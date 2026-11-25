import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme.dart';
import '../../../core/db/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../data/download_service.dart';
import '../data/playback_store.dart';
import '../data/providers/content_provider.dart' show contentUserAgent;
import '../domain/content_item.dart';

/// Renditions of [it] to try in order on [platform]: VP9 WebM first on
/// Android, MPEG-4 first on iOS; the other is the fallback.
List<String> videoCandidates(ContentItemRow it, {TargetPlatform? platform}) {
  final p = platform ?? defaultTargetPlatform;
  final ios = p == TargetPlatform.iOS || p == TargetPlatform.macOS;
  final out = <String>[];
  for (final u in ios ? [it.altMediaUrl, it.mediaUrl] : [it.mediaUrl, it.altMediaUrl]) {
    if (u != null && u.isNotEmpty && !out.contains(u)) out.add(u);
  }
  return out;
}

/// Playback state shared by the inline player and its full-screen page, so
/// going full screen never restarts or re-buffers the video.
class _PlayerModel extends ChangeNotifier {
  _PlayerModel(this.c, {required this.loop}) {
    c.addListener(notifyListeners);
  }
  final VideoPlayerController c;
  bool loop;
  double speed = 1;
  bool muted = false;

  Future<void> togglePlay() async {
    final v = c.value;
    if (v.isPlaying) {
      await c.pause();
    } else {
      if (v.duration > Duration.zero && v.position >= v.duration - const Duration(milliseconds: 300)) {
        await c.seekTo(Duration.zero); // finished: play again from the start
      }
      await c.play();
    }
  }

  Future<void> seekBy(Duration d) async {
    final v = c.value;
    var t = v.position + d;
    if (t < Duration.zero) t = Duration.zero;
    if (v.duration > Duration.zero && t > v.duration) t = v.duration;
    await c.seekTo(t);
  }

  Future<void> setLoop(bool v) async {
    loop = v;
    await c.setLooping(v);
    notifyListeners();
  }

  Future<void> setSpeed(double s) async {
    speed = s;
    await c.setPlaybackSpeed(s);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    muted = !muted;
    await c.setVolume(muted ? 0 : 1);
    notifyListeners();
  }

  @override
  void dispose() {
    c.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Inline video player with modern controls: tap to show/hide, play/pause,
/// double-tap or buttons to skip 10 s, scrubbing, speed, loop, mute and
/// full screen. Plays the saved copy when there is one.
///
/// Long videos continue where you left off ("Resumed at 3:12 · Start
/// over"); short exercise loops always start from the beginning and loop.
class DmVideoPlayer extends StatefulWidget {
  const DmVideoPlayer({super.key, required this.item, this.autoPlay = true});
  final ContentItemRow item;
  final bool autoPlay;

  @override
  State<DmVideoPlayer> createState() => _DmVideoPlayerState();
}

class _DmVideoPlayerState extends State<DmVideoPlayer> {
  _PlayerModel? _m;
  bool _failed = false;
  Duration? _resumedFrom;
  Timer? _saveTimer;

  ContentKind get _kind => ContentKind.values.byName(widget.item.kind);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _failed = false);
    final saved = await PlaybackStore.instance.get(widget.item.id);
    for (final url in videoCandidates(widget.item)) {
      VideoPlayerController? c;
      try {
        final local = await DownloadService.instance.localFile(url);
        c = local != null
            ? VideoPlayerController.file(File(local.path))
            : VideoPlayerController.networkUrl(Uri.parse(url), httpHeaders: const {'User-Agent': contentUserAgent});
        await c.initialize();
        final dur = c.value.duration;
        final short = dur.inMilliseconds < ResumePoint.minResumableMs;
        await c.setLooping(short); // exercise demos loop
        Duration? resumed;
        if (saved != null &&
            ResumePoint.worthResuming(positionMs: saved.positionMs, durationMs: dur.inMilliseconds)) {
          resumed = Duration(milliseconds: saved.positionMs);
          await c.seekTo(resumed);
        }
        if (widget.autoPlay) await c.play();
        if (!mounted) {
          await c.dispose();
          return;
        }
        setState(() {
          _m = _PlayerModel(c!, loop: short);
          _resumedFrom = resumed;
        });
        if (!short) {
          _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _savePosition());
        }
        return;
      } catch (e) {
        debugPrint('[Video] $url failed: $e');
        await c?.dispose();
      }
    }
    if (mounted) setState(() => _failed = true);
  }

  Future<void> _savePosition() async {
    final c = _m?.c;
    if (c == null || !c.value.isInitialized) return;
    final dur = c.value.duration;
    if (dur.inMilliseconds < ResumePoint.minResumableMs) return;
    await PlaybackStore.instance.saveMedia(widget.item.id, _kind, position: c.value.position, duration: dur);
  }

  Future<void> _startOver() async {
    setState(() => _resumedFrom = null);
    await _m?.c.seekTo(Duration.zero);
    await _m?.c.play();
  }

  Future<void> _openFullscreen() async {
    final m = _m;
    if (m == null) return;
    final landscape = m.c.value.aspectRatio > 1.05;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (landscape) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    }
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
      opaque: true,
      pageBuilder: (_, __, ___) => _FullscreenPage(model: m, title: widget.item.title),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    final m = _m;
    if (m != null) {
      final c = m.c;
      if (c.value.isInitialized && c.value.duration.inMilliseconds >= ResumePoint.minResumableMs) {
        // Fire-and-forget: the controller is disposed right after, so read now.
        PlaybackStore.instance.saveMedia(widget.item.id, _kind, position: c.value.position, duration: c.value.duration);
      }
      m.dispose();
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = _m;
    Widget child;
    if (_failed) {
      child = Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 40),
            const SizedBox(height: Space.sm),
            Text(l.videoError,
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            TextButton.icon(
              onPressed: _init,
              icon: const Icon(Icons.refresh_rounded, color: BrandColors.mint),
              label: Text(l.retry, style: const TextStyle(color: BrandColors.mint)),
            ),
          ]),
        ),
      );
    } else if (m == null) {
      child = const Center(child: CircularProgressIndicator(color: Colors.white));
    } else {
      child = _VideoSurface(
        model: m,
        fullscreen: false,
        onFullscreen: _openFullscreen,
        resumedFrom: _resumedFrom,
        onStartOver: _startOver,
        onDismissResume: () => setState(() => _resumedFrom = null),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: _aspect(m),
        child: child,
      ),
    );
  }

  /// Inline frame: the video's own shape, kept between square and 16:9 so
  /// tall phone videos don't push the page content off screen.
  double _aspect(_PlayerModel? m) {
    final a = m?.c.value.aspectRatio ?? 16 / 9;
    if (a <= 0) return 16 / 9;
    return a.clamp(1.0, 16 / 9);
  }
}

