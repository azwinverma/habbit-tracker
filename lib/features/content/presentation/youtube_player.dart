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
import '../domain/content_item.dart';

/// Inline YouTube player (YouTube's official IFrame player, no-cookie host).
///
/// - Shows the thumbnail with a play button until tapped (or plays at once
///   with [autoPlay]), so pages with a video on top don't start playing or
///   use data until the user asks.
/// - Continues where you left off (saved under [resumeKey]) for videos over
///   a minute; [onResumed] reports the start position.
/// - YouTube's own ⛶ button goes full screen (Android custom view).
/// - A YouTube error (e.g. embedding switched off) or a very slow load
///   offers "Open in YouTube".
class YoutubeInlinePlayer extends StatefulWidget {
  const YoutubeInlinePlayer({
    super.key,
    required this.videoId,
    required this.resumeKey,
    this.autoPlay = false,
    this.badge,
    this.onResumed,
    this.onWatched,
  });

  final String videoId;
  final String resumeKey;
  final bool autoPlay;

  /// Small label on the poster, e.g. "Bodybuilding.com".
  final String? badge;
  final ValueChanged<Duration>? onResumed;

  /// Total seconds watched so far (for ad pacing on the host page).
  final ValueChanged<int>? onWatched;

  /// Off in widget tests (thumbnails need the image cache's file system).
  @visibleForTesting
  static bool showThumbnails = true;

  static String thumbnail(String id) => 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
  static String watchUrl(String id) => 'https://www.youtube.com/watch?v=$id';

  static Future<void> openInYoutube(String id) =>
      launchUrl(Uri.parse(watchUrl(id)), mode: LaunchMode.externalApplication);

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
  State<YoutubeInlinePlayer> createState() => YoutubeInlinePlayerState();
}

class YoutubeInlinePlayerState extends State<YoutubeInlinePlayer> {
  WebViewController? _web;
  bool _started = false;
  bool _ready = false;
  bool _failed = false;
  bool _slow = false;
  bool _nativeFullscreen = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);
  int _watchedSeconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) start();
  }

  /// Starts loading/playing (also called by the host's "Start over").
  Future<void> start() async {
    if (_started) return;
    setState(() => _started = true);
    final saved = await PlaybackStore.instance.get(widget.resumeKey);
    var startAt = 0;
    if (saved != null && ResumePoint.worthResuming(positionMs: saved.positionMs, durationMs: saved.durationMs)) {
      startAt = saved.positionMs ~/ 1000;
      widget.onResumed?.call(Duration(seconds: startAt));
    }
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('Dm', onMessageReceived: (m) => _onMessage(m.message))
      ..setNavigationDelegate(NavigationDelegate(
        // Taps on the YouTube logo/title leave the app to YouTube.
        onNavigationRequest: (r) {
          final u = Uri.tryParse(r.url);
          final internal = r.url.startsWith('about:') ||
              (u != null &&
                  (u.host.endsWith('youtube-nocookie.com') ||
                      u.path.startsWith('/embed') ||
                      u.path.contains('iframe_api') ||
                      u.host.endsWith('ytimg.com') ||
                      u.host.endsWith('google.com') ||
                      u.host.endsWith('doubleclick.net') ||
                      u.host.endsWith('googlevideo.com')));
          if (internal || !r.isMainFrame) return NavigationDecision.navigate;
          openExternally();
          return NavigationDecision.prevent;
        },
      ));
    final platform = c.platform;
    if (platform is AndroidWebViewController) {
      await platform.setMediaPlaybackRequiresUserGesture(false);
      await platform.setCustomWidgetCallbacks(
        onShowCustomWidget: _showNativeFullscreen,
        onHideCustomWidget: _hideNativeFullscreen,
      );
    }
    // A real https origin is required, or YouTube refuses to embed in a
    // WebView (error 152/153: missing referrer).
    await c.loadHtmlString(YoutubeInlinePlayer.playerHtml(widget.videoId, startSeconds: startAt),
        baseUrl: 'https://www.youtube-nocookie.com');
    if (!mounted) return;
    setState(() => _web = c);
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && !_ready) setState(() => _slow = true);
    });
  }

  Future<void> seekToStart() async {
    await _web?.runJavaScript('player && player.seekTo(0, true); player && player.playVideo();');
  }

  Future<void> pause() async {
    await _web?.runJavaScript('player && player.pauseVideo && player.pauseVideo();');
  }

  Future<void> openExternally() async {
    await pause();
    await YoutubeInlinePlayer.openInYoutube(widget.videoId);
  }

  void _onMessage(String m) {
    if (!mounted) return;
    if (m == 'ready') {
      setState(() => _ready = true);
    } else if (m.startsWith('error:')) {
      debugPrint('[YouTube] ${widget.videoId} error ${m.substring(6)}');
      setState(() => _failed = true);
    } else if (m.startsWith('t:')) {
      final parts = m.split(':');
      final t = double.tryParse(parts[1]) ?? 0;
      final d = double.tryParse(parts.length > 2 ? parts[2] : '') ?? 0;
      final pos = Duration(milliseconds: (t * 1000).round());
      if (pos != _pos) {
        _watchedSeconds += 2;
        widget.onWatched?.call(_watchedSeconds);
      }
      _pos = pos;
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
    await PlaybackStore.instance.saveMedia(widget.resumeKey, ContentKind.video, position: _pos, duration: _dur);
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
    if (_nativeFullscreen) {
      _nativeFullscreen = false;
      onHidden(); // closed with Back
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  void _hideNativeFullscreen() {
    if (!_nativeFullscreen || !mounted) return;
    _nativeFullscreen = false;
    Navigator.of(context, rootNavigator: true).pop();
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
    final Widget poster = YoutubeInlinePlayer.showThumbnails
        ? CachedNetworkImage(
            imageUrl: YoutubeInlinePlayer.thumbnail(widget.videoId),
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
          )
        : const ColoredBox(color: Colors.black);
    return ColoredBox(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(fit: StackFit.expand, children: [
          if (_web != null && !_failed) WebViewWidget(controller: _web!),
          if (!_started)
            Semantics(
              button: true,
              label: l.play,
              child: GestureDetector(
                onTap: start,
                child: Stack(fit: StackFit.expand, children: [
                  poster,
                  const ColoredBox(color: Colors.black26),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(Space.md),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44),
                    ),
                  ),
                  if (widget.badge != null)
                    Positioned(
                      left: Space.sm,
                      bottom: Space.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 3),
                        decoration:
                            BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(Radii.pill)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.smart_display_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(widget.badge!, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white)),
                        ]),
                      ),
                    ),
                ]),
              ),
            )
          else if (!_ready && !_failed)
            Stack(fit: StackFit.expand, children: [
              poster,
              const ColoredBox(color: Colors.black45),
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: Colors.white),
                  if (_slow) ...[
                    const SizedBox(height: Space.md),
                    TextButton.icon(
                      onPressed: openExternally,
                      icon: const Icon(Icons.open_in_new_rounded, color: BrandColors.mint),
                      label: Text(l.ytOpenInYoutube, style: const TextStyle(color: BrandColors.mint)),
                    ),
                  ],
                ]),
              ),
            ]),
          if (_failed)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.smart_display_outlined, color: Colors.white70, size: 36),
                  const SizedBox(height: Space.sm),
                  Text(l.ytCantPlayHere, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: Space.sm),
                  FilledButton.icon(
                    onPressed: openExternally,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(l.ytOpenInYoutube),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}
