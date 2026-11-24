import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/content_item.dart';
import 'content_provider.dart';

/// Freely licensed ambient / nature / mindfulness sounds from Wikimedia
/// Commons. Every Commons file carries a free licence; we additionally keep
/// only licences that allow commercial reuse (PD, CC0, CC BY, CC BY-SA) and
/// show the author + licence wherever the sound is used (attribution is a
/// licence requirement for CC BY / BY-SA).
///
/// Playback uses Commons' MP3 transcode so it works on Android and iOS.
class WikimediaAudioProvider implements ContentProvider {
  WikimediaAudioProvider({this.apiUrl = 'https://commons.wikimedia.org/w/api.php'});

  final String apiUrl;

  @override
  String get id => 'commons';
  @override
  String get displayName => 'Wikimedia Commons';
  @override
  String get homepage => 'https://commons.wikimedia.org';
  @override
  ContentKind get kind => ContentKind.audio;
  @override
  Duration get refreshEvery => const Duration(hours: 24);

  /// Collection label -> Commons search.
  static const collections = <String, String>{
    'Rain': 'filetype:audio rain',
    'Ocean': 'filetype:audio ocean waves',
    'Forest & birds': 'filetype:audio forest birds',
    'Flowing water': 'filetype:audio stream water',
    'Wind': 'filetype:audio wind',
    'Thunderstorm': 'filetype:audio thunderstorm',
    'Singing bowl': 'filetype:audio singing bowl',
    'Bells': 'filetype:audio bell',
    'Night': 'filetype:audio crickets night',
    'Fire': 'filetype:audio campfire',
  };

  static const minSeconds = 30;
  static const maxSeconds = 3 * 60 * 60;

  @override
  Future<List<ContentItem>> fetch(http.Client client, {required DateTime now}) async {
    final out = <String, ContentItem>{};
    Object? lastError;
    var ok = 0;
    for (final entry in collections.entries) {
      try {
        final uri = Uri.parse(apiUrl).replace(queryParameters: {
          'action': 'query',
          'format': 'json',
          'formatversion': '2',
          'generator': 'search',
          'gsrsearch': entry.value,
          'gsrnamespace': '6',
          'gsrlimit': '15',
          'prop': 'imageinfo|videoinfo',
          'iiprop': 'url|size|mime|extmetadata',
          'iiextmetadatafilter': 'LicenseShortName|LicenseUrl|Artist|ImageDescription',
          'viprop': 'derivatives',
        });
        final json = await getJson(client, uri);
        final pages = ((json['query'] as Map?)?['pages'] as List?) ?? const [];
        for (final p in pages) {
          final item = parse(p as Map<String, dynamic>, entry.key);
          if (item == null) continue;
          final existing = out[item.id];
          out[item.id] = existing == null
              ? item
              : _withTags(existing, {...existing.tags, entry.key}.toList());
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
  static ContentItem? parse(Map<String, dynamic> page, String collection) {
    final infos = page['imageinfo'] as List?;
    if (infos == null || infos.isEmpty) return null;
    final ii = infos.first as Map<String, dynamic>;
    final duration = (ii['duration'] as num?)?.round();
    if (duration == null || duration < minSeconds || duration > maxSeconds) return null;

    final meta = (ii['extmetadata'] as Map?)?.cast<String, dynamic>() ?? const {};
    String? metaValue(String k) => (meta[k] as Map?)?['value']?.toString();
    final license = metaValue('LicenseShortName') ?? '';
    if (!LicensePolicy.isAllowed(license)) return null;

    String? mp3;
    final vinfo = page['videoinfo'] as List?;
    if (vinfo != null && vinfo.isNotEmpty) {
      for (final d in ((vinfo.first as Map)['derivatives'] as List? ?? const [])) {
        if ((d as Map)['type'] == 'audio/mpeg') {
          mp3 = d['src'] as String?;
          break;
        }
      }
    }
    if (mp3 == null && ii['mime'] == 'audio/mpeg') mp3 = ii['url'] as String?;
    if (mp3 == null) return null;

    final rawTitle = (page['title'] as String? ?? '').replaceFirst(RegExp(r'^File:'), '');
    final title = rawTitle.replaceFirst(RegExp(r'\.[A-Za-z0-9]{2,5}$'), '').replaceAll('_', ' ').trim();
    final artist = stripHtml(metaValue('Artist'));
    final desc = stripHtml(metaValue('ImageDescription'));

    return ContentItem(
      id: 'commons:${page['pageid']}',
      provider: 'commons',
      kind: ContentKind.audio,
      title: title.isEmpty ? collection : title,
      subtitle: collection,
      description: desc.isEmpty ? null : (desc.length > 300 ? '${desc.substring(0, 300)}…' : desc),
      mediaUrl: _clean(mp3),
      mediaFormat: 'mp3',
      sourceUrl: _clean(ii['descriptionurl'] as String?),
      license: license,
      licenseUrl: metaValue('LicenseUrl'),
      attribution: artist.isEmpty ? null : artist,
      tags: [collection],
      durationSeconds: duration,
    );
  }

  static String? _clean(String? url) {
    if (url == null) return null;
    final u = Uri.tryParse(url.startsWith('//') ? 'https:$url' : url);
    if (u == null) return url;
    final q = Map.of(u.queryParameters)..removeWhere((k, _) => k.startsWith('utm_'));
    return u.replace(queryParameters: q.isEmpty ? null : q).toString();
  }

  static ContentItem _withTags(ContentItem i, List<String> tags) => ContentItem(
        id: i.id, provider: i.provider, kind: i.kind, title: i.title, license: i.license,
        subtitle: i.subtitle, description: i.description, mediaUrl: i.mediaUrl,
        mediaFormat: i.mediaFormat, imageUrl: i.imageUrl, sourceUrl: i.sourceUrl,
        licenseUrl: i.licenseUrl, attribution: i.attribution, tags: tags,
        language: i.language, durationSeconds: i.durationSeconds, popularity: i.popularity,
      );
}
