import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/playback_store.dart';
import '../data/youtube_workouts.dart';
import '../domain/content_item.dart';
import 'discover_screen.dart' show fmtDuration;

/// Plays a free YouTube workout inside the app with YouTube's official
/// embedded (IFrame) player: play/pause/seek/captions/quality come from
/// YouTube's own controls. Adds full screen, "continue where you left off"
/// and "Open in YouTube" (also the fallback if a video can't be embedded).
class YoutubeWorkoutScreen extends StatefulWidget {
  const YoutubeWorkoutScreen({super.key, required this.video});
  final YoutubeWorkout video;

  static Future<void> open(BuildContext context, YoutubeWorkout v) => Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute(builder: (_) => YoutubeWorkoutScreen(video: v)));

  /// Player page HTML (IFrame API). Reports position every 2 s through the
  /// `Dm` JavaScript channel so the app can resume later.
  static String playerHtml(String id, {int startSeconds = 0}) => '''<!DOCTYPE html>
<html><head><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<style>html,body{margin:0;padding:0;background:#000;height:100%;overflow:hidden}#p{position:absolute;top:0;left:0;width:100%;height:100%}</style>
</head><body><div id="p"></div>
<script src="https://www.youtube.com/iframe_api"></script>
<script>
var player;
function send(m){try{Dm.postMessage(m)}catch(e){}}
function onYouTubeIframeAPIReady(){
  player=new YT.Player('p',{host:'https://www.youtube-nocookie.com',videoId:${jsonEncode(id)},
    playerVars:{playsinline:1,rel:0,modestbranding:1,fs:1,autoplay:1,start:$startSeconds},
    events:{
      onReady:function(e){e.target.playVideo();send('ready')},
      onError:function(e){send('error:'+e.data)},
      onStateChange:function(e){send('state:'+e.data)}
    }});
  setInterval(function(){
    if(player&&player.getCurrentTime&&player.getDuration){send('t:'+player.getCurrentTime()+':'+player.getDuration())}
  },2000);
}
</script></body></html>''';

  @override
  State<YoutubeWorkoutScreen> createState() => _YoutubeWorkoutScreenState();
}

