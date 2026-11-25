import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/db/app_database.dart';
import '../../../services/ad_service.dart';
import '../../../widgets/ad_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../data/youtube_workouts.dart';
import 'discover_screen.dart' show fmtDuration;
import 'youtube_player.dart';

/// Plays a free YouTube workout or exercise guide inside the app: player on
/// top (plays straight away, continues where you left off, YouTube's own
/// full screen), details, "Open in YouTube".
class YoutubeWorkoutScreen extends StatefulWidget {
  const YoutubeWorkoutScreen({super.key, required this.video, this.resumeKey});
  final YoutubeWorkout video;

  /// Defaults to `yt:<id>` (also the content id of channel-feed items, so
  /// they show up in "Continue where you left off").
  final String? resumeKey;

  static Future<void> open(BuildContext context, YoutubeWorkout v) => Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute(builder: (_) => YoutubeWorkoutScreen(video: v)));

  /// Opens a channel-feed item from the content catalogue.
  static Future<void> openRow(BuildContext context, ContentItemRow row) => open(context, fromRow(row));

  static YoutubeWorkout fromRow(ContentItemRow r) => YoutubeWorkout(
    r.id.startsWith('yt:') ? r.id.substring(3) : r.id,
    r.title,
    r.subtitle ?? 'YouTube',
    r.tags.length > 1 ? r.tags[1] : 'Workout',
    '',
    r.durationSeconds ?? 0,
  );

  /// Kept for tests and callers that build the page HTML directly.
  static String playerHtml(String id, {int startSeconds = 0}) =>
      YoutubeInlinePlayer.playerHtml(id, startSeconds: startSeconds);

  @override
  State<YoutubeWorkoutScreen> createState() => _YoutubeWorkoutScreenState();
}

class _YoutubeWorkoutScreenState extends State<YoutubeWorkoutScreen> {
  final _player = GlobalKey<YoutubeInlinePlayerState>();
  Duration? _resumedFrom;
  int _watched = 0;

  YoutubeWorkout get v => widget.video;

  @override
  void dispose() {
    // Natural break after a real watch (not on a quick peek), frequency-capped.
    if (_watched >= 60) InterstitialHelper().showIfAvailable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: Colors.white70);
    final meta = [
      v.channel,
      if (v.seconds > 0) fmtDuration(v.seconds),
      if (v.group.isNotEmpty) v.group,
      if (v.level.isNotEmpty) v.level,
    ].join(' · ');

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
            YoutubeInlinePlayer(
              key: _player,
              videoId: v.id,
              resumeKey: widget.resumeKey ?? v.resumeKey,
              autoPlay: true,
              onResumed: (d) => setState(() => _resumedFrom = d),
              onWatched: (s) => _watched = s,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Space.page),
                children: [
                  if (_resumedFrom != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.md),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, color: BrandColors.mint, size: 18),
                          const SizedBox(width: Space.xs),
                          Expanded(child: Text(l.resumedAt(_fmt(_resumedFrom!)), style: muted)),
                          TextButton(
                            onPressed: () {
                              setState(() => _resumedFrom = null);
                              _player.currentState?.seekToStart();
                            },
                            child: Text(l.startOver, style: const TextStyle(color: BrandColors.mint)),
                          ),
                        ],
                      ),
                    ),
                  Text(v.title, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: Space.xs),
                  Text(meta, style: muted),
                  const SizedBox(height: Space.lg),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      onPressed:
                          () => _player.currentState?.openExternally() ?? YoutubeInlinePlayer.openInYoutube(v.id),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(l.ytOpenInYoutube),
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  Text('${l.ytFullscreenHint}\n\n${l.ytNote}', style: muted),
                  const SizedBox(height: Space.lg),
                  // Below the content, never over the player.
                  const AdBanner(placement: 'video_page'),
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
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (YoutubeInlinePlayer.showThumbnails)
                      CachedNetworkImage(
                        imageUrl: video.thumbnail,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _Placeholder(video: video),
                      )
                    else
                      _Placeholder(video: video),
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

/// Brand-styled stand-in when thumbnails aren't loaded (offline / tests).
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.video});
  final YoutubeWorkout video;

  @override
  Widget build(BuildContext context) {
    final p = context.dm.movement;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.container, Color.lerp(p.container, p.accent, 0.35)!],
        ),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Text(video.group.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.onContainer, letterSpacing: 0.8)),
        ),
      ),
    );
  }
}
