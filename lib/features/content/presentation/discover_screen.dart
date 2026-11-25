import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/db/app_database.dart';
import '../../../design/components.dart';
import '../../../l10n/app_localizations.dart';
import '../../../screens/reading_screen.dart' show BookReader;
import '../data/download_service.dart';
import '../domain/content_item.dart';
import 'audiobook_screen.dart';
import 'video_player_screen.dart';

/// Browse the free content catalogue (works offline from the cache).
/// New items from the latest refresh are listed first with a "New" badge;
/// "Saved" shows only what is stored on the phone.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key, this.initialKind = ContentKind.book});
  final ContentKind initialKind;

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: ContentKind.values.length, vsync: this, initialIndex: widget.initialKind.index);
  final _search = TextEditingController();
  String _query = '';
  bool _savedOnly = false;
  Timer? _debounce;
  Timer? _seenTimer;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _scheduleMarkSeen();
    });
    _scheduleMarkSeen();
  }

  /// Items count as "seen" after a moment on the tab, so New badges show first.
  void _scheduleMarkSeen() {
    _seenTimer?.cancel();
    final kind = ContentKind.values[_tabs.index];
    _seenTimer = Timer(const Duration(seconds: 3), () {
      ref.read(contentRepositoryProvider).markSeen(kind);
    });
  }

  @override
  void dispose() {
    _seenTimer?.cancel();
    _debounce?.cancel();
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final l = AppLocalizations.of(context);
    final r = await ref.read(contentSyncServiceProvider).syncIfStale(force: true);
    if (!mounted) return;
    final added = r.fold<int>(0, (a, b) => a + b.newItems);
    final allFailed = r.every((x) => x.error != null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(allFailed
          ? l.contentUnreachable
          : added > 0
              ? l.newItemsAdded(added)
              : l.upToDate),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.discover),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(124),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.sm),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l.searchContent,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: l.clear,
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _search.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Radii.pill), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Radii.pill), borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) {
                        _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 250), () => setState(() => _query = v));
                      },
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  FilterChip(
                    avatar: const Icon(Icons.download_done_rounded, size: 18),
                    label: Text(l.savedFilter),
                    selected: _savedOnly,
                    showCheckmark: false,
                    onSelected: (v) => setState(() => _savedOnly = v),
                  ),
                ]),
              ),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                tabs: [for (final k in ContentKind.values) _TabLabel(kind: k)],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          for (final k in ContentKind.values)
            _ContentList(kind: k, query: _query, savedOnly: _savedOnly, onRefresh: _refresh),
        ],
      ),
    );
  }
}

String kindLabel(AppLocalizations l, ContentKind k) => switch (k) {
      ContentKind.book => l.tabBooks,
      ContentKind.audiobook => l.tabAudiobooks,
      ContentKind.audio => l.tabSounds,
      ContentKind.exercise => l.tabWorkouts,
      ContentKind.video => l.tabVideos,
    };

IconData kindIcon(ContentKind k) => switch (k) {
      ContentKind.book => Icons.menu_book_rounded,
      ContentKind.audiobook => Icons.headphones_rounded,
      ContentKind.audio => Icons.graphic_eq_rounded,
      ContentKind.exercise => Icons.fitness_center_rounded,
      ContentKind.video => Icons.play_circle_outline_rounded,
    };

class _TabLabel extends ConsumerWidget {
  const _TabLabel({required this.kind});
  final ContentKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(_newCountByKind(kind)).valueOrNull ?? 0;
    return Tab(
      child: Badge(
        isLabelVisible: n > 0,
        backgroundColor: context.dm.celebrate,
        textColor: BrandColors.ink,
        label: Text(n > 99 ? '99+' : '$n'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(kindLabel(AppLocalizations.of(context), kind)),
        ),
      ),
    );
  }
}

final _newCountByKind = StreamProvider.family<int, ContentKind>(
    (ref, k) => ref.watch(contentRepositoryProvider).watchNewCount(kind: k));

/// Content ids with at least one saved file.
final savedContentIdsProvider = StreamProvider<Set<String>>(
    (ref) => DownloadService.instance.watchAll().map((rows) => {for (final r in rows) r.contentId}));

