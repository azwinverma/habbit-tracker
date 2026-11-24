import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/providers.dart';
import '../../../core/db/app_database.dart';
import '../../../screens/reading_screen.dart' show BookReader;
import '../domain/content_item.dart';

/// Browse the free content catalogue (works offline from the cache).
/// New items from the latest refresh are listed first with a "New" badge.
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

  /// Items count as "seen" after the user has had a moment on the tab, so
  /// the New badges are visible first.
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
    final r = await ref.read(contentSyncServiceProvider).syncIfStale(force: true);
    if (!mounted) return;
    final added = r.fold<int>(0, (a, b) => a + b.newItems);
    final allFailed = r.every((x) => x.error != null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(allFailed
          ? 'You\'re offline or sources are busy. Showing saved content.'
          : added > 0
              ? '$added new items'
              : 'You\'re up to date'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search titles, authors, topics',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 250), () => setState(() => _query = v));
                  },
                ),
              ),
              TabBar(
                controller: _tabs,
                tabs: [
                  for (final k in ContentKind.values) _TabLabel(kind: k),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          for (final k in ContentKind.values)
            _ContentList(kind: k, query: _query, onRefresh: _refresh),
        ],
      ),
    );
  }
}

class _TabLabel extends ConsumerWidget {
  const _TabLabel({required this.kind});
  final ContentKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(_newCountByKind(kind)).valueOrNull ?? 0;
    final label = switch (kind) {
      ContentKind.book => 'Books',
      ContentKind.audio => 'Sounds',
      ContentKind.exercise => 'Exercises',
    };
    return Tab(
      child: Badge(isLabelVisible: n > 0, label: Text('$n'), child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(label),
      )),
    );
  }
}

final _newCountByKind = StreamProvider.family<int, ContentKind>(
    (ref, k) => ref.watch(contentRepositoryProvider).watchNewCount(kind: k));

class _ContentList extends ConsumerWidget {
  const _ContentList({required this.kind, required this.query, required this.onRefresh});
  final ContentKind kind;
  final String query;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(contentListProvider((kind: kind, search: query, tag: null)));
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load content.\n$e', textAlign: TextAlign.center),
        )]),
        data: (list) {
          if (list.isEmpty) {
            return ListView(children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Icon(Icons.cloud_download_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    query.isNotEmpty
                        ? 'Nothing matches "$query".'
                        : 'Nothing here yet. Connect to the internet and pull down to load free content.',
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ]);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (c, i) => _ContentTile(item: list[i]),
          );
        },
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  const _ContentTile({required this.item});
  final ContentItemRow item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = ContentKind.values.byName(item.kind);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: _Thumb(url: item.imageUrl, kind: kind),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            if (item.subtitle != null && item.subtitle!.isNotEmpty) item.subtitle!,
            if (item.durationSeconds != null) _fmtDuration(item.durationSeconds!),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: item.seen
            ? null
            : Chip(
                label: const Text('New'),
                visualDensity: VisualDensity.compact,
                backgroundColor: theme.colorScheme.tertiaryContainer,
                side: BorderSide.none,
              ),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: true,
          builder: (_) => _ContentDetail(item: item),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.kind});
  final String? url;
  final ContentKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        switch (kind) {
          ContentKind.book => Icons.menu_book,
          ContentKind.audio => Icons.graphic_eq,
          ContentKind.exercise => Icons.fitness_center,
        },
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
    if (url == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 48,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

class _ContentDetail extends StatefulWidget {
  const _ContentDetail({required this.item});
  final ContentItemRow item;

  @override
  State<_ContentDetail> createState() => _ContentDetailState();
}

class _ContentDetailState extends State<_ContentDetail> {
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
        await _player!.setUrl(url);
        await _player!.setLoopMode(LoopMode.one);
      }
      unawaited(_player!.play());
      setState(() => _playing = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not play this sound. Check your connection.')));
      }
    } finally {
      if (mounted) setState(() => _loadingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final it = widget.item;
    final kind = ContentKind.values.byName(it.kind);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          if (it.imageUrl != null && kind != ContentKind.audio)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: it.imageUrl!,
                  height: 180,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(it.title, style: theme.textTheme.headlineSmall),
          if (it.subtitle != null && it.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(it.subtitle!, style: theme.textTheme.titleMedium),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final t in it.tags) Chip(label: Text(t), visualDensity: VisualDensity.compact),
              if (it.durationSeconds != null)
                Chip(avatar: const Icon(Icons.timer_outlined, size: 18), label: Text(_fmtDuration(it.durationSeconds!))),
            ],
          ),
          const SizedBox(height: 12),
          if (kind == ContentKind.book && it.mediaUrl != null)
            FilledButton.icon(
              icon: const Icon(Icons.chrome_reader_mode_outlined),
              label: const Text('Read now'),
              onPressed: () => BookReader.open(context, title: it.title, url: it.mediaUrl!, format: it.mediaFormat),
            ),
          if (kind == ContentKind.audio && it.mediaUrl != null)
            FilledButton.icon(
              icon: _loadingAudio
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_playing ? Icons.pause : Icons.play_arrow),
              label: Text(_playing ? 'Pause' : 'Play (loops)'),
              onPressed: _loadingAudio ? null : _togglePlay,
            ),
          if (it.description != null && it.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(it.description!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          const Divider(),
          Text('Credits & licence', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          if (it.attribution != null) Text(it.attribution!),
          Text('Licence: ${it.license}'),
          if (it.sourceUrl != null)
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Copy source link'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: it.sourceUrl!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Source link copied')));
              },
            ),
        ],
      ),
    );
  }
}

String _fmtDuration(int s) {
  if (s < 60) return '${s}s';
  final m = s ~/ 60;
  if (m < 60) return '$m min';
  return '${m ~/ 60} h ${m % 60} min';
}
