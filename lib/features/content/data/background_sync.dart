import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../steps/step_service.dart';
import 'content_sync_service.dart';

/// Android background refresh of the content catalogue (WorkManager):
/// roughly every 12 hours, only with a network connection and when the
/// battery isn't low. The OS decides the exact time and may defer it
/// (Doze, battery saver). Foreground refresh on every app open is the
/// primary path; this keeps the catalogue fresh for people who open the app
/// rarely. iOS: not scheduled (BGTaskScheduler needs extra setup; the app
/// refreshes on open).
abstract final class BackgroundSync {
  static const taskName = 'dm.content.refresh';
  static const uniqueName = 'dm-content-refresh';
  static const every = Duration(hours: 12);

  /// Step sensor sampling (~every 15 min, WorkManager's minimum) so steps are
  /// put on the right day even when the app isn't opened. No network needed.
  static const stepsTask = 'dm.steps.sample';
  static const stepsUnique = 'dm-steps-sample';

  static Future<void> schedule() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        uniqueName,
        taskName,
        frequency: every,
        initialDelay: const Duration(hours: 1),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected, requiresBatteryNotLow: true),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 30),
      );
      await Workmanager().registerPeriodicTask(
        stepsUnique,
        stepsTask,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
    } catch (e) {
      debugPrint('[BackgroundSync] not scheduled: $e');
    }
  }
}

/// Runs in a background isolate started by WorkManager.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task == BackgroundSync.stepsTask) {
      // Only records the sensor reading; the app writes habits on next open.
      await StepService.instance.sync(writeHabits: false);
      return true;
    }
    if (task != BackgroundSync.taskName) return true;
    try {
      final results = await ContentSyncService.instance.syncIfStale();
      debugPrint('[BackgroundSync] ${results.join('; ')}');
      return true;
    } catch (e) {
      debugPrint('[BackgroundSync] failed: $e');
      return false; // WorkManager retries with back-off
    }
  });
}