class _ContentList extends ConsumerWidget {
  const _ContentList({required this.kind, required this.query, required this.savedOnly, required this.onRefresh});
  final ContentKind kind;
  final String query;
  final bool savedOnly;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final items = ref.watch(contentListProvider((kind: kind, search: query, tag: null)));
    final saved = ref.watch(savedContentIdsProvider).valueOrNull ?? const <String>{};
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(Space.page),
          children: const [
            Skeleton(height: 88, radius: Radii.lg),
            SizedBox(height: Space.md),
            Skeleton(height: 88, radius: Radii.lg),
            SizedBox(height: Space.md),
            Skeleton(height: 88, radius: Radii.lg),
          ],
        ),
        error: (e, _) => ListView(children: [EmptyState(icon: Icons.error_outline_rounded, title: l.couldNotLoad('$e'))]),
        data: (all) {
          final list = savedOnly ? all.where((i) => saved.contains(i.id)).toList() : all;
          if (list.isEmpty) {
            return ListView(children: [
              EmptyState(
                icon: savedOnly ? Icons.download_rounded : Icons.cloud_download_outlined,
                title: query.isNotEmpty
                    ? l.nothingMatches(query)
                    : savedOnly
                        ? l.nothingSaved
                        : l.nothingYet,
              ),
            ]);
          }
          final video = kind == ContentKind.video;
          return LayoutBuilder(builder: (context, c) {
            final cols = video ? (c.maxWidth >= 640 ? 3 : 2) : (c.maxWidth >= 720 ? 2 : 1);
            if (cols == 1) {
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.xxl),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
                itemBuilder: (_, i) => _ContentTile(item: list[i], saved: saved.contains(list[i].id)),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.xxl),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: Space.md,
                crossAxisSpacing: Space.md,
                mainAxisExtent: video ? 200 : 112,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) => video
                  ? _VideoCard(item: list[i], saved: saved.contains(list[i].id))
                  : _ContentTile(item: list[i], saved: saved.contains(list[i].id)),
            );
          });
        },
      ),
    );
  }
}

void _openDetail(BuildContext context, ContentItemRow item) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ContentDetailSheet(item: item),
    );

