import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/db/app_database.dart';
import '../../../l10n/app_localizations.dart';
import 'discover_screen.dart' show DownloadButton, fmtDuration;
import 'dm_video_player.dart';

/// Workout / yoga / meditation video page: player on top (continues where
/// you left off for longer videos), title, credits and offline download.
class VideoPlayerScreen extends StatelessWidget {
  const VideoPlayerScreen({super.key, required this.item});
  final ContentItemRow item;

  /// The URL this platform should stream first.
  static String? streamUrl(ContentItemRow it, {TargetPlatform? platform}) =>
      candidates(it, platform: platform).firstOrNull;

  /// Renditions to try in order (see [videoCandidates]).
  static List<String> candidates(ContentItemRow it, {TargetPlatform? platform}) =>
      videoCandidates(it, platform: platform);

  static Future<void> open(BuildContext context, ContentItemRow item) =>
      Navigator.of(context, rootNavigator: true)
          .push(MaterialPageRoute(builder: (_) => VideoPlayerScreen(item: item)));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final url = streamUrl(item);
    final muted = theme.textTheme.bodySmall?.copyWith(color: Colors.white70);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
        ),
        body: Column(children: [
          DmVideoPlayer(item: item),
          Expanded(
            child: Theme(
              data: theme.copyWith(
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38)),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(Space.page),
                children: [
                  Text(item.title, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: Space.xs),
                  Text(
                    [
                      if (item.subtitle != null && item.subtitle!.isNotEmpty) item.subtitle!,
                      if (item.durationSeconds != null) fmtDuration(item.durationSeconds!),
                    ].join(' · '),
                    style: muted,
                  ),
                  if (url != null) ...[
                    const SizedBox(height: Space.lg),
                    DownloadButton(contentId: item.id, url: url, bytes: item.mediaBytes),
                  ],
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: Space.lg),
                    Text(item.description!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                  ],
                  const SizedBox(height: Space.lg),
                  Text(l.creditsLicence, style: theme.textTheme.titleSmall?.copyWith(color: Colors.white)),
                  const SizedBox(height: Space.xs),
                  if (item.attribution != null) Text(item.attribution!, style: muted),
                  Text(l.licenceLabel(item.license), style: muted),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
