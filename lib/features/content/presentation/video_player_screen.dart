import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme.dart';
import '../../../core/db/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../data/download_service.dart';
import '../data/providers/content_provider.dart' show contentUserAgent;

/// Plays a workout / yoga / meditation video: saved copy first, otherwise
/// streams the rendition this platform can decode (VP9 WebM on Android,
/// MPEG-4 on iOS). Exercise demos loop by default.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.item});
  final ContentItemRow item;

  /// The URL this platform should stream first.
  static String? streamUrl(ContentItemRow it, {TargetPlatform? platform}) =>
      candidates(it, platform: platform).firstOrNull;

  /// Renditions to try in order (the other one is a fallback if the first
  /// can't be decoded or fetched on this device).
  static List<String> candidates(ContentItemRow it, {TargetPlatform? platform}) {
    final p = platform ?? defaultTargetPlatform;
    final ios = p == TargetPlatform.iOS || p == TargetPlatform.macOS;
    final out = <String>[];
    for (final u in ios ? [it.altMediaUrl, it.mediaUrl] : [it.mediaUrl, it.altMediaUrl]) {
      if (u != null && u.isNotEmpty && !out.contains(u)) out.add(u);
    }
    return out;
  }

  static Future<void> open(BuildContext context, ContentItemRow item) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoPlayerScreen(item: item)));

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _c;
  bool _failed = false;
  bool _loop = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    for (final url in VideoPlayerScreen.candidates(widget.item)) {
      VideoPlayerController? c;
      try {
        final local = await DownloadService.instance.localFile(url);
        c = local != null
            ? VideoPlayerController.file(File(local.path))
            : VideoPlayerController.networkUrl(Uri.parse(url),
                httpHeaders: const {'User-Agent': contentUserAgent});
        await c.initialize();
        await c.setLooping(_loop);
        await c.play();
        if (!mounted) {
          await c.dispose();
          return;
        }
        c.addListener(_onTick);
        setState(() => _c = c);
        return;
      } catch (e) {
        debugPrint('[Video] $url failed: $e');
        await c?.dispose();
      }
    }
    if (mounted) setState(() => _failed = true);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c?.removeListener(_onTick);
    _c?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = _c;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _failed
                      ? Padding(
                          padding: const EdgeInsets.all(Space.xl),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 48),
                            const SizedBox(height: Space.md),
                            Text(l.videoError,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                          ]),
                        )
                      : c == null
                          ? const CircularProgressIndicator(color: Colors.white)
                          : GestureDetector(
                              onTap: () => c.value.isPlaying ? c.pause() : c.play(),
                              child: AspectRatio(
                                aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
                                child: Stack(alignment: Alignment.center, children: [
                                  VideoPlayer(c),
                                  AnimatedOpacity(
                                    opacity: c.value.isPlaying ? 0 : 1,
                                    duration: Motion.of(context, Motion.short),
                                    child: Container(
                                      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                      padding: const EdgeInsets.all(Space.md),
                                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                ),
              ),
              if (c != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.md),
                  child: Column(children: [
                    VideoProgressIndicator(c,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: Space.sm),
                        colors: const VideoProgressColors(playedColor: BrandColors.mint, bufferedColor: Colors.white24)),
                    Row(children: [
                      Text('${_fmt(c.value.position)} / ${_fmt(c.value.duration)}',
                          style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70)),
                      const Spacer(),
                      IconButton(
                        tooltip: l.loop,
                        isSelected: _loop,
                        color: Colors.white54,
                        selectedIcon: const Icon(Icons.repeat_one_rounded, color: BrandColors.mint),
                        icon: const Icon(Icons.repeat_rounded),
                        onPressed: () {
                          setState(() => _loop = !_loop);
                          c.setLooping(_loop);
                        },
                      ),
                      IconButton(
                        tooltip: c.value.isPlaying ? l.pause : l.play,
                        color: Colors.white,
                        iconSize: 36,
                        icon: Icon(c.value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                        onPressed: () => c.value.isPlaying ? c.pause() : c.play(),
                      ),
                    ]),
                    if (widget.item.attribution != null)
                      Text('${widget.item.attribution} · ${widget.item.license}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
