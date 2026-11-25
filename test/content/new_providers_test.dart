import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/features/content/data/content_repository.dart';
import 'package:habit_tracker_nepali/features/content/data/download_service.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/archive_audiobook_provider.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/commons_video_provider.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/content_provider.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/wger_provider.dart';
import 'package:habit_tracker_nepali/features/content/domain/content_item.dart';
import 'package:habit_tracker_nepali/features/content/presentation/video_player_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('parseClock', () {
    expect(parseClock('3:55:07'), 3 * 3600 + 55 * 60 + 7);
    expect(parseClock('27:50'), 27 * 60 + 50);
    expect(parseClock('45'), 45);
    expect(parseClock('12.4'), 12);
    expect(parseClock(null), isNull);
  });

  group('getJson retries', () {
    test('429 then 200 succeeds', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return calls == 1 ? http.Response('busy', 429) : http.Response('{"ok":true}', 200);
      });
      final j = await getJson(client, Uri.parse('https://x'), baseDelay: Duration.zero);
      expect(j['ok'], isTrue);
      expect(calls, 2);
    });

    test('gives up after retries; 404 is not retried', () async {
      var calls = 0;
      final c500 = MockClient((_) async {
        calls++;
        return http.Response('down', 503);
      });
      await expectLater(getJson(c500, Uri.parse('https://x'), baseDelay: Duration.zero), throwsA(isA<http.ClientException>()));
      expect(calls, 3);
      calls = 0;
      final c404 = MockClient((_) async {
        calls++;
        return http.Response('no', 404);
      });
      await expectLater(getJson(c404, Uri.parse('https://x'), baseDelay: Duration.zero), throwsA(isA<http.ClientException>()));
      expect(calls, 1);
    });
  });

  group('LibriVox (Internet Archive)', () {
    test('parses a book; skips bundle uploads and non-free licences', () {
      final b = ArchiveAudiobookProvider.parse({
        'identifier': 'art_of_war_librivox',
        'title': 'The Art of War',
        'creator': 'Sun Tzu',
        'downloads': 24480653,
        'runtime': '1:08:23',
        'licenseurl': 'http://creativecommons.org/publicdomain/mark/1.0/',
        'subject': ['librivox', 'war', 'strategy'],
      })!;
      expect(b.id, 'librivox:art_of_war_librivox');
      expect(b.kind, ContentKind.audiobook);
      expect(b.license, 'Public domain');
      expect(b.mediaUrl, 'https://archive.org/metadata/art_of_war_librivox');
      expect(b.durationSeconds, 4103);
      expect(b.tags, ['war', 'strategy']);
      expect(ArchiveAudiobookProvider.parse({'identifier': 'LibrivoxM4bCollectionAudiobooksMain', 'title': 'Librivox M4b'}), isNull);
      expect(ArchiveAudiobookProvider.parse({
        'identifier': 'x', 'title': 'Y', 'licenseurl': 'https://creativecommons.org/licenses/by-nc/4.0/',
      }), isNull);
    });

    test('rotating page changes daily', () {
      expect(ArchiveAudiobookProvider.pagesFor(DateTime(2026, 1, 1)).take(2), [1, 2]);
      expect(ArchiveAudiobookProvider.pagesFor(DateTime(2026, 1, 1)).last,
          isNot(ArchiveAudiobookProvider.pagesFor(DateTime(2026, 1, 2)).last));
    });

    test('chapters: 64 kbps MP3s in track order with download URLs', () {
      final ch = parseChapters({
        'metadata': {'identifier': 'book_x'},
        'files': [
          {'name': 'book_02_64kb.mp3', 'title': 'Two', 'track': '2/3', 'length': '10:00', 'size': '100'},
          {'name': 'book_01_64kb.mp3', 'title': 'One', 'track': '1/3', 'length': '05:30'},
          {'name': 'book_01.mp3', 'title': 'One (128k)'},
          {'name': 'cover.jpg'},
        ],
      });
      expect(ch.map((c) => c.title), ['One', 'Two']);
      expect(ch.first.url, 'https://archive.org/download/book_x/book_01_64kb.mp3');
      expect(ch.first.seconds, 330);
      expect(ch.last.bytes, 100);
    });
  });

  group('Commons videos', () {
    Map<String, dynamic> page({String license = 'CC BY-SA 4.0', double duration = 60, String? restrictions}) => {
          'pageid': 42,
          'title': 'File:Sun_salutation_(yoga).webm',
          'videoinfo': [
            {
              'mediatype': 'VIDEO',
              'duration': duration,
              'url': 'https://upload.wikimedia.org/o.webm',
              'thumburl': 'https://upload.wikimedia.org/thumb.jpg',
              'descriptionurl': 'https://commons.wikimedia.org/wiki/File:Sun_salutation_(yoga).webm',
              'derivatives': [
                {'type': 'video/webm; codecs="vp9, opus"', 'src': 'https://t/x.webm.240p.vp9.webm'},
                {'type': 'video/webm; codecs="vp9, opus"', 'src': 'https://t/x.webm.480p.vp9.webm'},
                {'type': 'video/quicktime; codecs="mp4v"', 'src': 'https://t/x.webm.360p.mpeg4.mov'},
              ],
              'extmetadata': {
                'LicenseShortName': {'value': license},
                'Artist': {'value': '<a href="//commons.wikimedia.org/wiki/User:A">Asha</a>'},
                'ImageDescription': {'value': '<p>Twelve poses</p>'},
                if (restrictions != null) 'Restrictions': {'value': restrictions},
              },
            }
          ],
        };

    test('picks 480p VP9 for Android and MPEG-4 for iOS; credits the author', () {
      final v = CommonsVideoProvider.parse(page(), collection: 'Yoga')!;
      expect(v.title, 'Sun salutation (yoga)');
      expect(v.mediaUrl, 'https://t/x.webm.480p.vp9.webm');
      expect(v.altMediaUrl, 'https://t/x.webm.360p.mpeg4.mov');
      expect(v.attribution, 'Asha');
      expect(v.description, 'Twelve poses');
      expect(v.kind, ContentKind.video);
    });

    test('rejects NC/ND licences, restricted files and odd durations', () {
      expect(CommonsVideoProvider.parse(page(license: 'CC BY-NC 4.0'), collection: 'Yoga'), isNull);
      expect(CommonsVideoProvider.parse(page(restrictions: 'personality'), collection: 'Yoga'), isNull);
      expect(CommonsVideoProvider.parse(page(duration: 2), collection: 'Yoga'), isNull);
      expect(CommonsVideoProvider.parse(page(duration: 4000), collection: 'Yoga'), isNull);
    });
  });

  group('wger videos', () {
    Map<String, dynamic> ex(int id) => {
          'id': id,
          'license': {'short_name': 'CC-BY-SA 4'},
          'category': {'name': 'Legs'},
          'translations': [
            {'language': 2, 'name': 'Squat $id', 'description': '<p>Bend knees</p>'}
          ],
        };
    final licences = {2: (name: 'CC-BY-SA 4', url: 'https://cc/by-sa'), 9: (name: 'CC-BY-NC 4', url: null)};

    test('attaches the main / smallest allowed video and lists it as a video item', () {
      final items = WgerProvider.build([ex(1), ex(2)], videos: [
        {'id': 10, 'exercise': 1, 'video': 'https://w/big.mov', 'is_main': false, 'size': 900, 'duration': '9.0', 'license': 2},
        {'id': 11, 'exercise': 1, 'video': 'https://w/small.mov', 'is_main': false, 'size': 100, 'duration': '5.0', 'license': 2},
        {'id': 12, 'exercise': 2, 'video': 'https://w/nc.mov', 'is_main': true, 'size': 50, 'license': 9},
      ], licences: licences);
      final e1 = items.firstWhere((i) => i.id == 'wger:1');
      expect(e1.mediaUrl, 'https://w/small.mov');
      expect(e1.mediaFormat, 'video');
      expect(e1.mediaBytes, 100);
      expect(e1.tags.first, 'Video');
      final v = items.firstWhere((i) => i.id == 'wger-video:11');
      expect(v.kind, ContentKind.video);
      expect(v.title, 'Squat 1');
      // NC video rejected; exercise 2 stays without video.
      expect(items.firstWhere((i) => i.id == 'wger:2').mediaFormat, 'none');
      expect(items.where((i) => i.kind == ContentKind.video).length, 1);
    });
  });

  test('video URL per platform', () {
    final row = ContentItemRow(
      id: 'v', provider: 'p', kind: 'video', title: 't', mediaFormat: 'video', license: 'CC0',
      mediaUrl: 'https://a.webm', altMediaUrl: 'https://a.mov', tags: const [], popularity: 0,
      firstSeenAt: DateTime(2026), lastSeenAt: DateTime(2026), seen: true,
    );
    expect(VideoPlayerScreen.streamUrl(row, platform: TargetPlatform.android), 'https://a.webm');
    expect(VideoPlayerScreen.streamUrl(row, platform: TargetPlatform.iOS), 'https://a.mov');
  });

  group('DownloadService', () {
    late AppDatabase db;
    late Directory tmp;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      tmp = await Directory.systemTemp.createTemp('dm_dl');
    });
    tearDown(() async {
      await db.close();
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('saves, reports progress, reads back offline, removes', () async {
      final body = List<int>.generate(5000, (i) => i % 256);
      final client = MockClient.streaming((req, _) async =>
          http.StreamedResponse(Stream.fromIterable([body.sublist(0, 2500), body.sublist(2500)]), 200,
              contentLength: body.length));
      final s = DownloadService(db, client: client, baseDir: () async => tmp);
      final progress = <double?>[];
      final f = await s.download('c1', 'https://x/book.epub', onProgress: progress.add);
      expect(await f.readAsBytes(), body);
      expect(progress.last, 1.0);
      expect(f.path, endsWith('.epub'));
      expect((await s.localFile('https://x/book.epub'))?.path, f.path);
      // Second call is served from disk (no network).
      final offline = DownloadService(db, client: MockClient((_) async => throw Exception('offline')), baseDir: () async => tmp);
      expect(await offline.bytesFor('c1', 'https://x/book.epub'), body);
      await s.remove('c1');
      expect(await s.localFile('https://x/book.epub'), isNull);
      expect(await f.exists(), isFalse);
    });

    test('failed download leaves no file and no record', () async {
      final client = MockClient.streaming((req, _) async =>
          http.StreamedResponse(Stream<List<int>>.fromFuture(Future.error(const SocketException('drop'))), 200));
      final s = DownloadService(db, client: client, baseDir: () async => tmp);
      await expectLater(s.download('c1', 'https://x/a.mp3'), throwsA(isA<SocketException>()));
      expect(await s.localFile('https://x/a.mp3'), isNull);
      final files = await Directory('${tmp.path}/media').list().toList();
      expect(files, isEmpty);
    });

    test('pruning keeps downloaded items', () async {
      final repo = ContentRepository(db);
      final old = DateTime(2026, 1, 1);
      await repo.upsert('p', const [
        ContentItem(id: 'p:kept', provider: 'p', kind: ContentKind.book, title: 'Kept', license: 'Public domain'),
        ContentItem(id: 'p:gone', provider: 'p', kind: ContentKind.book, title: 'Gone', license: 'Public domain'),
      ], now: old, firstSync: true);
      await db.into(db.contentDownloads).insert(ContentDownloadsCompanion.insert(
          contentId: 'p:kept', url: 'u', localPath: '/x', savedAt: old));
      await repo.prune(now: DateTime(2026, 12, 1));
      expect((await repo.list(ContentKind.book)).map((r) => r.id), ['p:kept']);
    });
  });

  test('schema v1 -> v2 migration keeps data and adds columns + downloads table', () async {
    // Build a v1 database: current schema minus the v2 additions.
    final file = File('${(await Directory.systemTemp.createTemp('dm_mig')).path}/db.sqlite');
    final fresh = AppDatabase(NativeDatabase(file));
    await fresh.customSelect('SELECT 1').get(); // creates schema
    await fresh.customStatement('DROP TABLE content_downloads');
    await fresh.customStatement('ALTER TABLE content_items DROP COLUMN alt_media_url');
    await fresh.customStatement('ALTER TABLE content_items DROP COLUMN media_bytes');
    await fresh.customStatement(
        "INSERT INTO content_items (id, provider, kind, title, media_format, license, tags, popularity, first_seen_at, last_seen_at, seen) "
        "VALUES ('g:1', 'gutenberg', 'book', 'Walden', 'epub', 'Public domain', '[]', 0, 0, 0, 1)");
    await fresh.customStatement('PRAGMA user_version = 1');
    await fresh.close();

    final db = AppDatabase(NativeDatabase(file));
    final rows = await db.select(db.contentItems).get();
    expect(rows.single.title, 'Walden');
    expect(rows.single.altMediaUrl, isNull);
    await db.into(db.contentDownloads).insert(ContentDownloadsCompanion.insert(
        contentId: 'g:1', url: 'u', localPath: '/p', savedAt: DateTime(2026)));
    expect((await db.select(db.contentDownloads).get()).length, 1);
    expect(await db.customSelect('PRAGMA user_version').getSingle().then((r) => r.data.values.first), 2);
    await db.close();
  });

}
