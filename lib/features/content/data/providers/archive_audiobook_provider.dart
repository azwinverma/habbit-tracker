import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/content_item.dart';
import 'content_provider.dart';

/// Public-domain audiobooks recorded by LibriVox volunteers, served from the
/// Internet Archive mirror (collection `librivoxaudio`, ~22k titles).
///
/// The catalogue stores one row per book; chapter lists are fetched only when
/// the user opens a book ([fetchChapters]), so a refresh is 3 small requests.
class ArchiveAudiobookProvider implements ContentProvider {
  ArchiveAudiobookProvider({this.baseUrl = 'https://archive.org', this.rows = 100});

  final String baseUrl;
  final int rows;

  @override
  String get id => 'librivox';
  @override
  String get displayName => 'LibriVox (via Internet Archive)';
  @override
  String get homepage => 'https://librivox.org';
  @override
  ContentKind get kind => ContentKind.audiobook;
  @override
  Duration get refreshEvery => const Duration(hours: 6);

  /// Most popular two pages, plus one page that rotates daily so new titles
  /// keep appearing.
  @visibleForTesting
  static List<int> pagesFor(DateTime now) {
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return [1, 2, 3 + dayOfYear % 40];
  }

  @override
  Future<List<ContentItem>> fetch(http.Client client, {required DateTime now}) async {
    final out = <String, ContentItem>{};
    Object? lastError;
    for (final page in pagesFor(now)) {
      try {
        final uri = Uri.parse('$baseUrl/advancedsearch.php').replace(queryParameters: {
          'q': 'collection:librivoxaudio AND language:(eng OR English) AND mediatype:audio',
          'fl[]': ['identifier', 'title', 'creator', 'downloads', 'runtime', 'description', 'licenseurl', 'subject'],
          'sort[]': 'downloads desc',
          'rows': '$rows',
          'page': '$page',
          'output': 'json',
        });
        final json = await getJson(client, uri, timeout: const Duration(seconds: 30));
        final docs = ((json['response'] as Map?)?['docs'] as List? ?? const []);
        for (final d in docs) {
          final item = parse(d as Map<String, dynamic>, page: page);
          if (item != null) out[item.id] = item;
        }
      } catch (e) {
        lastError = e;
      }
    }
    if (out.isEmpty && lastError != null) throw lastError;
    return out.values.toList();
  }

  @visibleForTesting
  static ContentItem? parse(Map<String, dynamic> d, {int page = 1}) {
    final id = d['identifier'] as String?;
    final title = _str(d['title'])?.trim();
    if (id == null || title == null || title.isEmpty) return null;
    // Skip bundle uploads ("... Collection", M4B packs) — they aren't single books.
    if (RegExp(r'collection|m4b', caseSensitive: false).hasMatch(id) ||
        RegExp(r'\bcollection\b', caseSensitive: false).hasMatch(title) && !title.contains(':')) {
      return null;
    }
    final licenseUrl = _str(d['licenseurl']);
    final license = licenseUrl == null || licenseUrl.contains('publicdomain')
        ? 'Public domain'
        : licenseUrl.contains('/by-sa/')
            ? 'CC BY-SA'
            : licenseUrl.contains('/by/')
                ? 'CC BY'
                : licenseUrl.contains('zero')
                    ? 'CC0'
                    : licenseUrl;
    if (!LicensePolicy.isAllowed(license)) return null;
    final subjects = (d['subject'] is List ? (d['subject'] as List).cast<Object>() : [d['subject'] ?? ''])
        .map((s) => s.toString().trim())
        .where((s) => s.isNotEmpty && s.length < 30 && !_genericTag.hasMatch(s))
        .take(3)
        .toList();
    return ContentItem(
      id: 'librivox:$id',
      provider: 'librivox',
      kind: ContentKind.audiobook,
      title: title,
      subtitle: _str(d['creator']),
      description: stripHtml(_str(d['description'])),
      mediaUrl: 'https://archive.org/metadata/$id',
      mediaFormat: 'audiobook',
      imageUrl: 'https://archive.org/services/img/$id',
      sourceUrl: 'https://archive.org/details/$id',
      license: license,
      licenseUrl: licenseUrl ?? 'https://librivox.org/pages/public-domain/',
      attribution: 'Read by LibriVox volunteers',
      tags: subjects,
      language: 'en',
      durationSeconds: parseClock(_str(d['runtime'])),
      popularity: (d['downloads'] as num?)?.toInt() ?? 0,
    );
  }

  static final _genericTag = RegExp(r'librivox|audio ?books?|^literature$', caseSensitive: false);

  static String? _str(Object? v) => v is List ? (v.isEmpty ? null : v.first.toString()) : v?.toString();
}

/// One chapter of an audiobook.
class AudiobookChapter {
  final String title;
  final String url;
  final int? seconds;
  final int? bytes;
  const AudiobookChapter(this.title, this.url, {this.seconds, this.bytes});
}

/// Loads an audiobook's chapters (64 kbps MP3s) from its Archive metadata URL.
Future<List<AudiobookChapter>> fetchChapters(http.Client client, String metadataUrl) async {
  final json = await getJson(client, Uri.parse(metadataUrl), timeout: const Duration(seconds: 30));
  return parseChapters(json);
}

@visibleForTesting
List<AudiobookChapter> parseChapters(Map<String, dynamic> json) {
  final id = (json['metadata'] as Map?)?['identifier'] as String?;
  final server = json['d1'] as String?;
  final dir = json['dir'] as String?;
  final files = (json['files'] as List? ?? const []).cast<Map<String, dynamic>>();
  final mp3 = files.where((f) => (f['name'] as String? ?? '').endsWith('_64kb.mp3')).toList()
    ..sort((a, b) {
      int track(Map<String, dynamic> f) => int.tryParse('${f['track'] ?? ''}'.split('/').first) ?? 9999;
      final t = track(a).compareTo(track(b));
      return t != 0 ? t : (a['name'] as String).compareTo(b['name'] as String);
    });
  return [
    for (final f in mp3)
      AudiobookChapter(
        (f['title'] as String?)?.trim().isNotEmpty == true ? f['title'] as String : f['name'] as String,
        id != null
            ? 'https://archive.org/download/$id/${Uri.encodeComponent(f['name'] as String)}'
            : 'https://$server$dir/${Uri.encodeComponent(f['name'] as String)}',
        seconds: parseClock(f['length'] as String?),
        bytes: int.tryParse('${f['size'] ?? ''}'),
      ),
  ];
}
