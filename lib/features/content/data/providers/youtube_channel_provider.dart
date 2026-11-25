import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/content_item.dart';
import 'content_provider.dart';

/// Newest free workout videos from YouTube channels, via each channel's
/// public RSS feed (no API key; the latest 15 uploads). Starts with
/// Bodybuilding.com (youtube.com/@bodybuildingcom).
///
/// Videos are not downloaded: they play in the app with YouTube's official
/// embedded player (see `YoutubeInlinePlayer`), as YouTube's terms allow.
/// Each new video is checked with oEmbed so only videos that exist and
/// allow embedding are listed. Promos, news and podcasts are skipped.
class YoutubeChannelProvider implements ContentProvider {
  YoutubeChannelProvider({this.channels = defaultChannels});

  final List<YoutubeChannel> channels;

  static const defaultChannels = [
    YoutubeChannel('UC97k3hlbE-1rVN8y56zyEEA', 'Bodybuilding.com'),
  ];

  @override
  String get id => 'youtube';
  @override
  String get displayName => 'YouTube (Bodybuilding.com)';
  @override
  String get homepage => 'https://www.youtube.com/@bodybuildingcom';
  @override
  ContentKind get kind => ContentKind.video;
  @override
  Duration get refreshEvery => const Duration(hours: 6);

  @override
  Future<List<ContentItem>> fetch(http.Client client, {required DateTime now}) async {
    final out = <ContentItem>[];
    for (final ch in channels) {
      final r = await client
          .get(Uri.parse('https://www.youtube.com/feeds/videos.xml?channel_id=${ch.id}'),
              headers: const {'User-Agent': contentUserAgent})
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) throw http.ClientException('HTTP ${r.statusCode}', r.request?.url);
      for (final e in parseFeed(r.body, ch)) {
        if (await _embeddable(client, e.mediaUrl!)) out.add(e);
      }
    }
    return out;
  }

  Future<bool> _embeddable(http.Client client, String watchUrl) async {
    try {
      final r = await client
          .get(Uri.parse('https://www.youtube.com/oembed?format=json&url=${Uri.encodeComponent(watchUrl)}'))
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return true; // can't tell: list it; the player offers "Open in YouTube" if needed
    }
  }

  static final _promo = RegExp(
      r'news|podcast|giveaway|announce|edge ×|×|sale\b|discount|supplement|protein|pre-?workout|recipe|unboxing|future of|why are|popular\?|q&a|interview|trailer',
      caseSensitive: false);
  static final _fitness = RegExp(
      r'how to|exercise|workout|form|press|row|squat|curl|raise|lunge|deadlift|pull|push|plank|abs?\b|core|leg|arm|chest|back|shoulder|glute|calf|stretch|cardio|hiit|fly|dip|crunch|machine',
      caseSensitive: false);

  /// Parses a channel RSS feed. Public for tests.
  @visibleForTesting
  static List<ContentItem> parseFeed(String xml, YoutubeChannel ch) {
    final items = <ContentItem>[];
    for (final m in RegExp(r'<entry>([\s\S]*?)</entry>').allMatches(xml)) {
      final e = m.group(1)!;
      String? tag(String name) => RegExp('<$name[^>]*>([\\s\\S]*?)</$name>').firstMatch(e)?.group(1)?.trim();
      final vid = tag('yt:videoId');
      final title = _unescape(tag('title') ?? '');
      if (vid == null || title.isEmpty) continue;
      if (_promo.hasMatch(title) || !_fitness.hasMatch(title)) continue;
      final views = int.tryParse(RegExp(r'<media:statistics views="(\d+)"').firstMatch(e)?.group(1) ?? '') ?? 0;
      final desc = _unescape(tag('media:description') ?? '');
      final shortDesc = desc.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty && !l.startsWith('http')).take(3).join('\n');
      items.add(ContentItem(
        id: 'yt:$vid',
        provider: 'youtube',
        kind: ContentKind.video,
        title: title,
        subtitle: ch.name,
        description: shortDesc.isEmpty ? null : shortDesc,
        mediaUrl: 'https://www.youtube.com/watch?v=$vid',
        mediaFormat: 'youtube',
        imageUrl: 'https://i.ytimg.com/vi/$vid/hqdefault.jpg',
        sourceUrl: 'https://www.youtube.com/watch?v=$vid',
        license: 'YouTube (embedded player)',
        licenseUrl: 'https://www.youtube.com/t/terms',
        attribution: '${ch.name} on YouTube',
        tags: [ch.name, groupFor(title)],
        language: 'en',
        popularity: views,
      ));
    }
    return items;
  }

  /// Rough body-part group from a title (for filters and the Home hub).
  static String groupFor(String title) {
    final t = title.toLowerCase();
    if (RegExp(r'\babs?\b|core|crunch|plank|sit.?up').hasMatch(t)) return 'Abdomen';
    if (RegExp(r'leg|squat|lunge|calf|glute|hamstring|quad|deadlift').hasMatch(t)) return 'Legs';
    if (RegExp(r'chest|bench|push.?up|fly|pec|dip').hasMatch(t)) return 'Chest';
    if (RegExp(r'back|row|pulldown|pull.?up|lat\b').hasMatch(t)) return 'Back';
    if (RegExp(r'shoulder|delt|lateral raise|overhead press').hasMatch(t)) return 'Shoulders';
    if (RegExp(r'curl|tricep|bicep|arm').hasMatch(t)) return 'Arms';
    if (RegExp(r'cardio|hiit|run').hasMatch(t)) return 'Cardio';
    return 'Full body';
  }

  static String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

class YoutubeChannel {
  const YoutubeChannel(this.id, this.name);
  final String id;
  final String name;
}
