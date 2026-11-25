import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/db/app_database.dart';
import '../../../design/components.dart';
import '../../../l10n/app_localizations.dart';
import '../data/content_repository.dart';
import '../domain/content_item.dart';
import 'discover_screen.dart' show ContentCredits, DownloadButton;
import 'dm_video_player.dart';
import 'youtube_player.dart';
import '../data/youtube_workouts.dart';
import '../../../widgets/ad_banner.dart';
import '../../../design/backdrop.dart';

/// One exercise: demo video pinned at the top (play / pause / skip / speed /
/// loop / full screen), then how to do it, muscles, equipment and more
/// exercises of the same type that have a video.
///
/// Exercises without a video show their picture instead (most wger
/// exercises have pictures; about 1 in 20 has a video).
class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.item});
  final ContentItemRow item;

  static Future<void> open(BuildContext context, ContentItemRow item, {bool replace = false}) {
    final route = MaterialPageRoute<void>(builder: (_) => ExerciseDetailScreen(item: item));
    final nav = Navigator.of(context, rootNavigator: true);
    return replace ? nav.pushReplacement(route) : nav.push(route);
  }

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  List<ContentItemRow> _related = const [];
  late final YoutubeWorkout? _coach = ExerciseText.howToFor(widget.item.title);
  bool _showCoach = false; // which video is on top when both exist

  ContentItemRow get it => widget.item;
  bool get _hasVideo => it.mediaFormat == 'video' && videoCandidates(it).isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No demo loop → the coach video takes the top spot.
    if (!_hasVideo && _coach != null) _showCoach = true;
  }

  @override
  void initState() {
    super.initState();
    _loadRelated();
  }

  Future<void> _loadRelated() async {
    final category = it.tags.firstOrNull;
    final rows = await ContentRepository(AppDatabase.instance).list(ContentKind.exercise, tag: category);
    if (!mounted) return;
    setState(() {
      _related = rows.where((r) => r.id != it.id && r.mediaFormat == 'video').take(12).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final parts = ExerciseText.split(it.description);

    return BrandBackdrop(tint: context.dm.movement.container, glow: context.dm.movement.accent, child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Column(children: [
        // Pinned media: stays visible while the steps scroll underneath.
        if (_showCoach && _coach != null)
          YoutubeInlinePlayer(
            key: ValueKey('yt-${_coach.id}'),
            videoId: _coach.id,
            resumeKey: _coach.resumeKey,
            badge: _coach.channel,
          )
        else if (_hasVideo)
          DmVideoPlayer(key: ValueKey(it.id), item: it)
        else
          _ImageHero(item: it),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.xxl),
            children: [
              Text(it.title, style: theme.textTheme.headlineSmall),
              if (it.subtitle != null && it.subtitle!.isNotEmpty) ...[
                const SizedBox(height: Space.xs),
                Text(it.subtitle!,
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: Space.md),
              if (_hasVideo && _coach != null) ...[
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, icon: const Icon(Icons.loop_rounded), label: Text(l.demoLoop)),
                    ButtonSegment(value: true, icon: const Icon(Icons.smart_display_rounded), label: Text(l.coachVideo)),
                  ],
                  selected: {_showCoach},
                  onSelectionChanged: (v) => setState(() => _showCoach = v.first),
                ),
                const SizedBox(height: Space.md),
              ],
              Wrap(spacing: Space.sm, runSpacing: Space.xs, children: [
                if (_hasVideo) StatusChip(icon: Icons.play_arrow_rounded, label: l.videoDemo),
                if (_coach != null) StatusChip(icon: Icons.smart_display_rounded, label: _coach.channel),
                for (final t in it.tags.where((t) => t != 'Video')) StatusChip(label: t),
              ]),
              if (!_hasVideo && _coach == null) ...[
                const SizedBox(height: Space.md),
                Text(l.noVideoYet, style: theme.textTheme.bodySmall),
              ],
              if (_showCoach && _coach != null) ...[
                const SizedBox(height: Space.sm),
                Text('${_coach.title} · ${_coach.channel} · ${l.ytFullscreenHint}', style: theme.textTheme.bodySmall),
              ],
              if (_hasVideo && !_showCoach && it.mediaUrl != null) ...[
                const SizedBox(height: Space.md),
                DownloadButton(contentId: it.id, url: videoCandidates(it).first, bytes: it.mediaBytes),
              ],
              if (parts.steps.isNotEmpty) ...[
                const SizedBox(height: Space.xl),
                Text(l.howToDoIt, style: theme.textTheme.titleMedium),
                const SizedBox(height: Space.sm),
                for (var i = 0; i < parts.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (parts.steps.length > 1)
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: Space.sm, top: 1),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
                          child: Text('${i + 1}',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
                        ),
                      Expanded(child: Text(parts.steps[i], style: theme.textTheme.bodyMedium)),
                    ]),
                  ),
              ],
              if (parts.muscles.isNotEmpty || parts.equipment.isNotEmpty) ...[
                const SizedBox(height: Space.lg),
                if (parts.muscles.isNotEmpty) _InfoRow(icon: Icons.accessibility_new_rounded, label: l.musclesLabel, value: parts.muscles),
                if (parts.equipment.isNotEmpty) _InfoRow(icon: Icons.fitness_center_rounded, label: l.equipmentLabel, value: parts.equipment),
              ],
              if (_related.isNotEmpty) ...[
                const SizedBox(height: Space.xl),
                Text(l.moreWithVideo, style: theme.textTheme.titleMedium),
                const SizedBox(height: Space.sm),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _related.length,
                    separatorBuilder: (_, __) => const SizedBox(width: Space.md),
                    itemBuilder: (_, i) => ExerciseCard(
                      item: _related[i],
                      width: 160,
                      onTap: () => ExerciseDetailScreen.open(context, _related[i], replace: true),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: Space.xl),
              const Divider(),
              const SizedBox(height: Space.sm),
              ContentCredits(item: it),
              if (_showCoach && _coach != null)
                Text(l.ytNote, style: theme.textTheme.bodySmall),
              const SizedBox(height: Space.lg),
              const AdBanner(placement: 'exercise_detail'),
            ],
          ),
        ),
      ]),
    ));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ])),
        ),
      ]),
    );
  }
}