class _ContentTile extends StatelessWidget {
  const _ContentTile({required this.item, required this.saved});
  final ContentItemRow item;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final kind = ContentKind.values.byName(item.kind);
    final hasVideo = item.mediaFormat == 'video';
    return SurfaceCard(
      onTap: () => _openDetail(context, item),
      padding: const EdgeInsets.all(Space.md),
      child: Row(children: [
        _Thumb(url: item.imageUrl, kind: kind, width: 56, height: 72),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              [
                if (item.subtitle != null && item.subtitle!.isNotEmpty) item.subtitle!,
                if (item.durationSeconds != null) fmtDuration(item.durationSeconds!),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!item.seen || saved || hasVideo) ...[
              const SizedBox(height: Space.xs),
              Wrap(spacing: Space.xs, children: [
                if (!item.seen)
                  StatusChip(label: l.newBadge, background: context.dm.celebrate, color: BrandColors.ink),
                if (hasVideo && kind == ContentKind.exercise)
                  StatusChip(icon: Icons.play_arrow_rounded, label: l.tabVideos),
                if (saved) StatusChip(icon: Icons.download_done_rounded, label: l.savedFilter),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.item, required this.saved});
  final ContentItemRow item;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(context, item),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              _Thumb(url: item.imageUrl, kind: ContentKind.video, radius: 0),
              const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
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
              if (!item.seen || saved)
                Positioned(
                  left: 6,
                  top: 6,
                  child: StatusChip(
                    icon: saved ? Icons.download_done_rounded : null,
                    label: saved ? l.savedFilter : l.newBadge,
                    background: saved ? theme.colorScheme.secondaryContainer : context.dm.celebrate,
                    color: saved ? null : BrandColors.ink,
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, Space.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(item.subtitle ?? '', style: theme.textTheme.bodySmall, maxLines: 1),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.kind, this.width, this.height, this.radius = Radii.sm});
  final String? url;
  final ContentKind kind;
  final double? width, height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(kindIcon(kind), color: theme.colorScheme.onPrimaryContainer),
    );
    if (url == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

/// Item details with the right action per kind (read / listen / play /
/// watch), download for offline, and the mandatory credits + licence.
class ContentDetailSheet extends StatefulWidget {
  const ContentDetailSheet({super.key, required this.item});
  final ContentItemRow item;

  @override
  State<ContentDetailSheet> createState() => _ContentDetailSheetState();
}

class _ContentDetailSheetState extends State<ContentDetailSheet> {
  AudioPlayer? _player;
  bool _playing = false;
  bool _loadingAudio = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final url = widget.item.mediaUrl;
    if (url == null) return;
    if (_playing) {
      await _player?.pause();
      setState(() => _playing = false);
      return;
    }
    setState(() => _loadingAudio = true);
    try {
      _player ??= AudioPlayer();
      if (_player!.audioSource == null) {
        final local = await DownloadService.instance.localFile(url);
        if (local != null) {
          await _player!.setFilePath(local.path);
        } else {
          await _player!.setUrl(url);
        }
        await _player!.setLoopMode(LoopMode.one);
      }
      unawaited(_player!.play());
      setState(() => _playing = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).couldNotPlay)));
      }
    } finally {
      if (mounted) setState(() => _loadingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final it = widget.item;
    final kind = ContentKind.values.byName(it.kind);
    final isVideo = it.mediaFormat == 'video';
    final videoUrl = isVideo ? VideoPlayerScreen.streamUrl(it) : null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
        children: [
          if (it.imageUrl != null && kind != ContentKind.audio)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: CachedNetworkImage(
                  imageUrl: it.imageUrl!,
                  height: 180,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          const SizedBox(height: Space.md),
          Text(it.title, style: theme.textTheme.headlineSmall),
          if (it.subtitle != null && it.subtitle!.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Text(it.subtitle!, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              for (final t in it.tags.take(4)) StatusChip(label: t),
              if (it.durationSeconds != null)
                StatusChip(icon: Icons.timer_outlined, label: fmtDuration(it.durationSeconds!)),
            ],
          ),
          const SizedBox(height: Space.lg),
          if (kind == ContentKind.book && it.mediaUrl != null)
            FilledButton.icon(
              icon: const Icon(Icons.chrome_reader_mode_outlined),
              label: Text(l.readNow),
              onPressed: () =>
                  BookReader.open(context, title: it.title, url: it.mediaUrl!, format: it.mediaFormat, contentId: it.id),
            ),
          if (kind == ContentKind.audiobook && it.mediaUrl != null)
            FilledButton.icon(
              icon: const Icon(Icons.headphones_rounded),
              label: Text(l.listen),
              onPressed: () => AudiobookScreen.open(context, it),
            ),
          if (kind == ContentKind.audio && it.mediaUrl != null) ...[
            FilledButton.icon(
              icon: _loadingAudio
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
              label: Text(_playing ? l.pause : l.playLoops),
              onPressed: _loadingAudio ? null : _togglePlay,
            ),
            const SizedBox(height: Space.sm),
            DownloadButton(contentId: it.id, url: it.mediaUrl!, bytes: it.mediaBytes),
          ],
          if (videoUrl != null) ...[
            FilledButton.icon(
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: Text(it.mediaBytes == null ? l.watchVideo : l.watchVideoSize(fmtBytes(it.mediaBytes!))),
              onPressed: () => VideoPlayerScreen.open(context, it),
            ),
            const SizedBox(height: Space.sm),
            DownloadButton(contentId: it.id, url: videoUrl, bytes: it.mediaBytes),
          ],
          if (it.description != null && it.description!.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Text(it.description!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: Space.xl),
          const Divider(),
          const SizedBox(height: Space.sm),
          Text(l.creditsLicence, style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xs),
          if (it.attribution != null) Text(it.attribution!, style: theme.textTheme.bodySmall),
          Text(l.licenceLabel(it.license), style: theme.textTheme.bodySmall),
          if (it.sourceUrl != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.link_rounded, size: 18),
                label: Text(l.copySourceLink),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: it.sourceUrl!));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.sourceCopied)));
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Download for offline / progress / remove, for one media URL.
class DownloadButton extends StatefulWidget {
  const DownloadButton({super.key, required this.contentId, required this.url, this.bytes});
  final String contentId;
  final String url;
  final int? bytes;

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool? _saved;
  double? _progress; // non-null while downloading (may be indeterminate)
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    DownloadService.instance.localFile(widget.url).then((f) {
      if (mounted) setState(() => _saved = f != null);
    });
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _progress = null;
    });
    try {
      await DownloadService.instance.download(widget.contentId, widget.url, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (mounted) setState(() => _saved = true);
    } on DownloadCancelled {
      // user cancelled
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).downloadFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_busy) {
      return Row(children: [
        Expanded(child: LinearProgressIndicator(value: _progress)),
        const SizedBox(width: Space.sm),
        Text(_progress == null ? '' : '${(_progress! * 100).round()}%'),
        TextButton(onPressed: () => DownloadService.instance.cancel(widget.url), child: Text(l.cancel)),
      ]);
    }
    if (_saved == true) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.delete_outline_rounded),
        label: Text(l.removeDownload),
        onPressed: () async {
          await DownloadService.instance.remove(widget.contentId);
          if (mounted) setState(() => _saved = false);
        },
      );
    }
    return OutlinedButton.icon(
      icon: const Icon(Icons.download_rounded),
      label: Text(widget.bytes == null ? l.downloadOffline : l.downloadOfflineSize(fmtBytes(widget.bytes!))),
      onPressed: _saved == null ? null : _download,
    );
  }
}

String fmtDuration(int s) {
  if (s < 60) return '${s}s';
  final m = s ~/ 60;
  if (m < 60) return '$m min';
  return '${m ~/ 60} h ${m % 60} min';
}

String fmtBytes(int b) {
  if (b < 1024 * 1024) return '${(b / 1024).ceil()} KB';
  if (b < 1024 * 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(b < 10 * 1024 * 1024 ? 1 : 0)} MB';
  return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