class _FullscreenPage extends StatelessWidget {
  const _FullscreenPage({required this.model, required this.title});
  final _PlayerModel model;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _VideoSurface(
        model: model,
        fullscreen: true,
        title: title,
        onFullscreen: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// Video + overlay controls (shared by inline and full screen).
class _VideoSurface extends StatefulWidget {
  const _VideoSurface({
    required this.model,
    required this.fullscreen,
    required this.onFullscreen,
    this.title,
    this.resumedFrom,
    this.onStartOver,
    this.onDismissResume,
  });
  final _PlayerModel model;
  final bool fullscreen;
  final VoidCallback onFullscreen;
  final String? title;
  final Duration? resumedFrom;
  final VoidCallback? onStartOver;
  final VoidCallback? onDismissResume;

  @override
  State<_VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<_VideoSurface> {
  bool _visible = true;
  Timer? _hide;
  Timer? _resumeHide;
  int _skipFlash = 0; // -1 back, 1 forward, 0 none

  _PlayerModel get m => widget.model;

  @override
  void initState() {
    super.initState();
    m.addListener(_onModel);
    _scheduleHide();
    if (widget.resumedFrom != null) _scheduleResumeHide();
  }

  @override
  void didUpdateWidget(covariant _VideoSurface old) {
    super.didUpdateWidget(old);
    if (widget.resumedFrom != null && old.resumedFrom == null) _scheduleResumeHide();
  }

  void _scheduleResumeHide() {
    _resumeHide?.cancel();
    _resumeHide = Timer(const Duration(seconds: 8), () => widget.onDismissResume?.call());
  }

  void _onModel() {
    if (mounted) setState(() {});
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted && m.c.value.isPlaying) setState(() => _visible = false);
    });
  }

  void _poke() {
    setState(() => _visible = true);
    _scheduleHide();
  }

  void _toggleVisible() {
    if (_visible) {
      _hide?.cancel();
      setState(() => _visible = false);
    } else {
      _poke();
    }
  }