class _ImageHero extends StatelessWidget {
  const _ImageHero({required this.item});
  final ContentItemRow item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = Center(
      child: Icon(Icons.fitness_center_rounded, size: 56, color: theme.colorScheme.onPrimaryContainer),
    );
    return Container(
      height: 220,
      width: double.infinity,
      color: item.imageUrl == null ? theme.colorScheme.primaryContainer : Colors.white,
      child: item.imageUrl == null
          ? fallback
          : CachedNetworkImage(
              imageUrl: item.imageUrl!,
              fit: BoxFit.contain,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}

/// Compact exercise card (picture + play badge when it has a video).
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.item, required this.onTap, this.width});
  final ContentItemRow item;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final video = item.mediaFormat == 'video';
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                ColoredBox(
                  color: Colors.white,
                  child: item.imageUrl == null
                      ? Icon(Icons.fitness_center_rounded, color: theme.colorScheme.primary)
                      : CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => Icon(Icons.fitness_center_rounded, color: theme.colorScheme.primary),
                        ),
                ),
                if (video)
                  const Positioned(
                    right: 6,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: Padding(
                          padding: EdgeInsets.all(4), child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18)),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Text(item.title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Splits a wger description ("text…\n\nMuscles: …\nEquipment: …") into
/// readable steps plus the muscles / equipment lines.
abstract final class ExerciseText {
  static ({List<String> steps, String muscles, String equipment}) split(String? description) {
    var muscles = '';
    var equipment = '';
    final body = <String>[];
    for (final raw in (description ?? '').split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('Muscles: ')) {
        muscles = line.substring(9);
      } else if (line.startsWith('Equipment: ')) {
        equipment = line.substring(11);
      } else {
        body.add(line.replaceFirst(RegExp(r'^(\d+[.)]|[-•*])\s*'), ''));
      }
    }
    // One long paragraph → split into sentences so it reads as steps.
    if (body.length == 1 && body.first.length > 160) {
      final sentences = body.first
          .split(RegExp(r'(?<=[.!?])\s+(?=[A-Z])'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (sentences.length > 1) return (steps: sentences, muscles: muscles, equipment: equipment);
    }
    return (steps: body, muscles: muscles, equipment: equipment);
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'\(.*?\)'), ' ')
      .replaceAll(RegExp(r'[^a-z ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w.length > 3 && w.endsWith('s') ? w.substring(0, w.length - 1) : w)
      .join(' ');

  /// Best catalogue match for a plan entry such as "Push-ups (knee/incline)"
  /// (prefers exercises with a video). Null when nothing is close.
  static ContentItemRow? bestMatch(String name, Iterable<ContentItemRow> items) =>
      bestMatchBy(name, items, (it) => it.title, (it) => it.mediaFormat == 'video');

  /// Bodybuilding.com exercise guide for an exercise name, if one is close.
  static YoutubeWorkout? howToFor(String name) => bestMatchBy(name, youtubeHowTos, (v) => v.title, (_) => false);

  static T? bestMatchBy<T>(String name, Iterable<T> items, String Function(T) titleOf, bool Function(T) hasVideo) {
    final q = _norm(name);
    if (q.isEmpty) return null;
    final qWords = q.split(' ').toSet();
    T? best;
    var bestScore = 0.0;
    for (final it in items) {
      final t = _norm(titleOf(it));
      if (t.isEmpty) continue;
      final tWords = t.split(' ').toSet();
      double score;
      if (t == q || t.replaceAll(' ', '') == q.replaceAll(' ', '')) {
        score = 3; // also "pulldown" vs "Pull Down"
      } else if (q.length >= 6 && t.replaceAll(' ', '').contains(q.replaceAll(' ', ''))) {
        score = 1.9 - tWords.length * 0.05; // "lat pull down" inside "wide grip lat pulldown"
      } else {
        final common = qWords.intersection(tWords).length;
        if (common == 0) continue;
        // Every word of the plan entry present → strong; else partial overlap.
        score = common == qWords.length ? 2 : common / qWords.length;
        if (score < 0.5) continue;
        score -= (tWords.length - common) * 0.05; // fewer extra words is better
      }
      if (hasVideo(it)) score += 0.3;
      if (score > bestScore) {
        bestScore = score;
        best = it;
      }
    }
    return best;
  }
}
