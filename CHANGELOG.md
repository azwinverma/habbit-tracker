# Changelog

## [Unreleased] — Phase 0 stabilization (2026-11-24)

### Fixed
- Deleted habits, removed reminder times and disabled habits no longer keep notifying (alarms are now cancelled).
- One-time reminders and "session finished" alarms no longer repeat every day forever.
- Medicine courses with start/end dates no longer pile up duplicate notifications or continue after the end date.
- No more duplicate "Habit Reminder" notifications for medicine/water/meditation/reading/exercise habits.
- Crash when saving a generic habit with a single reminder time (alarm id overflow).
- Crash / silently missing reminders on Android 12+ when exact-alarm permission is not granted; reminders now fall back to inexact delivery and the app explains how to enable on-time reminders.
- Reminders are restored after reboot, app update, and clock or timezone changes.
- Stopping or pausing a meditation/reading/workout session cancels its "finished" notification.
- Exercise "today's minutes" now resets each day.

### Changed
- All reminders go through one engine (`ReminderService` + native `AlarmScheduler`); alarm ids are stable across app versions.
- One-time reminders are saved with the habit.
- No interstitial ads around medication (Medicine tile, saving medicine), during/after meditation, or from inside the reader.
- `AlarmReceiver` is no longer exported to other apps.
- `http` and `webview_flutter` declared as direct dependencies (same versions); rename tools moved to dev dependencies.

### Added
- 37 unit tests; docs: `docs/PHASE0_AUDIT.md`, `docs/NOTIFICATION_ARCHITECTURE.md`, `docs/MIGRATION_PLAN.md`, `docs/IMPLEMENTATION_PLAN.md`.

### Known limitations
- One-time reminders created in v1.0.0 were never stored and are dropped during the upgrade.
- iOS reminders are not implemented yet (unchanged from v1.0.0).
- Office walk/stretch intervals are still not scheduled (Phase 3).
