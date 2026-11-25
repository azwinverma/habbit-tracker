import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/content_item.dart';
import 'content_provider.dart';

/// Exercise library from wger (https://wger.de), an open-source fitness
/// project. Exercise texts are CC BY-SA 4.0; images carry their own author
/// and licence. English entries only for now (Nepali in Phase 3).
///
/// The full catalogue is ~1,000 exercises (~10 requests; the API has no
/// "changed since" filter), refreshed at most daily. Exercise videos (~80,
/// HEVC) are attached to their exercise and also listed as video items.
class WgerProvider implements ContentProvider {
  WgerProvider({this.baseUrl = 'https://wger.de', this.maxPages = 12});

  final String baseUrl;
  final int maxPages;

  static const _english = 2;

  @override
  String get id => 'wger';
  @override
  String get displayName => 'wger Workout Manager';
  @override
  String get homepage => 'https://wger.de';
  @override
  ContentKind get kind => ContentKind.exercise;
  @override
  Duration get refreshEvery => const Duration(hours: 24);

  @override
  Future<List<ContentItem>> fetch(http.Client client, {required DateTime now}) async {
    final raw = <Map<String, dynamic>>[];
    Uri? next = Uri.parse('$baseUrl/api/v2/exerciseinfo/?limit=100&offset=0');
    var pages = 0;
    while (next != null && pages < maxPages) {
      final json = await getJson(client, next, timeout: const Duration(seconds: 40));
      raw.addAll((json['results'] as List? ?? const []).cast<Map<String, dynamic>>());
      final n = json['next'] as String?;
      next = n == null ? null : Uri.parse(n);
      pages++;
    }

    // Videos are optional: a failure here must not lose the exercise list.
    var videos = <Map<String, dynamic>>[];
    var licences = <int, ({String name, String? url})>{};
    try {
      final lic = await getJson(client, Uri.parse('$baseUrl/api/v2/license/?limit=50'));
      licences = {
        for (final l in (lic['results'] as List? ?? const []).cast<Map<String, dynamic>>())
          l['id'] as int: (name: '${l['short_name']}', url: l['url'] as String?),
      };
      final v = await getJson(client, Uri.parse('$baseUrl/api/v2/video/?limit=200'));
      videos = (v['results'] as List? ?? const []).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[wger] videos unavailable: $e');
    }
    return build(raw, videos: videos, licences: licences);
  }

  /// Exercises (with their best video attached) + one video item per
  /// exercise that has a video.
  @visibleForTesting
  static List<ContentItem> build(List<Map<String, dynamic>> exercises,
      {List<Map<String, dynamic>> videos = const [], Map<int, ({String name, String? url})> licences = const {}}) {
    final byExercise = <int, Map<String, dynamic>>{};
    for (final v in videos) {
      final lic = licences[v['license']];
      if (lic != null && !LicensePolicy.isAllowed(lic.name.replaceAll('-', ' '))) continue;
      final ex = v['exercise'] as int?;
      if (ex == null || v['video'] == null) continue;
      final cur = byExercise[ex];
      // Prefer the main video, then the smallest file (mobile data).
      final better = cur == null ||
          (v['is_main'] == true && cur['is_main'] != true) ||
          ((v['is_main'] == true) == (cur['is_main'] == true) &&
              ((v['size'] as num?) ?? 1 << 40) < ((cur['size'] as num?) ?? 1 << 40));
      if (better) byExercise[ex] = v;
    }

    final out = <ContentItem>[];
    for (final e in exercises) {
      final item = parse(e);
      if (item == null) continue;
      final v = byExercise[e['id']];
      if (v == null) {
        out.add(item);
        continue;
      }
      final lic = licences[v['license']];
      final seconds = double.tryParse('${v['duration'] ?? ''}')?.round();
      final bytes = (v['size'] as num?)?.toInt();
      final videoCredit = (v['license_author'] as String?)?.trim();
      final withVideo = ContentItem(
        id: item.id,
        provider: item.provider,
        kind: item.kind,
        title: item.title,
        subtitle: item.subtitle,
        description: item.description,
        mediaUrl: v['video'] as String,
        mediaFormat: 'video',
        mediaBytes: bytes,
        imageUrl: item.imageUrl,
        sourceUrl: item.sourceUrl,
        license: item.license,
        licenseUrl: item.licenseUrl,
        attribution: [
          item.attribution,
          if (videoCredit != null && videoCredit.isNotEmpty) 'Video: $videoCredit',
        ].join(' · '),
        tags: ['Video', ...item.tags],
        language: item.language,
        durationSeconds: seconds,
        popularity: 1,
      );
      out.add(withVideo);
      out.add(ContentItem(
        id: 'wger-video:${v['id']}',
        provider: 'wger',
        kind: ContentKind.video,
        title: item.title,
        subtitle: 'Exercise demo',
        description: item.description,
        mediaUrl: v['video'] as String,
        mediaFormat: 'video',
        mediaBytes: bytes,
        imageUrl: item.imageUrl,
        sourceUrl: item.sourceUrl,
        license: lic?.name ?? item.license,
        licenseUrl: lic?.url ?? item.licenseUrl,
        attribution: videoCredit == null || videoCredit.isEmpty ? 'wger contributors' : videoCredit,
        tags: ['Exercise demo', ...item.tags.take(2)],
        durationSeconds: seconds,
      ));
    }
    return out;
  }

