// Hits the real provider APIs. Skipped unless LIVE=1:
//   LIVE=1 flutter test test/content/live_providers_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/content_provider.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/gutendex_provider.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/wger_provider.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/wikimedia_audio_provider.dart';
import 'package:habit_tracker_nepali/features/content/domain/content_item.dart';
import 'package:http/http.dart' as http;

void main() {
  final live = Platform.environment['LIVE'] == '1';
  final client = http.Client();

  Future<void> check(ContentProvider p, {int min = 5}) async {
    final items = await p.fetch(client, now: DateTime.now());
    // ignore: avoid_print
    print('${p.id}: ${items.length} items, e.g. ${items.take(3).map((i) => '"${i.title}" [${i.license}]').join(', ')}');
    expect(items.length, greaterThanOrEqualTo(min));
    for (final i in items) {
      expect(LicensePolicy.isAllowed(i.license), isTrue, reason: '${i.id} ${i.license}');
      if (i.kind != ContentKind.exercise) expect(i.mediaUrl, startsWith('https://'));
    }
  }

  test('Gutendex', () => check(GutendexProvider(), min: 20), skip: !live, timeout: const Timeout(Duration(minutes: 2)));
  test('Wikimedia Commons audio', () => check(WikimediaAudioProvider(), min: 15), skip: !live, timeout: const Timeout(Duration(minutes: 3)));
  test('wger (2 pages)', () => check(WgerProvider(maxPages: 2), min: 50), skip: !live, timeout: const Timeout(Duration(minutes: 3)));
}
