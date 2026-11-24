# DailyMantra 2.0 — Implementation Plan & Task Tracker

Legend: ✅ done · 🔄 in progress · ⬜ not started · ⛔ blocked (needs owner input/credentials)

## Reality check on scope
The 2.0 brief covers three products: a rebuilt mobile app, a Firebase backend with content pipelines, and a Next.js admin portal. Built properly, that is many months of work. The plan below is ordered so that **every phase ships a better, releasable app**, and nothing in later phases forces rework of earlier ones. Work that needs accounts, credentials or legal decisions is marked ⛔ and is not faked.

## Dependency graph

```
P0 Stabilize ─► P1 Architecture + DB ─┬─► P2 Brand/UI ─┬─► P3 Core features ─► P6 Offline media ─┐
                                      │                └─► P7a Insights/widgets               ├─► P8 Hardening
                                      └─► P4 Firebase (⛔ project) ─► P5 Admin ─► P6 / P7b monetization ┘
```
P2 can start in parallel with late P1. P4 can start once P1's repository layer exists.

## Phase 0 — Audit & stabilization ✅
| Task | Status |
|---|---|
| Repository audit, defect list (`PHASE0_AUDIT.md`) | ✅ |
| Baseline analyze/test/build | ✅ |
| Rollback snapshot | ✅ |
| Unified reminder engine (planner + registry + native store) | ✅ |
| Cancel on delete/edit/disable; no duplicates; stable ids | ✅ |
| Reboot / update / time-zone recovery | ✅ |
| Exact-alarm permission fallback + explained prompt | ✅ |
| Legacy alarm migration (zombie cleanup) | ✅ |
| Remove ads around medicine / meditation / reading | ✅ |
| Dependency hygiene, gitignore secrets, receiver not exported | ✅ |
| 37 unit tests (model, ids, planner, service) | ✅ |
| On-device verification (checklist M1–M18) | ⛔ needs a physical device / emulator |

## Phase 1 — Architecture & database 🔄 (core done)
| # | Task | Status |
|---|---|---|
| 1.1 | `git init`, baseline commit, push to GitHub, CI | ✅ (GitHub Actions: codegen check, analyze, test, debug APK) |
| 1.2 | Riverpod + GoRouter; app shell Today / Plan / Add / Insights / You | ✅ |
| 1.3 | Remove hard-coded API URL (D21) | ✅ (dead PythonAnywhere API removed). Flavors dev/prod ⬜ |
| 1.4 | Drift schema v1: habits, per-category settings, habit_logs, content cache, meta | ✅ |
| 1.5 | Migration from `habits_v1` + fixture tests | ✅ |
| 1.6 | Repository layer; per-category tables (no god-object in storage) | ✅. Typed domain models for screens ⬜ (Phase 2/3, per screen) |
| 1.7 | ReminderService reads repository data | ✅ (via StorageService facade) |
| 1.8 | Delete dead code (D22); extract shared flows | ✅ −11k lines; `HabitFlows`. Splitting big screens into widgets ⬜ |
| 1.9 | Completion history in DB | ✅ (`habit_logs`). Flexible streaks / recovery days ⬜ |
| 1.10 | **Dynamic free content engine** (Gutenberg, Wikimedia Commons, wger) refreshed on app open, offline cache, New badges, Discover | ✅ |
| 1.11 | Firebase project wired (`flutterfire configure`, `Firebase.initializeApp`) | ✅ |
| 1.12 | Plan: upcoming reminders, reminder health, test reminder | ✅ |
| 1.13 | Insights (7-day history), You (theme, permissions, sources & licences) | ✅ |
| 1.14 | Dark mode with brand palette | ✅ (full design system in Phase 2) |
| 1.15 | Widget smoke tests for new screens (Insights, Discover, Plan) | ✅ (integration tests ⬜) |
| 1.16 | Kotlin metadata warnings in release build | ✅ investigated: project already on Kotlin 2.2; warnings come from a third-party plugin's compile settings, non-fatal |

## Phase 2 — Brand & UI 🔄
| # | Task | Status |
|---|---|---|
| 2.1 | Brand colour tokens (blueprint palette), light/dark | ✅ (`lib/app/theme.dart`). Contrast audit per pairing ⬜ |
| 2.1b | Brand typography (Plus Jakarta Sans + Noto Sans Devanagari) | ⬜ deferred until the brand assets arrive. Android's built-in Noto Sans Devanagari renders Nepali meanwhile |
| 2.2 | Theme preference (system/light/dark) | ✅ |
| 2.3 | Shared components: `ReminderScheduleEditor` (replaces 3 copied implementations; shows and removes saved one-time reminders) | ✅. Session timer / action button extraction ⬜ |
| 2.4 | Onboarding: welcome + language, goals, 1–3 starter habits with times, privacy; skippable; existing users skip; permission asked only after first reminder | ✅ |
| 2.4b | Localization foundation EN + नेपाली (gen-l10n), language picker | ✅ for shell, Today, Plan, Insights, You, onboarding. Category screens + Discover ⬜ (Phase 3) |
| 2.5 | Today dashboard with real data | ✅ (greeting, progress, quick add, habits). Re-orderable sections ⬜ |
| 2.6 | Monochrome notification icon | ✅ placeholder silhouette (`ic_stat_dailymantra`). Swap for the logo silhouette when provided |
| 2.7 | Analyzer clean (deprecations, async gaps, unused code) | ✅ **0 issues** |
| 2.8 | Accessibility pass | 🔄 semantics on done-toggle, progress, reminder editor tooltips. TalkBack / 200% text audit on device ⬜ |
| 2.9 | Splitting the large category screens into widgets | ⬜ (with Phase 3 rebuilds) |