  @visibleForTesting
  static ContentItem? parse(Map<String, dynamic> e) {
    final translations = (e['translations'] as List? ?? const []).cast<Map<String, dynamic>>();
    final en = translations.where((t) => t['language'] == _english).firstOrNull;
    if (en == null) return null;
    final name = (en['name'] as String? ?? '').trim();
    if (name.isEmpty) return null;

    final license = ((e['license'] as Map?)?['short_name'] as String?) ?? 'CC-BY-SA 4';
    if (!LicensePolicy.isAllowed(license.replaceAll('-', ' '))) return null;

    final category = (e['category'] as Map?)?['name'] as String?;
    final muscles = (e['muscles'] as List? ?? const [])
        .map((m) => ((m as Map)['name_en'] as String?)?.trim().isNotEmpty == true
            ? m['name_en'] as String
            : (m['name'] as String? ?? ''))
        .where((s) => s.isNotEmpty)
        .toList();
    final equipment = (e['equipment'] as List? ?? const [])
        .map((x) => (x as Map)['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    final images = (e['images'] as List? ?? const []).cast<Map<String, dynamic>>();
    final image = images.where((i) => i['is_main'] == true).firstOrNull ?? images.firstOrNull;

    final textAuthor = (en['license_author'] as String?)?.trim();
    final imageAuthor = (image?['license_author'] as String?)?.trim();
    final credit = [
      if (textAuthor != null && textAuthor.isNotEmpty) 'Text: $textAuthor',
      if (imageAuthor != null && imageAuthor.isNotEmpty) 'Image: $imageAuthor',
    ].join(' · ');

    final description = stripHtml(en['description'] as String?);
    final details = [
      if (muscles.isNotEmpty) 'Muscles: ${muscles.join(', ')}',
      if (equipment.isNotEmpty) 'Equipment: ${equipment.join(', ')}',
    ].join('\n');

    return ContentItem(
      id: 'wger:${e['id']}',
      provider: 'wger',
      kind: ContentKind.exercise,
      title: name,
      subtitle: [if (category != null) category, ...equipment.take(1)].join(' · '),
      description: [if (description.isNotEmpty) description, if (details.isNotEmpty) details].join('\n\n'),
      imageUrl: image?['image'] as String?,
      sourceUrl: 'https://wger.de/en/exercise/${e['id']}/view-base',
      license: license,
      licenseUrl: (e['license'] as Map?)?['url'] as String?,
      attribution: credit.isEmpty ? 'wger contributors' : credit,
      tags: [if (category != null) category, ...muscles.take(3)],
      language: 'en',
    );
  }
}
