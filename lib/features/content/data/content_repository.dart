import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/content_item.dart';

/// Local, offline-capable cache of the content catalogue.
class ContentRepository {
  ContentRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$ContentItemsTable, ContentItemRow> _query(
    ContentKind kind, {
    String? search,
    bool onlyNew = false,
    String? tag,
  }) {
    final q = _db.select(_db.contentItems)..where((t) => t.kind.equals(kind.name));
    if (onlyNew) q.where((t) => t.seen.equals(false));
    final s = search?.trim();
    if (s != null && s.isNotEmpty) {
      final like = '%${s.replaceAll('%', '').replaceAll('_', '')}%';
      q.where((t) => t.title.like(like) | t.subtitle.like(like) | t.tags.like(like));
    }
    if (tag != null) q.where((t) => t.tags.like('%"$tag"%'));
    q.orderBy([
      (t) => OrderingTerm(expression: t.seen), // unseen (false) first
      (t) => OrderingTerm(expression: t.popularity, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.title),
    ]);
    return q;
  }

  Future<List<ContentItemRow>> list(ContentKind kind, {String? search, bool onlyNew = false, String? tag}) =>
      _query(kind, search: search, onlyNew: onlyNew, tag: tag).get();

  Stream<List<ContentItemRow>> watch(ContentKind kind, {String? search, bool onlyNew = false, String? tag}) =>
      _query(kind, search: search, onlyNew: onlyNew, tag: tag).watch();

  Stream<int> watchNewCount({ContentKind? kind}) {
    final count = _db.contentItems.id.count();
    final q = _db.selectOnly(_db.contentItems)
      ..addColumns([count])
      ..where(_db.contentItems.seen.equals(false));
    if (kind != null) q.where(_db.contentItems.kind.equals(kind.name));
    return q.map((r) => r.read(count) ?? 0).watchSingle();
  }

  Future<void> markSeen(ContentKind kind) =>
      (_db.update(_db.contentItems)..where((t) => t.kind.equals(kind.name) & t.seen.equals(false)))
          .write(const ContentItemsCompanion(seen: Value(true)));

  Future<ContentItemRow?> byId(String id) =>
      (_db.select(_db.contentItems)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts/updates a provider's items. Returns how many were new.
  ///
  /// On a provider's first-ever sync nothing is flagged as new (otherwise the
  /// whole catalogue would show "New").
  Future<int> upsert(String provider, List<ContentItem> items,
      {required DateTime now, required bool firstSync}) {
    return _db.transaction(() async {
      final existing = {
        for (final r in await (_db.select(_db.contentItems)..where((t) => t.provider.equals(provider))).get())
          r.id: r,
      };
      var added = 0;
      for (final i in items) {
        final prev = existing[i.id];
        if (prev == null) added++;
        await _db.into(_db.contentItems).insertOnConflictUpdate(ContentItemsCompanion.insert(
              id: i.id,
              provider: i.provider,
              kind: i.kind.name,
              title: i.title,
              subtitle: Value(i.subtitle),
              description: Value(i.description),
              mediaUrl: Value(i.mediaUrl),
              mediaFormat: Value(i.mediaFormat),
              imageUrl: Value(i.imageUrl),
              sourceUrl: Value(i.sourceUrl),
              license: i.license,
              licenseUrl: Value(i.licenseUrl),
              attribution: Value(i.attribution),
              tags: Value(i.tags),
              language: Value(i.language),
              durationSeconds: Value(i.durationSeconds),
              popularity: Value(i.popularity),
              firstSeenAt: prev?.firstSeenAt ?? now,
              lastSeenAt: now,
              seen: Value(prev?.seen ?? firstSync),
            ));
      }
      return added;
    });
  }

  /// Drops items a provider has not returned for [maxAge] (withdrawn or
  /// rotated out), keeping the cache bounded.
  Future<int> prune({required DateTime now, Duration maxAge = const Duration(days: 90)}) =>
      (_db.delete(_db.contentItems)..where((t) => t.lastSeenAt.isSmallerThanValue(now.subtract(maxAge)))).go();

  // ---- sync state ----

  Future<ContentSyncStateRow?> syncState(String provider) =>
      (_db.select(_db.contentSyncStates)..where((t) => t.provider.equals(provider))).getSingleOrNull();

  Stream<List<ContentSyncStateRow>> watchSyncStates() => _db.select(_db.contentSyncStates).watch();

  Future<void> recordAttempt(String provider, DateTime now) => _db.into(_db.contentSyncStates).insert(
        ContentSyncStatesCompanion.insert(provider: provider, lastAttemptAt: Value(now)),
        onConflict: DoUpdate((_) => ContentSyncStatesCompanion(lastAttemptAt: Value(now))),
      );

  Future<void> recordSuccess(String provider, DateTime now) async {
    final count = await (_db.select(_db.contentItems)..where((t) => t.provider.equals(provider))).get();
    await (_db.update(_db.contentSyncStates)..where((t) => t.provider.equals(provider))).write(
      ContentSyncStatesCompanion(
        lastSuccessAt: Value(now),
        lastError: const Value(null),
        itemCount: Value(count.length),
      ),
    );
  }

  Future<void> recordFailure(String provider, String error) =>
      (_db.update(_db.contentSyncStates)..where((t) => t.provider.equals(provider)))
          .write(ContentSyncStatesCompanion(lastError: Value(error)));
}
