import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/content_item.dart';
import 'content_provider.dart';

/// Exercise library from wger (https://wger.de), an open-source fitness
/// project. Exercise texts are CC BY-SA 4.0; images carry their own author
/// and licence. English entries only for now (Nepali in Phase 3).
///
/// The full catalogue is ~1,000 exercises (~10 requests), so it refreshes
/// weekly to keep mobile data use low.
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
  Duration get refreshEvery => const Duration(days: 7);

  @override
  Future<List<ContentItem>> fetch(http.Client client, {required DateTime now}) async {
    final out = <ContentItem>[];
    Uri? next = Uri.parse('$baseUrl/api/v2/exerciseinfo/?limit=100&offset=0');
    var pages = 0;
    while (next != null && pages < maxPages) {
      final json = await getJson(client, next, timeout: const Duration(seconds: 40));
      for (final e in (json['results'] as List? ?? const [])) {
        final item = parse(e as Map<String, dynamic>);
        if (item != null) out.add(item);
      }
      final n = json['next'] as String?;
      next = n == null ? null : Uri.parse(n);
      pages++;
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
