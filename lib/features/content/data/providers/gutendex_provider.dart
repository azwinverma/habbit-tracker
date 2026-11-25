import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/content_item.dart';
import 'content_provider.dart';

/// Public-domain ebooks from Project Gutenberg, discovered via the Gutendex
/// metadata API (https://gutendex.com). Only books Gutenberg marks as not
/// under copyright (`copyright: false`, i.e. public domain in the US) and
/// that have an EPUB are kept. EPUB files are downloaded from gutenberg.org
/// only when the user opens a book.
///
/// Freshness: each refresh fetches the two most-popular pages plus one
/// rotating page, so the catalogue grows with new titles over time. (Filtered Gutendex
/// queries are uncached server-side and often time out, so filtering is done
/// here.)
class GutendexProvider implements ContentProvider {
  GutendexProvider({this.baseUrl = 'https://gutendex.com'});

  final String baseUrl;

  @override
  String get id => 'gutenberg';
  @override
  String get displayName => 'Project Gutenberg (via Gutendex)';
  @override
  String get homepage => 'https://www.gutenberg.org';
  @override
  ContentKind get kind => ContentKind.book;
  @override
  Duration get refreshEvery => const Duration(hours: 1);

  static const rotatingPages = 30;

  @visibleForTesting
  static List<int> pagesFor(DateTime now) {
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return [1, 2, 3 + (dayOfYear % rotatingPages)];
  }

  @override
  Future<List<ContentItem>> fetch(http.Client client, {required DateTime now}) async {
    final out = <String, ContentItem>{};
    Object? lastError;
    var ok = 0;
    for (final page in pagesFor(now)) {
      try {
        // Unfiltered listing pages are cached server-side (fast); filtered
        // ones are not and often time out. Language is filtered in parse().
        final json = await getJson(client, Uri.parse('$baseUrl/books/?page=$page'));
        for (final b in (json['results'] as List? ?? const [])) {
          final item = parse(b as Map<String, dynamic>);
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
  static ContentItem? parse(Map<String, dynamic> b) {
    if (b['copyright'] != false) return null; // only confirmed public domain
    final langs = (b['languages'] as List? ?? const []).map((l) => l.toString()).toList();
    if (!langs.contains('en')) return null; // English for now (Nepali in Phase 3)
    final formats = (b['formats'] as Map?)?.cast<String, dynamic>() ?? const {};
    final epub = formats['application/epub+zip'] as String?;
    if (epub == null) return null;
    final gid = b['id'];
    final authors = (b['authors'] as List? ?? const [])
        .map((a) => _displayName((a as Map)['name'] as String? ?? ''))
        .where((n) => n.isNotEmpty)
        .toList();
    final shelves = (b['bookshelves'] as List? ?? const [])
        .map((s) => s.toString())
        .where((s) => s.startsWith('Category: '))
        .map((s) => s.substring('Category: '.length))
        .toList();
    final summaries = (b['summaries'] as List?)?.cast<dynamic>() ?? const [];
    return ContentItem(
      id: 'gutenberg:$gid',
      provider: 'gutenberg',
      kind: ContentKind.book,
      title: (b['title'] as String? ?? 'Untitled').trim(),
      subtitle: authors.isEmpty ? null : authors.join(', '),
      description: summaries.isNotEmpty ? summaries.first.toString() : null,
      mediaUrl: epub,
      mediaFormat: 'epub',
      imageUrl: formats['image/jpeg'] as String?,
      sourceUrl: 'https://www.gutenberg.org/ebooks/$gid',
      license: 'Public domain (US)',
      licenseUrl: 'https://www.gutenberg.org/policy/license.html',
      attribution: 'Project Gutenberg',
      tags: shelves.take(4).toList(),
      language: (b['languages'] as List?)?.firstOrNull?.toString(),
      popularity: (b['download_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// "Austen, Jane" -> "Jane Austen"
  static String _displayName(String raw) {
    final parts = raw.split(', ');
    if (parts.length == 2) return '${parts[1]} ${parts[0]}'.trim();
    return raw.trim();
  }
}
