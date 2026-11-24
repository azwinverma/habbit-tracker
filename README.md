# DailyMantra – Habit & Wellness Reminder App (Flutter)

DailyMantra is a Flutter mobile app (mainly for Android) that helps users build daily habits. It does this with category-specific trackers and reliable reminders. Users can track medicine, water intake, meditation (with streamed audio), reading (with a built-in ebook reader), exercise, and generic custom habits.

- **Package / applicationId:** `com.daily.mantra`
- **Dart package name:** `habit_tracker_nepali`
- **Version:** 1.0.0+1
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

## 2. Tech Stack & Dependencies

| Purpose | Package |
|---|---|
| Local persistence | `shared_preferences` |
| Notifications | `flutter_local_notifications`, `timezone` |
| Background alarms | `android_alarm_manager_plus` (plus native Kotlin AlarmManager) |
| Audio | `just_audio`, `audio_session`, `just_audio_background` (installed, but its init is commented out) |
| Ebooks | `epub_view` |
| Images | `cached_network_image` |
| Ads | `google_mobile_ads` |
| Android intents | `android_intent_plus` |
| Steps | `pedometer` (**installed but not used yet**; steps are manual) |
| Tooling (wrongly placed in `dependencies`) | `package_rename`, `change_app_package_name` |

There is no state management library. Screens use `StatefulWidget` and `setState`.

---

## 3. Project Structure

```
lib/
├── main.dart                      # Init: orientation lock, MobileAds, AdService, notifications, AlarmManager → HabitApp → SplashScreen
├── models/
│   └── habit.dart                 # Habit model + HabitCategory enum, JSON (de)serialization
├── screens/
│   ├── splash_screen.dart
│   ├── home_screen.dart           # Quick Add grid + habit list
│   ├── add_edit_habit_screen.dart # Generic habit form
│   ├── medicine_screen.dart
│   ├── water_screen.dart
│   ├── meditation_screen.dart     # ~5.6k lines (much of it commented-out old code)
│   ├── reading_screen.dart        # ~3.4k lines (much of it commented-out old code); EPUB + web reader pages
│   ├── exercise_screen.dart       # ~2.4k lines; schedule editor bottom sheet
│   └── code1.txt                  # Stray file from an unrelated project – should be deleted
├── services/
│   ├── storage_service.dart       # Loads/saves List<Habit> as JSON under key 'habits_v1'
│   ├── notification_service.dart  # Local notifications, channel 'habit_channel_v2', exact scheduling, multi-time scheduling
│   ├── native_alarm.dart          # MethodChannel 'habit_alarms' → Kotlin AlarmScheduler
│   ├── ad_service.dart            # AdService + InterstitialHelper (frequency capping)
│   ├── quote_service.dart
│   └── track_library.dart         # Saved meditation tracks (shared_preferences key 'meditation_tracks')
├── widgets/
│   ├── habit_tile.dart
│   ├── grid_tile.dart
│   ├── ad_banner.dart             # Lifecycle-aware banner
│   └── extra_time_editior.dart    # Reusable "add multiple times" editor
└── utils/
    └── drive_link.dart            # Converts Google Drive share links to direct links

android/app/src/main/kotlin/com/daily/mantra/
├── MainActivity.kt                # Handles the 'habit_alarms' MethodChannel
├── AlarmScheduler.kt              # setExactAndAllowWhileIdle / cancel
└── AlarmReceiver.kt               # Shows a notification (channel 'habit_channel_native_v1'); re-arms daily alarms for the next day
```

---

## 4. Data Model

There is a single `Habit` class for every category, so category-specific fields are nullable:

```dart
enum HabitCategory { medicine, generic, water, meditation, reading, exercise }

class Habit {
  String id, name; bool enabled;
  int reminderHour, reminderMinute;        // legacy single time
  List<String> reminderTimes;              // multiple times, "HH:mm"
  HabitCategory category;
  int streak; DateTime? lastCompleted;

  // Water
  int? waterTarget, waterCompleted; String? waterLastDate;
  // Meditation
  int? meditationGoalMin, meditationTodayMin; String? meditationLastDate;
  // Medicine
  String? medicineName, medicineDose, medicineNotes, medicineStartDate, medicineEndDate;
  // Exercise
  int? exerciseGoalMin, exerciseTodayMin; String? exerciseLastDate;
  int? stepsGoal, stepsToday; String? stepsLastDate;
  int? officeWalkEveryMin, officeStretchEveryMin;
  String? exerciseScheduleJson, exerciseMilestonesJson;  // nested data stored as JSON strings
}
```

All habits are stored as one JSON list in `shared_preferences` under the key `habits_v1`. There is no database, user account or cloud sync.

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

## 6. Remote Content API

The meditation audio and ebooks come from a small self-hosted backend (Python, on PythonAnywhere):

- `GET {apiBase}/api/list/audio` returns a list of meditation tracks
- `GET {apiBase}/api/list/ebooks` returns a list of books (`.epub` or other URLs)

`apiBase` is hard-coded separately in `meditation_screen.dart` and `reading_screen.dart`.

---

## 7. Known Issues / Technical Debt

Phase 0 fixed the critical reminder bugs (orphaned and duplicate alarms, never-ending one-time reminders, missing reboot recovery, exact-alarm crashes), the broken test and the dependency problems. The full defect list and status is in [docs/PHASE0_AUDIT.md](docs/PHASE0_AUDIT.md). Still open:

1. Office walk/stretch intervals are saved but never scheduled.
2. iOS has no reminder implementation.
3. The splash screen refers to missing logo assets, and the new logo isn't in the repo yet.
4. The API base URL is hard-coded in two screens.
5. The large screen files contain thousands of lines of commented-out code and duplicated UI logic.
6. There is no state management layer, and one `Habit` class holds the fields for every category.
7. Storage is SharedPreferences JSON only, with no history tables.

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
flutter test           # 37 unit tests (model, alarm ids, planner, reminder service)
flutter run            # Android device/emulator recommended
flutter build apk --release   # needs android/key.properties + keystore
```
