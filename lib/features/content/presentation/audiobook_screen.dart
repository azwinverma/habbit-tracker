import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../../../app/theme.dart';
import '../../../core/db/app_database.dart';
import '../../../design/components.dart';
import '../../../l10n/app_localizations.dart';
import '../data/download_service.dart';
import '../data/playback_store.dart';
import '../domain/content_item.dart';
import '../data/providers/archive_audiobook_provider.dart';

/// Public-domain audiobook player (LibriVox). Chapters come from the
/// Internet Archive the first time and are cached; saved chapters play
/// offline. The listening position is remembered per book.
class AudiobookScreen extends StatefulWidget {
  const AudiobookScreen({super.key, required this.item});
  final ContentItemRow item;

  static Future<void> open(BuildContext context, ContentItemRow item) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AudiobookScreen(item: item)));

  @override
  State<AudiobookScreen> createState() => _AudiobookScreenState();
}

class _AudiobookScreenState extends State<AudiobookScreen> {
  final _player = AudioPlayer();
  List<AudiobookChapter>? _chapters;
  Set<String> _saved = {};
  String? _error;
  double? _downloadProgress; // null = not downloading
  bool _cancelDownload = false;
  StreamSubscription<Duration>? _posSub;
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);

  AppDatabase get _db => AppDatabase.instance;
  String get _chaptersKey => 'chapters:${widget.item.id}';
  String get _posKey => 'abpos:${widget.item.id}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      var chapters = _decode(await _db.getMeta(_chaptersKey));
      if (chapters == null) {
        chapters = await fetchChapters(http.Client(), widget.item.mediaUrl!);
        await _db.setMeta(_chaptersKey, jsonEncode([
          for (final c in chapters) {'t': c.title, 'u': c.url, 's': c.seconds, 'b': c.bytes},
        ]));
      }
      if (chapters.isEmpty) throw StateError('no chapters');
      await _refreshSaved(chapters);
      final sources = <AudioSource>[];
      for (final c in chapters) {
        final f = await DownloadService.instance.localFile(c.url);
        sources.add(f != null ? AudioSource.file(f.path) : AudioSource.uri(Uri.parse(c.url)));
      }
      final pos = (await _db.getMeta(_posKey))?.split('|');
      final index = int.tryParse(pos?.first ?? '') ?? 0;
      final ms = int.tryParse(pos?.last ?? '') ?? 0;
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: index.clamp(0, sources.length - 1),
        initialPosition: Duration(milliseconds: ms),
      );
      _posSub = _player.positionStream.listen(_savePosition);
      if (mounted) setState(() => _chapters = chapters);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  List<AudiobookChapter>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return [
        for (final m in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
          AudiobookChapter(m['t'] as String, m['u'] as String, seconds: m['s'] as int?, bytes: m['b'] as int?),
      ];
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshSaved(List<AudiobookChapter> chapters) async {
    final saved = <String>{};
    for (final c in chapters) {
      if (await DownloadService.instance.localFile(c.url) != null) saved.add(c.url);
    }
    if (mounted) setState(() => _saved = saved);
  }

  void _savePosition(Duration p) {
    final now = DateTime.now();
    if (now.difference(_lastSave) < const Duration(seconds: 5)) return;
    _lastSave = now;
    _db.setMeta(_posKey, '${_player.currentIndex ?? 0}|${p.inMilliseconds}');
    _markProgress(p);
  }

  /// Book-wide progress for "Continue listening" (chapter lengths permitting).
  void _markProgress(Duration p) {
    final chapters = _chapters;
    if (chapters == null || chapters.isEmpty) return;
    final i = (_player.currentIndex ?? 0).clamp(0, chapters.length - 1);
    final known = chapters.every((c) => c.seconds != null);
    final before = known ? chapters.take(i).fold<int>(0, (a, c) => a + c.seconds!) : 0;
    final total = known ? chapters.fold<int>(0, (a, c) => a + c.seconds!) : 0;
    PlaybackStore.instance.saveMedia(
      widget.item.id,
      ContentKind.audiobook,
      position: Duration(seconds: before) + p,
      duration: Duration(seconds: total),
      index: i,
      label: chapters[i].title,
      force: true,
    );
  }

  Future<void> _downloadAll() async {
    final chapters = _chapters;
    if (chapters == null) return;
    setState(() {
      _downloadProgress = 0;
      _cancelDownload = false;
    });
    try {
      for (var i = 0; i < chapters.length; i++) {
        if (_cancelDownload) break;
        await DownloadService.instance.download(widget.item.id, chapters[i].url,
            onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = (i + (p ?? 0)) / chapters.length);
        });
        if (mounted) setState(() => _saved = {..._saved, chapters[i].url});
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).downloadFailed)));
      }
    } finally {
      if (mounted) setState(() => _downloadProgress = null);
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _db.setMeta(_posKey, '${_player.currentIndex ?? 0}|${_player.position.inMilliseconds}');
    _markProgress(_player.position);
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final it = widget.item;
    final chapters = _chapters;
    final allSaved = chapters != null && chapters.every((c) => _saved.contains(c.url));

    return Scaffold(
      appBar: AppBar(title: Text(l.tabAudiobooks)),
      body: _error != null
          ? EmptyState(icon: Icons.wifi_off_rounded, title: l.couldNotPlay)
          : chapters == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xxl),
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.md),
                        child: it.imageUrl == null
                            ? const SizedBox(width: 96, height: 96)
                            : CachedNetworkImage(
                                imageUrl: it.imageUrl!, width: 96, height: 96, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const SizedBox(width: 96, height: 96)),
                      ),
                      const SizedBox(width: Space.lg),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(it.title, style: theme.textTheme.titleLarge),
                          if (it.subtitle != null) Text(it.subtitle!, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: Space.xs),
                          Text(l.chapterCount(chapters.length), style: theme.textTheme.bodySmall),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: Space.lg),
                    _PlayerControls(player: _player, chapters: chapters, fmt: _fmt),
                    const SizedBox(height: Space.md),
                    if (_downloadProgress != null)
                      Row(children: [
                        Expanded(child: LinearProgressIndicator(value: _downloadProgress)),
                        TextButton(onPressed: () => setState(() => _cancelDownload = true), child: Text(l.cancel)),
                      ])
                    else
                      OutlinedButton.icon(
                        onPressed: allSaved ? null : _downloadAll,
                        icon: Icon(allSaved ? Icons.download_done_rounded : Icons.download_rounded),
                        label: Text(allSaved ? l.downloaded : l.downloadAll),
                      ),
                    SectionHeader(l.chapters),
                    StreamBuilder<int?>(
                      stream: _player.currentIndexStream,
                      builder: (context, snap) => SurfaceCard(
                        padding: const EdgeInsets.symmetric(vertical: Space.xs),
                        child: Column(children: [
                          for (var i = 0; i < chapters.length; i++)
                            ListTile(
                              selected: snap.data == i,
                              leading: Text('${i + 1}', style: theme.textTheme.titleSmall),
                              title: Text(chapters[i].title, maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: chapters[i].seconds == null
                                  ? null
                                  : Text(_fmt(Duration(seconds: chapters[i].seconds!))),
                              trailing: _saved.contains(chapters[i].url)
                                  ? Icon(Icons.download_done_rounded, color: theme.colorScheme.primary, size: 20)
                                  : null,
                              onTap: () async {
                                await _player.seek(Duration.zero, index: i);
                                await _player.play();
                              },
                            ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: Space.lg),
                    Text('${it.attribution ?? ''} · ${it.license}', style: theme.textTheme.bodySmall),
                  ],
                ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({required this.player, required this.chapters, required this.fmt});
  final AudioPlayer player;
  final List<AudiobookChapter> chapters;
  final String Function(Duration) fmt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SurfaceCard(
      color: theme.colorScheme.primaryContainer,
      child: Column(children: [
        StreamBuilder<int?>(
          stream: player.currentIndexStream,
          builder: (_, s) => Text(
            s.data == null || s.data! >= chapters.length ? '' : chapters[s.data!].title,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
        StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (_, s) {
            final pos = s.data ?? Duration.zero;
            final dur = player.duration ?? Duration.zero;
            return Column(children: [
              Slider(
                value: dur.inMilliseconds == 0 ? 0 : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0),
                onChanged: dur.inMilliseconds == 0
                    ? null
                    : (v) => player.seek(Duration(milliseconds: (v * dur.inMilliseconds).round())),
              ),
              Row(children: [
                Text(fmt(pos), style: theme.textTheme.labelMedium),
                const Spacer(),
                Text(fmt(dur), style: theme.textTheme.labelMedium),
              ]),
            ]);
          },
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            tooltip: l.previousChapter,
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: () => player.hasPrevious ? player.seekToPrevious() : player.seek(Duration.zero),
          ),
          IconButton(
            tooltip: l.back30,
            icon: const Icon(Icons.replay_30_rounded),
            onPressed: () => player.seek(player.position - const Duration(seconds: 30)),
          ),
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (_, s) {
              final playing = s.data?.playing ?? false;
              final loading = s.data?.processingState == ProcessingState.loading ||
                  s.data?.processingState == ProcessingState.buffering;
              return IconButton.filled(
                tooltip: playing ? l.pause : l.play,
                iconSize: 40,
                onPressed: () => playing ? player.pause() : player.play(),
                icon: loading && playing
                    ? const SizedBox(width: 40, height: 40, child: Padding(
                        padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 3)))
                    : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
              );
            },
          ),
          IconButton(
            tooltip: l.forward30,
            icon: const Icon(Icons.forward_30_rounded),
            onPressed: () => player.seek(player.position + const Duration(seconds: 30)),
          ),
          IconButton(
            tooltip: l.nextChapter,
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: player.hasNext ? player.seekToNext : null,
          ),
        ]),
        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (_, s) => SegmentedButton<double>(
            showSelectedIcon: false,
            // The card is primaryContainer, so the default selected colour
            // (also primaryContainer) would be invisible here.
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: theme.colorScheme.primary,
              selectedForegroundColor: theme.colorScheme.onPrimary,
            ),
            segments: const [
              ButtonSegment(value: 1.0, label: Text('1×')),
              ButtonSegment(value: 1.25, label: Text('1.25×')),
              ButtonSegment(value: 1.5, label: Text('1.5×')),
            ],
            selected: {s.data ?? 1.0},
            onSelectionChanged: (v) => player.setSpeed(v.first),
          ),
        ),
      ]),
    );
  }
}
