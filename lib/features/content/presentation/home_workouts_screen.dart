import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/db/app_database.dart';
import '../../../design/backdrop.dart';
import '../../../design/components.dart';
import '../../../design/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/ad_banner.dart';
import '../data/content_repository.dart';
import '../data/youtube_workouts.dart';
import '../domain/content_item.dart';
import 'discover_screen.dart' show fmtDuration;
import 'exercise_detail_screen.dart';
import 'video_player_screen.dart';
import 'youtube_workout_screen.dart';

/// "Home workouts": everything you can do without a gym, in one place.
///
/// - Follow-along workouts (YouTube: Bodybuilding.com + hand-picked
///   trainers), filterable by body part.
/// - Coach exercise guides you can do at home (Bodybuilding.com).
/// - Bodyweight exercises from the free wger library (videos first).
/// - Yoga & stretching (YouTube + Wikimedia Commons videos).
/// - Latest uploads from Bodybuilding.com (auto-refreshed channel feed).
class HomeWorkoutsScreen extends StatefulWidget {
  const HomeWorkoutsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context, rootNavigator: true)
      .push(MaterialPageRoute(builder: (_) => const HomeWorkoutsScreen()));

  /// wger exercise with no equipment (or "none (bodyweight exercise)").
  static bool isBodyweight(ContentItemRow e) {
    final eq = RegExp(r'^Equipment: (.*)$', multiLine: true).firstMatch(e.description ?? '')?.group(1);
    if (eq == null) return true;
    final parts = eq.split(',').map((x) => x.trim().toLowerCase());
    return parts.every((p) => p.startsWith('none') || p == 'gym mat' || p == 'pull-up bar' || p == 'bench');
  }

  @override
  State<HomeWorkoutsScreen> createState() => _HomeWorkoutsScreenState();
}

