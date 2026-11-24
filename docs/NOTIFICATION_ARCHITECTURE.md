# Notification & Reminder Architecture

Status: **Phase 0 implementation (Android)**. iOS, actionable notifications, snooze, quiet hours and deep links are Phase 3.

## 1. Before (v1.0.0)

Three overlapping systems, each screen choosing its own:

| Screen | Scheduler | Id scheme |
|---|---|---|
| Home (all habits!) | Native Kotlin | `int.tryParse(id)` or `String.hashCode` |
| Water, Meditation | Native Kotlin | `String.hashCode` variants |
| Medicine, Reading, Exercise | android_alarm_manager_plus → Dart callback | `hashCode`, `hashCode ^ millis` |

No cancellation anywhere; the Dart callback re-armed every alarm daily. See `PHASE0_AUDIT.md` D1–D9.

## 2. After

```
 Screens / Home ──edit habit data──► StorageService (habits_v1)
        │
        └─► ReminderService.syncHabit(habit) / cancelHabit(id) / startup(habits)
                 │   registry: SharedPreferences `reminder_registry_v1` {habitId: [alarmIds]}
                 │
                 ├─► HabitReminderPlanner.plan(habit, now)  (pure, unit-tested)
                 │        → List<ReminderSpec{key, id=FNV(key), daily|once, firstAt, h:m, endAt}>
                 │
                 └─► AlarmBackend (NativeAlarmBackend → MethodChannel 'habit_alarms')
                           │
          Kotlin  AlarmScheduler ── store: SharedPreferences `dm_alarm_store`
                   │  exact if permitted, else inexact allow-while-idle (no crash)
                   ├─ AlarmReceiver: show → daily: re-arm next H:M (until endAt) / once: forget
                   │                  unknown id + migrated → drop silently (kills legacy zombies)
                   └─ BootReceiver: BOOT_COMPLETED, MY_PACKAGE_REPLACED, TIME_SET,
                                    TIMEZONE_CHANGED → rescheduleAll()
```

### Key rules
1. **Habit data is the source of truth.** Screens never schedule alarms directly; they save the habit and call `syncHabit`. Re-planning replaces alarms — removed times are cancelled, nothing duplicates.
2. **Stable ids.** `id = FNV-1a("<habitId>|daily|HH:mm")` / `"<habitId>|once|<iso>"` / `"<habitId>|session"`. Pinned by `test/reminders/alarm_id_test.dart`. **Never change the algorithm** without a migration.
3. **One alarm per daily time.** Medicine date ranges are a daily alarm with an `endAt`, not one alarm per day.
4. **Reconcile on every launch.** `startup()` re-arms all reminders from data and cancels reminders of habits that no longer exist.
5. **Local only.** No reminder depends on network or FCM.
6. **Session-end alarms** (meditation/reading/workout timers) use one stable id per habit and are cancelled on stop, pause and leaving the screen.

## 3. Exact alarms (Android 12+)
- Manifest keeps `SCHEDULE_EXACT_ALARM`. If not granted, alarms are armed with `setAndAllowWhileIdle` (may be several minutes late in Doze) instead of crashing / silently failing.
- Home shows a one-time explanation dialog (only if the user has enabled habits) that opens the system "Alarms & reminders" screen.
- `USE_EXACT_ALARM` is **not** used: Google Play restricts it to alarm-clock/calendar apps. Play Console will require the exact-alarm declaration for `SCHEDULE_EXACT_ALARM`.
- We do not promise exact delivery; OEM battery managers (Xiaomi, Oppo, Samsung, etc.) can still delay or kill alarms.

## 4. Legacy migration (runs once, first launch of the new build)
1. `enableLegacyCleanup` — native receiver will drop any alarm id not in its store.
2. Cancel every android_alarm_manager_plus alarm (ids read from the plugin's own persisted set).
3. Set `reminders_migrated_v2`; then reconcile re-creates all live reminders with new ids.
- Legacy native alarms whose ids can't be recomputed self-destruct the next time they fire.
- If the migration throws, the flag stays unset and it retries next launch; reminders are still armed.
- **Known loss:** one-time reminders created before this build were never saved, so they cannot be recreated. They are dropped.

## 5. Files
- `lib/core/reminders/alarm_id.dart`, `reminder_spec.dart`, `habit_reminder_planner.dart`, `reminder_service.dart`
- `lib/services/native_alarm.dart` (backend), `lib/services/notification_service.dart` (legacy callback guard; deprecated scheduling APIs)
- `android/app/src/main/kotlin/com/daily/mantra/AlarmScheduler.kt`, `AlarmReceiver.kt`, `BootReceiver.kt`, `MainActivity.kt`

## 6. Manual device test checklist (required — not yet run)

Run on at least one Android 14/15 device and one Android 10–12 device. Install **v1.0.0 first**, create data, then upgrade to this build to test migration.

| # | Scenario | Expected |
|---|---|---|
| M1 | Upgrade from v1.0.0 with water + medicine (date range) + reading habits, open app once | Each reminder fires once at its time; no duplicates the next day |
| M2 | Upgrade, but don't open the app before a reminder time | Old reminder still fires (legacy behaviour preserved until first open) |
| M3 | Delete a habit | It never notifies again (check next 2 days) |
| M4 | Change a habit's time 08:00 → 09:00 | Only 09:00 fires |
| M5 | Disable a medicine | No notifications |
| M6 | Medicine ending tomorrow, 2 dose times | Fires today/tomorrow; nothing the day after |
| M7 | Reboot device | Water/meditation/generic/medicine reminders still fire |
| M8 | Change timezone / manual clock change | Reminders fire at the new local wall-clock time |
| M9 | Android 14 fresh install, exact alarm denied | No crash; dialog shown once; reminders arrive (possibly a few minutes late) |
| M10 | Grant exact alarm in Settings | Reminders on the minute |
| M11 | Start meditation, stop after 1 min | No "Meditation finished" notification later |
| M12 | Start reading session, pause | No "Reading session done" notification |
| M13 | Add a one-time reading reminder for +5 min | Fires once; never again |
| M14 | Force-stop app (Settings → Force stop) | Android cancels alarms on force-stop by design; reopening the app re-arms them (documented platform limitation) |
| M15 | Generic habit with single time (no extra times) | Saves without crash; fires |
| M16 | Medicine reminder fires; tap **Taken** with the app swiped away; open app | Notification dismissed; medicine screen shows that dose as Taken |
| M17 | Medicine reminder; tap **Snooze 10 min** | Notification dismissed; same reminder (with buttons) returns ~10 min later |
| M18 | Exercise: walk every 60 min on, stretch every 120 min on | Notifications at 10:00…18:00 hourly; 11/13/15/17 show "walk and stretch" once (not twice); switching off cancels them |
