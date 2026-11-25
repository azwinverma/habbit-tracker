import 'dart:async';
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

/// GET + JSON decode with polite retries: HTTP 429 / 5xx and timeouts are
/// retried up to [retries] times with exponential back-off (honouring a
/// numeric Retry-After header when the server sends one).
Future<Map<String, dynamic>> getJson(http.Client client, Uri uri,
    {Duration timeout = const Duration(seconds: 25), int retries = 2,
    Duration baseDelay = const Duration(seconds: 2)}) async {
  for (var attempt = 0;; attempt++) {
    http.Response resp;
    try {
      resp = await client
          .get(uri, headers: {'User-Agent': contentUserAgent, 'Accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      if (attempt >= retries) rethrow;
      await Future<void>.delayed(baseDelay * (1 << attempt));
      continue;
    }
    final retryable = resp.statusCode == 429 || resp.statusCode >= 500;
    if (retryable && attempt < retries) {
      final after = int.tryParse(resp.headers['retry-after'] ?? '');
      final wait = after != null && after <= 30 ? Duration(seconds: after) : baseDelay * (1 << attempt);
      await Future<void>.delayed(wait);
      continue;
    }
    if (resp.statusCode != 200) {
      throw http.ClientException('HTTP ${resp.statusCode}', uri);
    }
    final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Unexpected JSON from $uri');
    }
    return decoded;
  }
}

/// "1:02:03" / "27:50" / "45" -> seconds.
int? parseClock(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  final parts = s.trim().split(':').map(int.tryParse).toList();
  if (parts.any((p) => p == null)) return double.tryParse(s)?.round();
  return parts.fold<int>(0, (acc, p) => acc * 60 + p!);
}
