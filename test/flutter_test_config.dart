import 'dart:async';

import 'package:habit_tracker_nepali/features/content/presentation/youtube_player.dart';
import 'package:habit_tracker_nepali/services/ad_service.dart';

/// Runs before every test file: no ads SDK / image cache plugins in tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AdService.enabled = false;
  YoutubeInlinePlayer.showThumbnails = false;
  await testMain();
}
