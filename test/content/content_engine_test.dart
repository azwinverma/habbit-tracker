import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/features/content/data/content_repository.dart';
import 'package:habit_tracker_nepali/features/content/data/content_sync_service.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/content_provider.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/gutendex_provider.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/wger_provider.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/wikimedia_audio_provider.dart';
import 'package:habit_tracker_nepali/features/content/domain/content_item.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> gutBook(int id, {bool copyright = false, bool epub = true, String lang = 'en'}) => {
      'id': id,
      'title': 'Book $id',
      'authors': [
        {'name': 'Austen, Jane', 'birth_year': 1775, 'death_year': 1817}
      ],
      'summaries': ['A summary.'],
      'bookshelves': ['Category: Novels', 'Best Books Ever Listings'],
      'languages': [lang],
      'copyright': copyright,
      'formats': {
        if (epub) 'application/epub+zip': 'https://www.gutenberg.org/ebooks/$id.epub3.images',
        'image/jpeg': 'https://www.gutenberg.org/cache/epub/$id/pg$id.cover.medium.jpg',
      },
      'download_count': 1000 - id,
    };

Map<String, dynamic> commonsPage(int pageId, {String license = 'CC BY-SA 4.0', num duration = 60, bool mp3 = true}) => {
      'pageid': pageId,
      'title': 'File:Gentle_rain_$pageId.ogg',
      'imageinfo': [
        {
          'url': 'https://upload.wikimedia.org/x/Gentle_rain_$pageId.ogg?utm_source=commons.wikimedia.org',
          'descriptionurl': 'https://commons.wikimedia.org/wiki/File:Gentle_rain_$pageId.ogg',
          'mime': 'application/ogg',
          'duration': duration,
          'extmetadata': {
            'LicenseShortName': {'value': license},
            'LicenseUrl': {'value': 'https://creativecommons.org/licenses/by-sa/4.0'},
            'Artist': {'value': '<a href="//commons.wikimedia.org/wiki/User:Someone">Someone</a>'},
            'ImageDescription': {'value': 'Rain on a <b>tin</b> roof'},
          },
        }
      ],
      'videoinfo': [
        {
          'derivatives': [
            if (mp3) {'type': 'audio/mpeg', 'src': 'https://upload.wikimedia.org/t/Gentle_rain_$pageId.ogg.mp3'},
          ]
        }
      ],
    };

Map<String, dynamic> wgerExercise(int id, {bool english = true}) => {
      'id': id,
      'category': {'id': 10, 'name': 'Abs'},
      'muscles': [
        {'name': 'Rectus abdominis', 'name_en': 'Abs'}
      ],
      'equipment': [
        {'name': 'Mat'}
      ],
      'images': [
        {'image': 'https://wger.de/media/$id.png', 'is_main': true, 'license_author': 'Img Author'}
      ],
      'license': {'short_name': 'CC-BY-SA 4', 'url': 'https://creativecommons.org/licenses/by-sa/4.0/'},
      'translations': [
        if (english)
          {'language': 2, 'name': 'Crunch $id', 'description': '<p>Lie down.</p><ol><li>Curl up</li></ol>', 'license_author': 'Txt Author'},
        {'language': 1, 'name': 'Bauchpresse', 'description': '', 'license_author': 'X'},
      ],
    };

/// Configurable fake provider for sync-service tests.
class FakeProvider implements ContentProvider {
  FakeProvider(this.id, {this.refreshEvery = const Duration(hours: 6)});
  @override
  final String id;
  @override
  final Duration refreshEvery;
  List<ContentItem> items = [];
  Object? error;
  int calls = 0;

  @override
  String get displayName => id;
  @override
  String get homepage => 'https://example.org';
  @override
  ContentKind get kind => ContentKind.book;

  @override
  Future<List<ContentItem>> fetch(http.Client client, {required DateTime now}) async {
    calls++;
    if (error != null) throw error!;
    return items;
  }
}

