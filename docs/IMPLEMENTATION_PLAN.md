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
| On-device verification (checklist M1–M15) | ⛔ needs a physical device / emulator |

## Phase 1 — Architecture & database 🔄 (core done)
| # | Task | Status |
|---|---|---|
| 1.1 | `git init`, baseline commit, push to GitHub | ✅ (CI still ⬜) |
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
| 1.16 | Bump Kotlin Gradle plugin 2.0 → 2.2 (non-fatal metadata warnings in release build) | ⬜ |

## Phase 2 — Brand & UI ⬜
2.1 Design tokens (colour roles from Deep Teal/Mint/Coral/Lavender/Sky, contrast-checked), typography (Plus Jakarta Sans + Noto Sans Devanagari), spacing, radii · 2.2 Light/dark/system theme · 2.3 Component library (cards, progress rings, empty/error/skeleton states, reminder editor, session timer) · 2.4 Onboarding (language, goals, interests, reminder prefs, permission explainers, guest mode) · 2.5 Today dashboard with real data, re-orderable sections · 2.6 Notification monochrome icon (D23) · 2.7 Fix deprecations (D26) · 2.8 Accessibility pass (TalkBack, text scale 200%, 48dp targets)
⛔ Logo asset not in repo (D19).

## Phase 3 — Core features ⬜
3.1 Medicine: taken/skipped/snoozed log, notification actions, refill reminder, history export (CSV/PDF) · 3.2 Water: container sizes, quick-log notification action, trends · 3.3 Exercise: Health Connect/pedometer steps, **office walk/stretch reminders actually scheduled** (D18) · 3.4 Custom habits: weekly/flexible frequency, pause/archive/reorder, notes · 3.5 Reminder engine v2: actions, snooze, quiet hours, per-category prefs, deep links, diagnostics screen · 3.6 **iOS reminders** via `flutter_local_notifications` zoned schedules (64-pending limit → rolling window) (D20) · 3.7 Mood, sleep, journal, focus timer, routines, weekly reflection (opt-in modules) · 3.8 Localisation EN + NE (ARB), Bikram Sambat date display

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
