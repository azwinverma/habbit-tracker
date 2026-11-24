import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/content_item.dart';

/// A source of free / openly licensed content.
abstract class ContentProvider {
  /// Stable id, also used as the `provider` column and id prefix.
  String get id;

  /// Human-readable name shown in "Sources & licences".
  String get displayName;
  String get homepage;
  ContentKind get kind;

  /// Minimum time between successful refreshes (politeness + data usage).
  Duration get refreshEvery;

  Future<List<ContentItem>> fetch(http.Client client, {required DateTime now});
}

/// Generic, non-identifying client name for API requests. Wikimedia asks
/// apps to identify themselves; the owner can append a contact URL here.
const contentUserAgent = 'DailyMantra/2.0 (Flutter habit & wellness app)';

Future<Map<String, dynamic>> getJson(http.Client client, Uri uri,
    {Duration timeout = const Duration(seconds: 25)}) async {
  final resp = await client
      .get(uri, headers: {'User-Agent': contentUserAgent, 'Accept': 'application/json'})
      .timeout(timeout);
  if (resp.statusCode != 200) {
    throw http.ClientException('HTTP ${resp.statusCode}', uri);
  }
  final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('Unexpected JSON from $uri');
  }
  return decoded;
}