  Future<void> _skip(int dir) async {
    setState(() => _skipFlash = dir);
    await m.seekBy(Duration(seconds: 10 * dir));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _skipFlash = 0);
    });
    _poke();
  }

  @override
  void dispose() {
    _hide?.cancel();
    _resumeHide?.cancel();
    m.removeListener(_onModel);
    super.dispose();
  }

  static String fmt(Duration d) {
    final h = d.inHours;
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final v = m.c.value;
    final showControls = _visible || !v.isPlaying;
    final white = theme.textTheme.labelMedium?.copyWith(color: Colors.white);
    final dur = Motion.of(context, Motion.short);

    return Stack(fit: StackFit.expand, children: [
      Center(
        child: AspectRatio(
          aspectRatio: v.aspectRatio <= 0 ? 16 / 9 : v.aspectRatio,
          child: VideoPlayer(m.c),
        ),
      ),
      // Gestures: tap toggles controls, double-tap left/right skips 10 s.
      Row(children: [
        for (final dir in const [-1, 1])
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleVisible,
              onDoubleTap: () => _skip(dir),
              child: AnimatedOpacity(
                opacity: _skipFlash == dir ? 1 : 0,
                duration: dur,
                child: Center(
                  child: Icon(dir < 0 ? Icons.replay_10_rounded : Icons.forward_10_rounded,
                      color: Colors.white, size: 44),
                ),
              ),
            ),
          ),
      ]),
      if (v.isBuffering && v.isPlaying)
        const Center(child: CircularProgressIndicator(color: Colors.white)),
      IgnorePointer(
        ignoring: !showControls,
        child: AnimatedOpacity(
          opacity: showControls ? 1 : 0,
          duration: dur,
          child: Stack(fit: StackFit.expand, children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black45, Colors.transparent, Colors.transparent, Colors.black54],
                  stops: [0, 0.25, 0.6, 1],
                ),
              ),
            ),
            if (widget.fullscreen)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Row(children: [
                    IconButton(
                      tooltip: l.exitFullscreen,
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: widget.onFullscreen,
                    ),
                    Expanded(
                      child: Text(widget.title ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                    ),
                  ]),
                ),
              ),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _RoundButton(icon: Icons.replay_10_rounded, tooltip: l.back10, onTap: () => _skip(-1)),
                const SizedBox(width: Space.lg),
                _RoundButton(
                  icon: v.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  tooltip: v.isPlaying ? l.pause : l.play,
                  big: true,
                  onTap: () {
                    m.togglePlay();
                    _poke();
                  },
                ),
                const SizedBox(width: Space.lg),
                _RoundButton(icon: Icons.forward_10_rounded, tooltip: l.forward10, onTap: () => _skip(1)),
              ]),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.xs, Space.xs),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    VideoProgressIndicator(
                      m.c,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: Space.sm),
                      colors: const VideoProgressColors(
                          playedColor: BrandColors.mint, bufferedColor: Colors.white38, backgroundColor: Colors.white12),
                    ),
                    Row(children: [
                      Text('${fmt(v.position)} / ${fmt(v.duration)}', style: white),
                      const Spacer(),
                      PopupMenuButton<double>(
                        tooltip: l.playbackSpeed,
                        initialValue: m.speed,
                        onSelected: m.setSpeed,
                        itemBuilder: (_) => [
                          for (final s in const [0.5, 0.75, 1.0, 1.25, 1.5])
                            PopupMenuItem(value: s, child: Text('${_trim(s)}×')),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.sm),
                          child: Text('${_trim(m.speed)}×', style: white?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      IconButton(
                        tooltip: l.loop,
                        isSelected: m.loop,
                        color: Colors.white70,
                        selectedIcon: const Icon(Icons.repeat_one_rounded, color: BrandColors.mint),
                        icon: const Icon(Icons.repeat_rounded),
                        onPressed: () => m.setLoop(!m.loop),
                      ),
                      IconButton(
                        tooltip: m.muted ? l.unmute : l.mute,
                        color: Colors.white,
                        icon: Icon(m.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                        onPressed: m.toggleMute,
                      ),
                      IconButton(
                        tooltip: widget.fullscreen ? l.exitFullscreen : l.fullscreen,
                        color: Colors.white,
                        icon: Icon(widget.fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
                        onPressed: widget.onFullscreen,
                      ),
                    ]),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
      if (widget.resumedFrom != null && !widget.fullscreen)
        Positioned(
          top: Space.sm,
          left: Space.sm,
          child: Material(
            color: Colors.black87,
            shape: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.only(left: Space.md),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(l.resumedAt(fmt(widget.resumedFrom!)), style: white),
                TextButton(
                  onPressed: widget.onStartOver,
                  child: Text(l.startOver, style: const TextStyle(color: BrandColors.mint)),
                ),
              ]),
            ),
          ),
        ),
    ]);
  }

  static String _trim(double s) => s == s.roundToDouble() ? s.toStringAsFixed(0) : '$s';
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap, this.big = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        iconSize: big ? 44 : 28,
        color: Colors.white,
        padding: EdgeInsets.all(big ? Space.sm : Space.xs),
        icon: Icon(icon),
        onPressed: onTap,
      ),
    );
  }
}