class _HomeWorkoutsScreenState extends State<HomeWorkoutsScreen> {
  final _repo = ContentRepository(AppDatabase.instance);
  String? _group;
  List<ContentItemRow> _bodyweight = const [];
  List<ContentItemRow> _yogaVideos = const [];
  List<ContentItemRow> _latest = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ex = await _repo.list(ContentKind.exercise);
    final videos = await _repo.list(ContentKind.video);
    if (!mounted) return;
    setState(() {
      _bodyweight = ex.where(HomeWorkoutsScreen.isBodyweight).toList()
        ..sort((a, b) {
          final v = (b.mediaFormat == 'video' ? 1 : 0) - (a.mediaFormat == 'video' ? 1 : 0);
          return v != 0 ? v : a.title.compareTo(b.title);
        });
      _yogaVideos = videos
          .where((v) => v.provider != 'youtube' && v.tags.any((t) => RegExp('yoga|stretch', caseSensitive: false).hasMatch(t)))
          .toList();
      _latest = videos.where((v) => v.provider == 'youtube').toList()
        ..sort((a, b) => b.firstSeenAt.compareTo(a.firstSeenAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groups = ['Full body', 'Abdomen', 'Legs', 'Chest', 'Arms', 'Shoulders', 'Back', 'Cardio'];
    // Full follow-along sessions (≥ 5 min); short form guides are listed
    // with the coach guides instead. Curated order (beginner-friendly first).
    final follow = youtubeWorkouts
        .where((v) => v.home && v.seconds >= 300 && !const {'Yoga', 'Office', 'Walking'}.contains(v.group))
        .where((v) => _group == null || v.group == _group)
        .toList();
    final guides = [
      ...youtubeHowTos.where((v) => v.home),
      ...youtubeWorkouts.where((v) => v.home && v.seconds < 300), // e.g. "The perfect plank"
    ].where((v) => _group == null || v.group == _group).toList();
    final yoga = youtubeWorkouts.where((v) => const {'Yoga', 'Office', 'Walking'}.contains(v.group)).toList();
    final bodyweight = _bodyweight.take(24).toList();

    Widget header(String title, {String? subtitle}) => Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.sm),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleLarge),
            if (subtitle != null) Text(subtitle, style: theme.textTheme.bodySmall),
          ]),
        );

    Widget row(int count, double height, Widget Function(int) item) => SizedBox(
          height: height,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (_, __) => const SizedBox(width: Space.md),
            itemBuilder: (_, i) => item(i),
          ),
        );

    return BrandBackdrop(
      tint: context.dm.movement.container,
      glow: context.dm.movement.accent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(l.homeWorkouts)),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: Space.xxl),
            children: Entrance.list([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.page),
                child: Text(l.homeWorkoutsHint, style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(height: Space.md),
              SizedBox(
                height: 40,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: Space.page),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final g in groups) ...[
                      ChoiceChip(
                        label: Text(g),
                        selected: _group == g,
                        onSelected: (v) => setState(() => _group = v ? g : null),
                      ),
                      const SizedBox(width: Space.sm),
                    ],
                  ],
                ),
              ),
              header(l.followAlong, subtitle: l.ytWorkoutsHint),
              if (follow.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.page),
                  child: Text(l.nothingYet, style: theme.textTheme.bodySmall),
                )
              else
                row(follow.length, 200, (i) => YoutubeWorkoutCard(video: follow[i], width: 230)),
              if (guides.isNotEmpty) ...[
                header(l.coachGuides, subtitle: 'Bodybuilding.com'),
                row(guides.length, 200, (i) => YoutubeWorkoutCard(video: guides[i], width: 200)),
              ],
              const Padding(
                padding: EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, 0),
                child: AdBanner(placement: 'home_workouts'),
              ),
              if (bodyweight.isNotEmpty) ...[
                header(l.bodyweightMoves, subtitle: 'wger'),
                row(bodyweight.length, 170, (i) => ExerciseCard(
                      item: bodyweight[i],
                      width: 150,
                      onTap: () => ExerciseDetailScreen.open(context, bodyweight[i]),
                    )),
              ],
              header(l.yogaStretch),
              row(yoga.length + _yogaVideos.length, 200, (i) {
                if (i < yoga.length) return YoutubeWorkoutCard(video: yoga[i], width: 230);
                final v = _yogaVideos[i - yoga.length];
                return _CatalogVideoCard(item: v, onTap: () => VideoPlayerScreen.open(context, v));
              }),
              if (_latest.isNotEmpty) ...[
                header(l.latestFrom('Bodybuilding.com')),
                row(_latest.length, 200, (i) {
                  final v = _latest[i];
                  return _CatalogVideoCard(item: v, onTap: () => YoutubeWorkoutScreen.openRow(context, v));
                }),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _CatalogVideoCard extends StatelessWidget {
  const _CatalogVideoCard({required this.item, required this.onTap});
  final ContentItemRow item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 230,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                if (item.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black12),
                  )
                else
                  ColoredBox(color: theme.colorScheme.primaryContainer),
                const Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: Padding(padding: EdgeInsets.all(6), child: Icon(Icons.play_arrow_rounded, color: Colors.white)),
                  ),
                ),
                if (item.durationSeconds != null)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                      child: Text(fmtDuration(item.durationSeconds!),
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white)),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(item.subtitle ?? '', style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Entry card for the Home workouts hub (Exercise screen, Discover).
class HomeWorkoutsCard extends StatelessWidget {
  const HomeWorkoutsCard({super.key, this.margin = EdgeInsets.zero});
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = context.dm.movement;
    return Padding(
      padding: margin,
      child: SurfaceCard(
        color: p.container,
        onTap: () => HomeWorkoutsScreen.open(context),
        semanticLabel: l.homeWorkouts,
        child: Row(children: [
          CategoryBadge(icon: Icons.home_rounded, palette: p, size: 48),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.homeWorkouts, style: theme.textTheme.titleMedium?.copyWith(color: p.onContainer)),
              const SizedBox(height: 2),
              Text(l.homeWorkoutsHint, style: theme.textTheme.bodySmall?.copyWith(color: p.onContainer)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: p.onContainer),
        ]),
      ),
    );
  }
}