⛔ Logo asset still not in repo (D19).

## Phase 3 — Core features 🔄
| # | Task | Status |
|---|---|---|
| 3.1a | Medicine taken/skipped log, undo, 7-day adherence (`habit_logs` metric `dose@HH:mm`) | ✅ |
| 3.1b | Notification actions Taken / Snooze 10 min (native `DoseActionReceiver`, queued → imported on app open/resume) | ✅ (device check M16–M17 ⛔) |
| 3.1c | Refill reminder, history export (CSV/PDF), Skip action on notification | ⬜ |
| 3.3a | **Office walk/stretch reminders scheduled** (D18), merged when coinciding | ✅ (fixed office hours 09–18; configurable hours/weekdays ⬜) |
| 3.6 | **iOS reminders** (`IosAlarmBackend`: repeating daily triggers, rolling 7-day one-shots for bounded/future courses, contextual permission, foreground presentation); iOS min 15.0; CI iOS build | ✅ (device test ⛔; notification action buttons on iOS ⬜) |
| 3.8a | Medicine screen localized; office section localized | ✅. Water / meditation / reading / exercise rest / Discover ⬜ |

Remaining scope: 3.1 Medicine: taken/skipped/snoozed log, notification actions, refill reminder, history export (CSV/PDF) · 3.2 Water: container sizes, quick-log notification action, trends · 3.3 Exercise: Health Connect/pedometer steps, **office walk/stretch reminders actually scheduled** (D18) · 3.4 Custom habits: weekly/flexible frequency, pause/archive/reorder, notes · 3.5 Reminder engine v2: actions, snooze, quiet hours, per-category prefs, deep links, diagnostics screen · 3.6 **iOS reminders** via `flutter_local_notifications` zoned schedules (64-pending limit → rolling window) (D20) · 3.7 Mood, sleep, journal, focus timer, routines, weekly reflection (opt-in modules) · 3.8 Localisation EN + NE (ARB), Bikram Sambat date display

## Phase 4 — Firebase backend ⛔ (needs Firebase project on Blaze plan)
Auth (guest → linked account), Firestore per-user data with security rules + emulator tests, outbox sync (MIGRATION_PLAN M2), Remote Config, Analytics (no medicine/journal content), Crashlytics, App Check, Cloud Functions for content sync jobs (Gutendex, wger, …) with license metadata, account deletion + data export.

## Phase 5 — Admin dashboard ⛔ (depends on P4)
Next.js + TypeScript, Firebase Auth custom claims for roles, modules prioritised: content catalog + licensing/approval → providers & sync jobs → feature flags/config → ad placements → users/support → analytics → notification campaigns → audit logs.

## Phase 6 — Offline media ⬜
Download manager (pause/resume, checksums, storage quota, eviction), offline audio with background playback + lock-screen controls (`just_audio_background`), offline EPUB, workout instructions cache.

## Phase 7 — Engagement & monetization ⬜ / ⛔
Insights, challenges, achievements, home-screen widgets · Ads: remote-configured placements, consent (UMP) · Premium: Play Billing / StoreKit, server-side receipt validation (⛔ store accounts) · Optional AI via backend proxy with consent and quotas.

## Phase 8 — Hardening ⬜
Integration tests for critical journeys, security review of rules/functions, performance (startup, jank), accessibility audit, Play policy (exact alarm declaration, health data, ads), release pipeline.

## Decisions needed from the owner
1. ~~Version control~~ — done (GitHub `main`).
2. ~~Firebase project~~ — `habbittracker-c2daa` wired. **Blaze plan** still needed for Cloud Functions/Scheduler in Phase 4.
3. **Logo:** still not in the repo (blueprint received). Please add to `assets/branding/`.
4. ~~Content licence~~ — none exists; switched to free/open providers (see `CONTENT_SOURCES.md`).
5. **Monorepo move:** recommend keeping the Flutter app at the repo root until Phase 4, then moving to `apps/mobile` in one dedicated change (avoids breaking signing/IDE paths now).
6. **Priority:** if time is limited, recommended order after P1 is P2 → P3 (medicine/reminders/iOS) → P4, with the admin dashboard after the app is stable.
