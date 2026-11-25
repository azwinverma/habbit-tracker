import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/content_item.dart';

/// Where the user stopped in a video, audiobook or book, so it can
/// "continue where you left off". Stored on the phone only (AppMeta
/// `resume:<contentId>`), so it works offline and survives restarts.
class ResumePoint {
  const ResumePoint({
    required this.kind,
    required this.updatedAt,
    this.positionMs = 0,
    this.durationMs = 0,
    this.index = 0,
    this.cfi,
    this.label,
  });

  final ContentKind kind;

  /// Video / audiobook position within the current file.
  final int positionMs;
  final int durationMs;

  /// Audiobook chapter index (videos and books: 0).
  final int index;

  /// Book location (EPUB CFI).
  final String? cfi;

  /// Short human label, e.g. a chapter title.
  final String? label;
  final DateTime updatedAt;

  /// Videos shorter than this are exercise loops: they always start at 0.
  static const minResumableMs = 60 * 1000;

  /// Fraction watched (0..1) when the duration is known.
  double? get progress => durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : null;

  /// Whether a media position is worth resuming: long enough to matter,
  /// past the first few seconds and not already at the end.
  static bool worthResuming({required int positionMs, required int durationMs}) =>
      durationMs >= minResumableMs && positionMs >= 5000 && positionMs < durationMs - 10000;

  Map<String, Object?> toJson() => {
        'k': kind.name,
        'p': positionMs,
        'd': durationMs,
        'i': index,
        if (cfi != null) 'c': cfi,
        if (label != null) 'l': label,
        't': updatedAt.millisecondsSinceEpoch,
      };

  static ResumePoint? fromJson(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return ResumePoint(
        kind: ContentKind.values.byName(j['k'] as String),
        positionMs: (j['p'] as num?)?.toInt() ?? 0,
        durationMs: (j['d'] as num?)?.toInt() ?? 0,
        index: (j['i'] as num?)?.toInt() ?? 0,
        cfi: j['c'] as String?,
        label: j['l'] as String?,
        updatedAt: DateTime.fromMillisecondsSinceEpoch((j['t'] as num).toInt()),
      );
    } catch (_) {
      return null;
    }
  }
}

typedef ContinueEntry = ({ContentItemRow item, ResumePoint point});

class PlaybackStore {
  PlaybackStore(this._db);
  final AppDatabase _db;

  static PlaybackStore? _instance;
  static PlaybackStore get instance => _instance ??= PlaybackStore(AppDatabase.instance);
  static set instance(PlaybackStore s) => _instance = s;

  static const _prefix = 'resume:';
  static String _key(String id) => '$_prefix$id';

  Future<ResumePoint?> get(String contentId) async {
    final raw = await _db.getMeta(_key(contentId));
    return raw == null ? null : ResumePoint.fromJson(raw);
  }

  Future<void> save(String contentId, ResumePoint p) => _db.setMeta(_key(contentId), jsonEncode(p.toJson()));

  Future<void> clear(String contentId) => (_db.delete(_db.appMeta)..where((t) => t.key.equals(_key(contentId)))).go();

  /// Saves a media position, or clears it when finished / too short, so the
  /// "Continue" list only shows things actually in progress.
  Future<void> saveMedia(String contentId, ContentKind kind,
      {required Duration position, required Duration duration, int index = 0, String? label, bool force = false}) {
    final keep = force ||
        ResumePoint.worthResuming(positionMs: position.inMilliseconds, durationMs: duration.inMilliseconds);
    if (!keep) return clear(contentId);
    return save(
        contentId,
        ResumePoint(
          kind: kind,
          positionMs: position.inMilliseconds,
          durationMs: duration.inMilliseconds,
          index: index,
          label: label,
          updatedAt: DateTime.now(),
        ));
  }

  /// Items in progress (most recent first), optionally of one [kind].
  Stream<List<ContinueEntry>> watchContinue({ContentKind? kind, int limit = 10}) {
    final q = _db.select(_db.appMeta)..where((t) => t.key.like('$_prefix%'));
    return q.watch().asyncMap((rows) async {
      final points = <String, ResumePoint>{};
      for (final r in rows) {
        final p = ResumePoint.fromJson(r.value);
        if (p != null && (kind == null || p.kind == kind)) points[r.key.substring(_prefix.length)] = p;
      }
      if (points.isEmpty) return const <ContinueEntry>[];
      final items = await (_db.select(_db.contentItems)..where((t) => t.id.isIn(points.keys))).get();
      final out = [for (final it in items) (item: it, point: points[it.id]!)]
        ..sort((a, b) => b.point.updatedAt.compareTo(a.point.updatedAt));
      return out.take(limit).toList();
    });
  }
}
