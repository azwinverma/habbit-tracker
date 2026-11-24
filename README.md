# DailyMantra – Habit & Wellness Reminder App (Flutter)

**Small habits. Better days.** DailyMantra is a Flutter mobile app (mainly for Android) that helps users build daily habits. It does this with category-specific trackers and reliable reminders. Users can track medicine, water intake, meditation (with streamed audio), reading (with a built-in ebook reader), exercise, and generic custom habits.

- **Package / applicationId:** `com.daily.mantra`
- **Dart package name:** `habit_tracker_nepali`
- **Version:** 1.0.0+1 (2.0 work in progress: Phase 0 ✅, Phase 1 core ✅; see [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md))
- **Min Android:** 7.0 (API 24)
- **Dart SDK:** ^3.7.2, Material 3, seed color `#2563EB`
- **Orientation:** portrait only
- **Platforms:** Android is the main target. iOS folders exist, but alarms and ads are mostly Android-specific.

---

## 1. Features

### App flow
1. **Splash screen.** An animated gradient with fade and scale. It initializes notifications, asks for notification permission, loads saved habits and preloads an interstitial ad, then fades to Home.
2. **Home screen.**
   - A **Quick Add** grid with 6 category tiles: Medicine, Water Intake, Meditation, Reading, Exercise, Others.
   - A **Your Habits** list of the user's habits. Each habit has an Edit/Delete popup menu, and tapping it opens that category's screen.
   - An empty state with an "Add Habit" button.

### Category screens
| Category | Capabilities |
|---|---|
| **Medicine** | Medicine name, dose, notes, start and end dates, several dose times per day. Reminders are scheduled day by day between the start and end dates, limited to 120 days ahead so the app doesn't create too many alarms. |
| **Water Intake** | A daily target in glasses, a counter for today (resets each day), and several daily reminder times. |
| **Meditation** | A session timer with an adjustable length. An audio player (`just_audio`) streams tracks listed by a remote API. A "Choose Sound" picker. A daily minutes goal. Daily repeating reminders and one-time date/time reminders. |
| **Reading** | A session timer. A remote ebook library. A built-in **EPUB reader** (`epub_view`) with table of contents and Prev/Next; non-EPUB books open in a web reader page. Daily and one-time reminders. |
| **Exercise** | A workout session timer and a daily minutes goal. **Manual** step counting with +50, +100 and +500 buttons, a reset button and a goal (default 6000). **Office worker helpers** send "walk every N min" and "stretch every N min" reminders. **Milestones.** A **weekly gym plan** (exercises per weekday with body part and level). Daily and one-time reminders. |
| **Others (generic)** | A name, one reminder time and an enable toggle. |

### Cross-cutting features
- Streak and `lastCompleted` tracking on each habit.
- Daily progress resets by comparing a stored `YYYY-MM-DD` date with today.
- Motivational quotes (`QuoteService`, a hard-coded list).
- AdMob banner and interstitial ads. Interstitials are limited to **at least 45 seconds apart** and **at most 6 per session**.

---

## 2. Tech Stack

Flutter 3.29 / Dart 3.7 · **Riverpod 2.6** (state) · **GoRouter 17** (navigation) · **Drift 2.28 / SQLite** (local database) · Firebase Core (project `habbittracker-c2daa`, initialised only) · `flutter_local_notifications` + native Kotlin AlarmManager (reminders) · `just_audio` · `epub_view` · `cached_network_image` · `google_mobile_ads` · `http`.

## 3. Project Structure & Data

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). In short:
- `lib/app/` holds the app shell, router, theme and providers. `lib/features/` holds habits (repository, migration, flows), content, plan, insights and profile. `lib/core/` holds the database schema and the reminder engine. `lib/screens/` holds the legacy category screens.
- **Storage:** SQLite (`dailymantra.sqlite`) with `habits`, a settings table per category, `habit_logs` (per-day history), `content_items` and `content_sync_states`. v1.0.0 data (`habits_v1`) is migrated automatically on first launch and still mirrored for rollback ([docs/MIGRATION_PLAN.md](docs/MIGRATION_PLAN.md)).

## 4. Free Content

There is no licensed content of our own. The app pulls **free, reusable** content and refreshes it when the user opens the app:
- public-domain books from Project Gutenberg (via Gutendex)
- nature and mindfulness sounds from Wikimedia Commons (PD/CC0/CC BY/CC BY-SA)
- an exercise library from wger (CC BY-SA)

