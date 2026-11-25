import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/content_item.dart';
import 'content_provider.dart';

/// Freely licensed exercise, yoga and meditation videos from Wikimedia
/// Commons (curated categories). Licence filter as everywhere: PD, CC0,
/// CC BY, CC BY-SA, with author credit shown.
///
/// Commons stores WebM; it also serves transcodes. We keep a VP9 WebM
/// rendition (plays on Android) as [ContentItem.mediaUrl] and the MPEG-4
/// QuickTime rendition (plays on iOS) as [ContentItem.altMediaUrl].
class CommonsVideoProvider implements ContentProvider {
  CommonsVideoProvider({this.apiUrl = 'https://commons.wikimedia.org/w/api.php'});

  final String apiUrl;

  @override
  String get id => 'commons-video';
  @override
  String get displayName => 'Wikimedia Commons (videos)';
  @override
  String get homepage => 'https://commons.wikimedia.org';
  @override
  ContentKind get kind => ContentKind.video;
  @override
  Duration get refreshEvery => const Duration(hours: 12);

  /// Label -> Commons category.
  static const categories = <String, String>{
    'Exercise': 'Videos of physical exercises',
    'Yoga': 'Videos of yoga',
    'Meditation': 'Videos of meditation',
  };

  static const minSeconds = 5;
  static const maxSeconds = 45 * 60;

  @override
  Future<List<ContentItem>> fetch(http.Client client, {required DateTime now}) async {
    final out = <String, ContentItem>{};
    Object? lastError;
    var ok = 0;
    for (final c in categories.entries) {
      try {
        final uri = Uri.parse(apiUrl).replace(queryParameters: {
          'action': 'query',
          'format': 'json',
          'formatversion': '2',
          'generator': 'categorymembers',
          'gcmtitle': 'Category:${c.value}',
          'gcmtype': 'file',
          'gcmlimit': '100',
          'prop': 'videoinfo',
          'viprop': 'url|derivatives|extmetadata|size|mediatype',
          'viurlwidth': '480',
        });
        final json = await getJson(client, uri, timeout: const Duration(seconds: 30));
        for (final p in ((json['query'] as Map?)?['pages'] as List? ?? const [])) {
          final item = parse(p as Map<String, dynamic>, collection: c.key);
          if (item != null) out[item.id] = item;
        }
        ok++;
      } catch (e) {
        lastError = e;
      }
    }
    if (ok == 0 && lastError != null) throw lastError;
    return out.values.toList();
  }

  @visibleForTesting
  static ContentItem? parse(Map<String, dynamic> page, {required String collection}) {
    final infos = (page['videoinfo'] as List? ?? const []).cast<Map<String, dynamic>>();
    if (infos.isEmpty) return null;
    final v = infos.first;
    if ((v['mediatype'] as String?) != null && v['mediatype'] != 'VIDEO') return null;
    final duration = (v['duration'] as num?)?.toDouble() ?? 0;
    if (duration < minSeconds || duration > maxSeconds) return null;

    final meta = (v['extmetadata'] as Map?)?.cast<String, dynamic>() ?? const {};
    String? m(String k) => ((meta[k] as Map?)?['value'])?.toString();
    final license = m('LicenseShortName') ?? '';
    if (!LicensePolicy.isAllowed(license)) return null;
    if ((m('Restrictions') ?? '').isNotEmpty) return null; // trademark/personality restrictions

    final derivatives = (v['derivatives'] as List? ?? const []).cast<Map<String, dynamic>>();
    String? pick(bool Function(String type, String src) test, List<String> prefer) {
      for (final q in prefer) {
        final hit = derivatives.where((d) => test('${d['type']}', '${d['src']}') && '${d['src']}'.contains(q));
        if (hit.isNotEmpty) return '${hit.first['src']}';
      }
      final any = derivatives.where((d) => test('${d['type']}', '${d['src']}'));
      return any.isEmpty ? null : '${any.first['src']}';
    }

    final webm = pick((t, s) => t.contains('vp9') || (t.contains('webm') && s.contains('.webm')),
        ['.480p.', '.360p.', '.240p.']);
    final mov = pick((t, s) => t.contains('quicktime') || s.endsWith('.mov') || s.endsWith('.mp4'),
        ['.480p.', '.360p.', '.240p.']);
    final main = webm ?? (v['url'] as String?);
    if (main == null) return null;

    final rawTitle = (page['title'] as String? ?? '').replaceFirst(RegExp(r'^File:'), '');
    final title = rawTitle
        .replaceAll(RegExp(r'\.(webm|ogv|ogg|mp4)(\.webm|hd\.webm)?$', caseSensitive: false), '')
        .replaceAll('_', ' ')
        .trim();
    if (title.isEmpty) return null;
    final artist = stripHtml(m('Artist'));

    return ContentItem(
      id: 'commons-video:${page['pageid']}',
      provider: 'commons-video',
      kind: ContentKind.video,
      title: title,
      subtitle: collection,
      description: stripHtml(m('ImageDescription')),
      mediaUrl: main,
      mediaFormat: 'video',
      altMediaUrl: mov,
      imageUrl: v['thumburl'] as String?,
      sourceUrl: v['descriptionurl'] as String?,
      license: license,
      licenseUrl: m('LicenseUrl'),
      attribution: artist.isEmpty ? 'Wikimedia Commons contributors' : artist,
      tags: [collection],
      durationSeconds: duration.round(),
    );
  }
}
