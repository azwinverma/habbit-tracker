# Phase 0 — Repository Audit & Stabilization

**Date:** 2026-11-24 · **Baseline version:** 1.0.0+1 · **Toolchain:** Flutter 3.29.3 / Dart 3.7.2

## 1. Baseline (before any change)

| Check | Result |
|---|---|
| `flutter pub get` | OK (70 packages have newer, constraint-incompatible versions) |
| `flutter analyze` | **1 error**, 7 warnings, 26 infos |
| `flutter test` | **Fails to compile** — template test refers to non-existent `MyApp` |
| Version control | **None** — the project is not a git repository |
| Android device/emulator | None available in this environment |

## 2. Working functionality (preserved)

Splash → Home (Quick Add grid + habit list) · Medicine (name/dose/notes/dates/multiple times) · Water (target, counter, times) · Meditation (timer, streamed audio from own API, daily + one-time reminders) · Reading (timer, remote ebook list, EPUB reader, web reader) · Exercise (timer, minutes goal, manual steps, weekly plan, milestones) · Generic habits · Quotes · AdMob banner + interstitial with frequency cap · SharedPreferences persistence (`habits_v1`).

## 3. Defects found

Severity: **S1** = loses/duplicates critical reminders or crashes · **S2** = wrong behaviour · **S3** = hygiene.

| # | Sev | Defect | Status |
|---|---|---|---|
| D1 | S1 | Deleting a habit never cancelled its alarms. Native daily alarms re-arm themselves, so deleted habits kept notifying **forever**. Editing/removing a time also left the old alarm armed. No cancel call existed anywhere in active code. | **Fixed** |
| D2 | S1 | Legacy Dart alarm callback re-armed **every** alarm for "now + 1 day" — including one-time reminders, session-end alarms and dated medicine doses. One-time reminders became daily ones; each "Reading/Workout session done" alarm repeated daily forever. | **Fixed** |
| D3 | S1 | Medicine with a date range scheduled one alarm per dose per day (≤120 days); combined with D2 each re-armed daily → day *k* produced up to *k* duplicate notifications and they continued past the end date. Also risked Android's ~500-alarms-per-app limit. | **Fixed** (1 bounded daily alarm per dose time) |
| D4 | S1 | Home re-scheduled a generic "Habit Reminder" for **every** habit at every launch, in addition to the category screen's own alarms → duplicate notifications for medicine/water/meditation/etc. | **Fixed** |
| D5 | S1 | Generic habits without extra times sent a >32-bit id (`int.tryParse` of a 16–19 digit id) to Kotlin, which read it as `Int` → `ClassCastException` crash. | **Fixed** (stable 31-bit ids; Kotlin reads `Number`) |
| D6 | S1 | Android 12+: when the exact-alarm permission is not granted (default for new installs on Android 14+), native `setExactAndAllowWhileIdle` throws `SecurityException` (crash), and the plugin path silently scheduled **nothing**. | **Fixed** (inexact fallback + one-time explained prompt) |
| D7 | S1 | No reboot recovery for native alarms (water, meditation, generic). | **Fixed** (`BootReceiver` + persisted alarm store; also on update/time/timezone change) |
| D8 | S2 | Alarm ids derived from `String.hashCode`, which Dart does not guarantee stable across SDK versions → future builds could not cancel existing alarms. | **Fixed** (FNV-1a, pinned by tests) |
| D9 | S2 | Stopping a meditation/reading/workout session early did not cancel the "session finished" alarm. | **Fixed** |
| D10 | S2 | One-time reminders were not persisted (fire-and-forget), so they could not be cancelled or restored. | **Fixed** (`Habit.oneTimeReminders`) |
| D11 | S2 | Exercise "today's minutes" never reset at midnight. | **Fixed** |
| D12 | S2 | Interstitial ads shown after saving medicine, on tapping the Medicine tile, when stopping/leaving meditation (incl. from `dispose`), and from inside the reader ("End now"). Violates the product rule: no ads around medication, meditation or reading. | **Fixed** (those placements removed; others kept for Phase 7) |
| D13 | S2 | `AlarmReceiver` was `exported="true"` → any installed app could make DailyMantra post arbitrary notifications. | **Fixed** |
| D14 | S2 | `http` and `webview_flutter` imported but only transitive dependencies. | **Fixed** (declared at locked versions — no upgrades) |
| D15 | S3 | Broken template widget test. | **Fixed** (replaced by 37 real tests) |
| D16 | S3 | Root `.gitignore` did not exclude `daily-mantra.jks` / `key.properties`. | **Fixed** |
| D17 | S3 | Rename CLI tools in runtime `dependencies`. | **Fixed** (moved to dev) |
| D18 | S2 | Office "walk every / stretch every" intervals are saved but **never scheduled** — the feature does nothing. | ✅ Fixed (Phase 3): scheduled as daily reminders in office hours |
| D19 | S2 | Splash references `assets/branding/*.png` that don't exist; no assets declared. New logo not in repo. | Open → blocked on logo (Phase 2) |
| D20 | S2 | iOS: no reminder implementation at all (all paths are Android-only). | Open → Phase 3 |
| D21 | S2 | API base URL hard-coded in two screens; no environment config. | Open → Phase 1 |
| D22 | S3 | Thousands of lines of commented-out code (meditation ~5.6k, reading ~3.4k lines). | Open → Phase 1 (remove during feature extraction) |
| D23 | S3 | Notification small icon uses the coloured launcher icon (renders as a white square on many devices). | Open → Phase 2 |
| D24 | S3 | Duplicated UI/logic across screens (reminder editor, timer, `_BigActionButton`). | Open → Phase 1/2 |
| D25 | S3 | `lib/screens/code1.txt` is an unrelated Python project config. | Open (safe to delete) |
| D26 | S3 | 24 analyzer infos (deprecated `withOpacity`/`surfaceVariant`, async `BuildContext`). | Open → Phase 2 |

## 4. After Phase 0

| Check | Result |
|---|---|
| `flutter analyze` | **0 errors**, 1 warning (pre-existing unused `_pickTime`), 24 infos (pre-existing deprecations) |
| `flutter test` | **37 / 37 passed** |
| `flutter build apk --debug` | **Builds** (Kotlin + manifest compile) |
| On-device verification | **Not run** — no device available. See checklist in `NOTIFICATION_ARCHITECTURE.md` §6. |
| Dependency versions | Unchanged (lockfile diff verified) |
| Rollback snapshot | `.phase0_backup/pre-phase0-2026-11-24.tar.gz` |
