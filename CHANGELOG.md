# Changelog

## [2.0.0] — Content library, offline downloads, background refresh (2026-11-25)

### Added
- **Audiobooks:** ~300 public-domain LibriVox audiobooks (Internet Archive), with chapters, speed control, ±30 s, remembered listening position and "Download all chapters".
- **Videos:** exercise, yoga and meditation videos (Wikimedia Commons) plus ~45 wger exercise demo videos. A new **Videos** tab, and a video badge on exercises that have a demo. Plays the right format per platform and falls back to the other if one fails.
- **Download for offline:** books save automatically on first open; audio and video have a Download button. You → *Saved for offline* shows storage used and can remove everything. Downloaded items are never pruned from the catalogue.
- **Fresher content:** every app open checks all sources (in parallel). Books refresh after 1 h, audiobooks and sounds after 6 h, videos after 12 h, exercises after 24 h. Android also refreshes in the background about every 12 h (network connected, battery not low).
- Discover redesigned and fully translated (English / नेपाली): five tabs, a *Saved* filter, video cards, and New and Saved badges.
- Polite networking: retries with back-off for rate limits (HTTP 429) and server errors.
- Draft privacy policy and release checklist (`docs/`).

### Changed
- Database schema v2 (additive migration, tested): alternate media URL, media size, `content_downloads` table. Shared across isolates for the background job.
- Version 2.0.0 (build 20).


## [Unreleased] — Redesign (Phase 2 design system)

### Added
- **New look across the app** following the brand guidelines: Plus Jakarta Sans + Noto Sans Devanagari (bundled, works offline), Deep Teal / Mint palette with per-category accents, soft rounded cards, pill buttons, calmer navigation with a central Add button. Light and dark.
- **Today dashboard:** progress ring with streak, tiles for water (**+1 glass in one tap**), medicine (**next dose + Taken in one tap**), movement, mind and reading; "Up next today"; habits with one-tap check; thought for the day.
- Redesigned Add sheet (category cards with a short benefit), Plan, Insights (2 columns on tablets), You (brand header, open-source licences) and splash (matching Android launch colour).
- Design system doc (`docs/DESIGN_SYSTEM.md`), automated WCAG contrast checks for both themes, screenshot harness for visual review.

### Fixed
- Today no longer waits for ads to load before showing your habits (if the ads SDK failed, Today could stay blank).
- Habit counts as done on Today when its daily goal is reached (water, meditation, exercise), not only when ticked.
- Two category colours adjusted to meet 3:1 contrast.

## [Unreleased] — Phase 3 (part 2)

### Added
- **iOS reminders** (previously none at all, D20). Daily reminders repeat on their own; medicine courses that end soon or start later are scheduled day by day for the next 7 days and topped up whenever the app opens, keeping well under iOS's 64-notification limit.

### Fixed
- iOS no longer asks for notification permission on first launch (only after the first reminder is set, as on Android).
- iOS build was broken since Firebase was added: minimum iOS raised to 15.0.
- iOS step counting: the motion permission text was misplaced in Info.plist, which would make iOS terminate the app when counting steps.
- CI now also builds the iOS app.

## [Unreleased] — Phase 3 (part 1)

### Added
- **Medicine dose log.** The medicine screen shows today's doses with *Taken* / *Skip* (and *Undo*), plus a 7-day adherence line ("5 of 6 doses taken").
- **Taken / Snooze 10 min buttons on medicine notifications.** *Taken* is recorded even when the app is closed and appears in the app the next time it opens. A snoozed dose keeps its original day.
- Medicine screen fully translated (English / नेपाली).

### Fixed
- **Office walk / stretch reminders now actually fire** (they were saved but never scheduled — D18). Each can be switched on/off with its own interval; reminders run every N minutes between 09:00 and 18:00, and a walk and stretch due at the same minute arrive as one notification. If you had set intervals before, they start reminding after this update.
- Removed the ad banner that was still shown on the medicine screen.
- Medicine screen no longer claims a 120-day limit (that limit was removed in Phase 0).

## [Unreleased] — Phase 2 (in progress)

### Added
- **Onboarding** for new users: language, goals, one to three starter habits with times, and a privacy note. Skippable; existing users never see it.
- **Nepali (नेपाली)** language support for the main screens and onboarding; language picker under You.
- Shared reminder editor: saved one-time reminders are now listed and can be removed.
- Monochrome status-bar notification icon with the brand accent colour.
- GitHub Actions CI (code generation check, analyze, tests, Android debug build).

### Fixed
- **Exercise "Save reminders" never saved.** The button only showed an ad. It now saves and schedules the reminders.
- The notification permission is no longer requested on first launch, only once you actually have a reminder.
- Static analysis is fully clean (deprecated APIs, unsafe context use after async gaps, dead code).


## [Unreleased] — Phase 1 (2026-11-24)

### Added
- **Free content that refreshes itself.** Public-domain books (Project Gutenberg), freely licensed nature and mindfulness sounds (Wikimedia Commons) and an exercise library (wger). New content is fetched when the app opens or returns to the foreground, cached for offline use, and marked **New** until viewed.
- **Discover** screen: search, books, sounds, exercises, Read now, Play, credits and licence for every item.
- New navigation: **Today · Plan · Add · Insights · You**.
- **Plan:** upcoming reminders by day, reminder health (notifications and on-time delivery), *Send a test reminder*.
- **Insights:** 7-day history for completions, water, meditation, exercise and steps.
- **You:** light/dark/system theme, reminder permission, content sources and status, sources and licences, privacy note.
- Tapping a habit now opens its screen (player, reader, tracker). Before, there was no way back into it after creation.
- Today shows a greeting and today's progress.
- Local SQLite database with history; one-time automatic migration of existing data.
- Firebase project configured (initialised only; no data is sent yet).

### Changed
- Meditation and reading now use the free catalogue. The previous content server was offline and its content unlicensed.
- Meditation sounds loop for the whole session.
- Brand colours (Deep Teal palette) and dark mode.
- **Minimum Android version is now 7.0 (API 24)**, required by Firebase.
- Removed ~11,000 lines of commented-out code.


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
