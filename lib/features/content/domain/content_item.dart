/// Kinds of dynamic content the app can show.
enum ContentKind { book, audio, exercise }

/// A content item as returned by a provider (before it is cached).
class ContentItem {
  final String id; // "<provider>:<externalId>"
  final String provider;
  final ContentKind kind;
  final String title;
  final String? subtitle;
  final String? description;
  final String? mediaUrl;
  final String mediaFormat; // epub | html | mp3 | none
  final String? imageUrl;
  final String? sourceUrl;
  final String license;
  final String? licenseUrl;
  final String? attribution;
  final List<String> tags;
  final String? language;
  final int? durationSeconds;
  final int popularity;

  const ContentItem({
    required this.id,
    required this.provider,
    required this.kind,
    required this.title,
    required this.license,
    this.subtitle,
    this.description,
    this.mediaUrl,
    this.mediaFormat = 'none',
    this.imageUrl,
    this.sourceUrl,
    this.licenseUrl,
    this.attribution,
    this.tags = const [],
    this.language,
    this.durationSeconds,
    this.popularity = 0,
  });
}

/// Only content whose licence allows free reuse *including commercial use*
/// (the app shows ads) is accepted: public domain, CC0, CC BY, CC BY-SA.
/// NonCommercial (NC) and NoDerivatives (ND) licences are rejected.
abstract final class LicensePolicy {
  static bool isAllowed(String license) {
    final l = license.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    if (l.contains(' nc') || l.contains('noncommercial') || l.contains(' nd') || l.contains('noderiv')) {
      return false;
    }
    return l.contains('public domain') ||
        l.startsWith('pd') ||
        l.contains('cc0') ||
        RegExp(r'\bcc by( sa)?\b').hasMatch(l);
  }
}

/// Minimal HTML → plain text for provider descriptions.
String stripHtml(String? html) {
  if (html == null) return '';
  var s = html
      .replaceAll(RegExp(r'<\s*(br|/p|/li|/h\d)\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  const entities = {
    '&amp;': '&', '&lt;': '<', '&gt;': '>', '&quot;': '"', '&#39;': "'", '&nbsp;': ' ', '&#039;': "'",
  };
  entities.forEach((k, v) => s = s.replaceAll(k, v));
  return s.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n\s*\n+'), '\n').trim();
}