class _YoutubeWorkoutScreenState extends State<YoutubeWorkoutScreen> {
  WebViewController? _web;
  bool _ready = false;
  bool _failed = false; // YouTube reported an error (e.g. embedding refused)
  bool _slow = false; // still loading after a while: offer YouTube, keep trying
  bool _nativeFullscreen = false; // YouTube's own full-screen (Android custom view)
  Duration? _resumedFrom;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);

  YoutubeWorkout get v => widget.video;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final saved = await PlaybackStore.instance.get(v.resumeKey);
    var start = 0;
    if (saved != null && ResumePoint.worthResuming(positionMs: saved.positionMs, durationMs: saved.durationMs)) {
      start = saved.positionMs ~/ 1000;
      _resumedFrom = Duration(seconds: start);
    }
    final c =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..addJavaScriptChannel('Dm', onMessageReceived: (m) => _onMessage(m.message))
          ..setNavigationDelegate(
            NavigationDelegate(
              // Taps on the YouTube logo/title open YouTube outside the app.
              onNavigationRequest: (r) {
                final u = Uri.tryParse(r.url);
                final internal =
                    r.url.startsWith('about:') ||
                    (u != null &&
                        (u.host.endsWith('youtube-nocookie.com') ||
                            u.path.startsWith('/embed') ||
                            u.path.contains('iframe_api') ||
                            u.host.endsWith('ytimg.com') ||
                            u.host.endsWith('google.com') ||
                            u.host.endsWith('doubleclick.net') ||
                            u.host.endsWith('googlevideo.com')));
                if (internal || !r.isMainFrame) return NavigationDecision.navigate;
                _openInYoutube();
                return NavigationDecision.prevent;
              },
            ),
          );
    final platform = c.platform;
    if (platform is AndroidWebViewController) {
      await platform.setMediaPlaybackRequiresUserGesture(false);
      // YouTube's ⛶ button: Android hands us the full-screen video view.
      await platform.setCustomWidgetCallbacks(
        onShowCustomWidget: _showNativeFullscreen,
        onHideCustomWidget: _hideNativeFullscreen,
      );
    }
    // The page origin must be a real https site or YouTube refuses to embed
    // (error 152/153 in WebViews without a referrer).
    await c.loadHtmlString(
      YoutubeWorkoutScreen.playerHtml(v.id, startSeconds: start),
      baseUrl: 'https://www.youtube-nocookie.com',
    );
    if (mounted) setState(() => _web = c);
    // Slow network: keep loading, but offer YouTube as a way out.
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && !_ready) setState(() => _slow = true);
    });
  }

  void _onMessage(String m) {
    if (!mounted) return;
    if (m == 'ready') {
      setState(() => _ready = true);
    } else if (m.startsWith('error:')) {
      debugPrint('[YouTube] ${v.id} error ${m.substring(6)}');
      setState(() => _failed = true);
    } else if (m.startsWith('t:')) {
      final parts = m.split(':');
      final t = double.tryParse(parts[1]) ?? 0;
      final d = double.tryParse(parts.length > 2 ? parts[2] : '') ?? 0;
      _pos = Duration(milliseconds: (t * 1000).round());
      _dur = Duration(milliseconds: (d * 1000).round());
      if (!_ready) setState(() => _ready = true);
      final now = DateTime.now();
      if (now.difference(_lastSave) >= const Duration(seconds: 5)) {
        _lastSave = now;
        _save();
      }
    }
  }

  Future<void> _save() async {
    if (_dur == Duration.zero) return;
    await PlaybackStore.instance.saveMedia(v.resumeKey, ContentKind.video, position: _pos, duration: _dur);
  }

  Future<void> _startOver() async {
    setState(() => _resumedFrom = null);
    await _web?.runJavaScript('player && player.seekTo(0, true); player && player.playVideo();');
  }

  Future<void> _openInYoutube() async {
    await _web?.runJavaScript('player && player.pauseVideo && player.pauseVideo();');
    await launchUrl(Uri.parse(v.watchUrl), mode: LaunchMode.externalApplication);
  }

  Future<void> _showNativeFullscreen(Widget view, void Function() onHidden) async {
    if (_nativeFullscreen || !mounted) return;
    _nativeFullscreen = true;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => Scaffold(backgroundColor: Colors.black, body: SizedBox.expand(child: view)),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
    // Back pressed (or YouTube left full screen and popped us).
    if (_nativeFullscreen) {
      _nativeFullscreen = false;
      onHidden();
    }
    await _restoreSystemUi();
  }

  void _hideNativeFullscreen() {
    if (!_nativeFullscreen || !mounted) return;
    _nativeFullscreen = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  void dispose() {
    _save();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: Colors.white70);

    final player = Stack(
      fit: StackFit.expand,
      children: [
        if (_web != null && !_failed) WebViewWidget(controller: _web!),
        if (!_ready && !_failed)
          Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: v.thumbnail,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox(),
              ),
              const ColoredBox(color: Colors.black45),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    if (_slow) ...[
                      const SizedBox(height: Space.md),
                      TextButton.icon(
                        onPressed: _openInYoutube,
                        icon: const Icon(Icons.open_in_new_rounded, color: BrandColors.mint),
                        label: Text(l.ytOpenInYoutube, style: const TextStyle(color: BrandColors.mint)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        if (_failed)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.smart_display_outlined, color: Colors.white70, size: 40),
                  const SizedBox(height: Space.sm),
                  Text(l.ytCantPlayHere, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: Space.sm),
                  FilledButton.icon(
                    onPressed: _openInYoutube,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(l.ytOpenInYoutube),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            v.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ),
        body: Column(
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: player),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Space.page),
                children: [
                  if (_resumedFrom != null && !_failed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.md),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, color: BrandColors.mint, size: 18),
                          const SizedBox(width: Space.xs),
                          Expanded(child: Text(l.resumedAt(_fmt(_resumedFrom!)), style: muted)),
                          TextButton(
                            onPressed: _startOver,
                            child: Text(l.startOver, style: const TextStyle(color: BrandColors.mint)),
                          ),
                        ],
                      ),
                    ),
                  Text(v.title, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: Space.xs),
                  Text('${v.channel} · ${fmtDuration(v.seconds)} · ${v.group} · ${v.level}', style: muted),
                  const SizedBox(height: Space.lg),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      onPressed: _openInYoutube,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(l.ytOpenInYoutube),
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  Text('${l.ytFullscreenHint}\n\n${l.ytNote}', style: muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// Thumbnail card for one YouTube workout.
class YoutubeWorkoutCard extends StatelessWidget {
  const YoutubeWorkoutCard({super.key, required this.video, this.width});
  final YoutubeWorkout video;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => YoutubeWorkoutScreen.open(context, video),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.thumbnail,
                      fit: BoxFit.cover,
                      errorWidget:
                          (_, __, ___) => ColoredBox(
                            color: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.smart_display_rounded, color: theme.colorScheme.onPrimaryContainer),
                          ),
                    ),
                    const Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          fmtDuration(video.seconds),
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.sm, Space.sm, Space.sm, Space.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(
                      '${video.channel} · ${video.level}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