ContentItem item(String provider, int n) => ContentItem(
      id: '$provider:$n', provider: provider, kind: ContentKind.book, title: 'T$n', license: 'Public domain');

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('LicensePolicy', () {
    test('accepts licences that allow commercial reuse', () {
      for (final l in ['Public domain', 'Public domain (US)', 'PD-self', 'CC0', 'CC0 1.0', 'CC BY 4.0', 'CC BY-SA 3.0', 'CC-BY-SA 4']) {
        expect(LicensePolicy.isAllowed(l), isTrue, reason: l);
      }
    });
    test('rejects NC / ND / unknown', () {
      for (final l in ['CC BY-NC 4.0', 'CC BY-NC-SA 3.0', 'CC BY-ND 4.0', 'All rights reserved', '', 'GFDL']) {
        expect(LicensePolicy.isAllowed(l), isFalse, reason: l);
      }
    });
  });

  group('Gutendex parser', () {
    test('maps a public-domain English EPUB book', () {
      final i = GutendexProvider.parse(gutBook(1342))!;
      expect(i.id, 'gutenberg:1342');
      expect(i.subtitle, 'Jane Austen');
      expect(i.mediaFormat, 'epub');
      expect(i.mediaUrl, endsWith('1342.epub3.images'));
      expect(i.tags, ['Novels']);
      expect(i.sourceUrl, 'https://www.gutenberg.org/ebooks/1342');
    });
    test('skips copyrighted, non-EPUB and non-English books', () {
      expect(GutendexProvider.parse(gutBook(1, copyright: true)), isNull);
      expect(GutendexProvider.parse(gutBook(2, epub: false)), isNull);
      expect(GutendexProvider.parse(gutBook(3, lang: 'fr')), isNull);
    });
    test('fetch tolerates one failing page, merges and de-duplicates', () async {
      final client = MockClient((req) async {
        final page = req.url.queryParameters['page'];
        if (page == '2') return http.Response('oops', 500);
        return http.Response(jsonEncode({'results': [gutBook(1), gutBook(int.parse(page!) + 100)]}), 200);
      });
      final items = await GutendexProvider().fetch(client, now: DateTime(2026, 11, 24));
      expect(items.map((i) => i.id).toSet().length, items.length);
      expect(items.length, 3); // book 1 (shared) + one unique per successful page
    });
    test('rotating page changes daily', () {
      expect(GutendexProvider.pagesFor(DateTime(2026, 1, 1)), isNot(GutendexProvider.pagesFor(DateTime(2026, 1, 2))));
    });
  });

  group('Wikimedia parser', () {
    test('maps a CC BY-SA sound with MP3 transcode and plain-text credits', () {
      final i = WikimediaAudioProvider.parse(commonsPage(7), 'Rain')!;
      expect(i.id, 'commons:7');
      expect(i.title, 'Gentle rain 7');
      expect(i.mediaFormat, 'mp3');
      expect(i.mediaUrl, endsWith('.mp3'));
      expect(i.attribution, 'Someone');
      expect(i.description, 'Rain on a tin roof');
      expect(i.license, 'CC BY-SA 4.0');
      expect(i.sourceUrl, isNot(contains('utm_')));
    });
    test('rejects NC licence, too-short clips and files without MP3', () {
      expect(WikimediaAudioProvider.parse(commonsPage(1, license: 'CC BY-NC 4.0'), 'Rain'), isNull);
      expect(WikimediaAudioProvider.parse(commonsPage(2, duration: 5), 'Rain'), isNull);
      expect(WikimediaAudioProvider.parse(commonsPage(3, mp3: false), 'Rain'), isNull);
    });
  });

  group('wger parser', () {
    test('maps English exercise with credits for text and image', () {
      final i = WgerProvider.parse(wgerExercise(5))!;
      expect(i.title, 'Crunch 5');
      expect(i.kind, ContentKind.exercise);
      expect(i.description, contains('Lie down.'));
      expect(i.description, contains('• Curl up'));
      expect(i.description, contains('Muscles: Abs'));
      expect(i.attribution, 'Text: Txt Author · Image: Img Author');
      expect(i.imageUrl, 'https://wger.de/media/5.png');
    });
    test('skips exercises without an English translation', () {
      expect(WgerProvider.parse(wgerExercise(6, english: false)), isNull);
    });
    test('follows pagination', () async {
      final client = MockClient((req) async {
        final offset = req.url.queryParameters['offset'];
        return http.Response(
            jsonEncode({
              'results': [wgerExercise(offset == '0' ? 1 : 2)],
              'next': offset == '0' ? 'https://wger.de/api/v2/exerciseinfo/?limit=100&offset=100' : null,
            }),
            200);
      });
      final items = await WgerProvider().fetch(client, now: DateTime.now());
      expect(items.map((i) => i.title), ['Crunch 1', 'Crunch 2']);
    });
  });

  group('ContentSyncService', () {
    late AppDatabase db;
    late ContentRepository repo;
    late FakeProvider p;
    late DateTime now;

    ContentSyncService service() => ContentSyncService(
          repository: repo,
          providers: [p],
          client: MockClient((_) async => http.Response('', 500)),
          clock: () => now,
        );

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ContentRepository(db);
      p = FakeProvider('fake');
      now = DateTime(2026, 11, 24, 9);
    });
    tearDown(() => db.close());

    test('first sync fills the catalogue without flagging everything as new', () async {
      p.items = [item('fake', 1), item('fake', 2)];
      final r = await service().syncIfStale();
      expect(r.single.fetched, 2);
      expect((await repo.list(ContentKind.book)).length, 2);
      expect(await repo.watchNewCount().first, 0);
    });

    test('items appearing in a later sync are marked new until viewed', () async {
      p.items = [item('fake', 1)];
      await service().syncIfStale();
      now = now.add(const Duration(hours: 7));
      p.items = [item('fake', 1), item('fake', 2), item('fake', 3)];
      final r = await service().syncIfStale();
      expect(r.single.newItems, 2);
      expect(await repo.watchNewCount(kind: ContentKind.book).first, 2);
      expect((await repo.list(ContentKind.book)).first.seen, isFalse); // new ones listed first

      await repo.markSeen(ContentKind.book);
      expect(await repo.watchNewCount().first, 0);
    });

    test('respects the refresh interval unless forced', () async {
      p.items = [item('fake', 1)];
      await service().syncIfStale();
      now = now.add(const Duration(hours: 1));
      expect((await service().syncIfStale()).single.skipped, isTrue);
      expect(p.calls, 1);
      await service().syncIfStale(force: true);
      expect(p.calls, 2);
    });

    test('failure keeps the cached catalogue, records error, backs off', () async {
      p.items = [item('fake', 1), item('fake', 2)];
      await service().syncIfStale();
      now = now.add(const Duration(hours: 7));
      p.error = Exception('offline');
      final r = await service().syncIfStale();
      expect(r.single.error, contains('offline'));
      expect((await repo.list(ContentKind.book)).length, 2);
      expect((await repo.syncState('fake'))!.lastError, contains('offline'));

      now = now.add(const Duration(minutes: 5));
      expect((await service().syncIfStale()).single.skipped, isTrue); // back-off

      now = now.add(const Duration(minutes: 20));
      p.error = null;
      expect((await service().syncIfStale()).single.error, isNull);
      expect((await repo.syncState('fake'))!.lastError, isNull);
    });

    test('empty response never wipes the cache', () async {
      p.items = [item('fake', 1)];
      await service().syncIfStale();
      now = now.add(const Duration(hours: 7));
      p.items = [];
      final r = await service().syncIfStale();
      expect(r.single.error, isNotNull);
      expect((await repo.list(ContentKind.book)).length, 1);
    });

    test('items not returned for 90 days are pruned', () async {
      p.items = [item('fake', 1), item('fake', 2)];
      await service().syncIfStale();
      p.items = [item('fake', 2)];
      now = now.add(const Duration(days: 91));
      await service().syncIfStale();
      expect((await repo.list(ContentKind.book)).map((r) => r.id), ['fake:2']);
    });

    test('concurrent calls share a single run', () async {
      p.items = [item('fake', 1)];
      final s = service();
      await Future.wait([s.syncIfStale(), s.syncIfStale(), s.syncIfStale()]);
      expect(p.calls, 1);
    });

    test('search matches title, author and tags', () async {
      await repo.upsert('x', [
        const ContentItem(id: 'x:1', provider: 'x', kind: ContentKind.book, title: 'Walden', subtitle: 'Henry David Thoreau', license: 'PD', tags: ['Nature']),
        const ContentItem(id: 'x:2', provider: 'x', kind: ContentKind.book, title: 'Emma', subtitle: 'Jane Austen', license: 'PD'),
      ], now: now, firstSync: true);
      expect((await repo.list(ContentKind.book, search: 'thoreau')).single.id, 'x:1');
      expect((await repo.list(ContentKind.book, search: 'nature')).single.id, 'x:1');
      expect((await repo.list(ContentKind.book, search: 'emma')).single.id, 'x:2');
    });
  });
}