Content is cached offline, new items get a **New** badge, and authors and licences are shown everywhere. Details and obligations are in [docs/CONTENT_SOURCES.md](docs/CONTENT_SOURCES.md).

---

## 5. Reminder Architecture

Since Phase 0, all reminders go through **one engine** (details in [docs/NOTIFICATION_ARCHITECTURE.md](docs/NOTIFICATION_ARCHITECTURE.md)):

- Screens save habit data, then call `ReminderService.syncHabit(habit)` ([lib/core/reminders/](lib/core/reminders/)).
- `HabitReminderPlanner` (a pure, unit-tested function) turns a habit into alarm specs. Alarm ids are stable FNV-1a hashes of keys like `"<habitId>|daily|08:00"`.
- A registry (`reminder_registry_v1`) records which alarm ids belong to each habit, so edits, disabling and deletion cancel exactly the right alarms.
- On Android, the native `AlarmScheduler` arms exact alarms, falling back to inexact ones if exact-alarm permission is denied. It keeps a persistent store. `AlarmReceiver` re-arms daily reminders (respecting a medicine end date), and `BootReceiver` restores alarms after a reboot, app update, or clock or timezone change.
- On every launch, `ReminderService.startup()` re-arms all reminders from data. On the first launch after upgrading, it also retires alarms left by v1.0.0.

Android permissions: `INTERNET`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`. iOS reminders are not implemented yet.

---

## 6. Navigation (Phase 1)

**Today** (greeting, progress, quick add, habits) · **Plan** (upcoming reminders, reminder health, test reminder) · **Add** (sheet) · **Insights** (7-day history) · **You** (theme, permissions, content sources and licences, privacy). **Discover** (free books, sounds and exercises) opens from Today and from Add. Tapping a habit opens its own screen.

The old PythonAnywhere content API has been removed: it was offline and its content was unlicensed.

---

## 7. Known Issues / Technical Debt

Phase 0 fixed the critical reminder bugs (orphaned and duplicate alarms, never-ending one-time reminders, missing reboot recovery, exact-alarm crashes), the broken test and the dependency problems. The full defect list and status is in [docs/PHASE0_AUDIT.md](docs/PHASE0_AUDIT.md). Still open:

1. Office walk/stretch intervals are saved but never scheduled.
2. iOS has no reminder implementation.
3. The splash screen refers to missing logo assets, and the new logo isn't in the repo yet.
4. The category screens still use the legacy `Habit` view model and are large. They will be split into typed models and widgets in Phase 2/3.
5. There are no widget or integration tests for the new screens yet, and no CI.
6. The release build prints non-fatal Kotlin metadata warnings: bump the Kotlin Gradle plugin to 2.2.

---

## 8. Enhancement Ideas (where I'd like help)

- **Architecture:** add a state management solution (Riverpod, Bloc or Provider), split the screens into widgets, controllers and services, and put repeated UI (reminder editor, session timer, action buttons) into shared widgets.
- **Reminders:** combine the three systems into one reliable approach, add rescheduling after reboot, and make alarm ID creation and cancellation consistent.
- **Persistence:** move to a local database (Hive, Isar, Drift or sqflite) with history per day, so the app can show streaks, calendars and charts. Model each category as its own type.
- **Real step counting:** connect `pedometer`, Health Connect or HealthKit.
- **Statistics:** weekly and monthly charts, a streak calendar, completion rates.
- **Localization:** add Nepali (ne) alongside English, plus Nepali calendar (Bikram Sambat) dates.
- **Dark mode and theming,** onboarding, and home screen widgets.
- **Backup and sync:** optional cloud backup or account sign-in.
- **Media:** offline caching for audio and ebooks, background audio playback with lock-screen controls.
- **Quality:** unit and widget tests, CI, lint cleanup, removal of dead code.
- **Monetization:** better ad placement and frequency, and an optional ad-free in-app purchase.
- **iOS support:** equal reminder reliability and ad configuration.

---

## 9. Running the App

```bash
flutter pub get
flutter test           # 74 unit + widget tests (+3 live API tests: LIVE=1 flutter test test/content/live_providers_test.dart)
flutter run            # Android device/emulator recommended
flutter build apk --release   # needs android/key.properties + keystore
dart run build_runner build --delete-conflicting-outputs   # after changing lib/core/db/tables.dart
```
