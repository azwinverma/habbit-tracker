# Migration & Rollback Plan

## Principles
- Existing users' data is never deleted or rewritten in a lossy way.
- Every storage change is additive and backward-readable, or done by a versioned, idempotent migration that keeps the old copy until the new one is verified.
- Each phase ships behind a rollback path.

## M0 — Phase 0 (done)

| Change | Compatibility | Rollback |
|---|---|---|
| `Habit.oneTimeReminders` added to `habits_v1` JSON | Additive. Old records decode with `[]`. v1.0.0 builds ignore the unknown key. | Install v1.0.0 — data still loads |
| `reminder_registry_v1`, `reminders_migrated_v2`, `exact_alarm_prompt_shown` (SharedPreferences) | New keys only | Ignored by old build |
| Native `dm_alarm_store` (Kotlin prefs) | New store | Ignored by old build |
| Legacy alarms retired (see NOTIFICATION_ARCHITECTURE §4) | One-way | Downgrade to v1.0.0 → open each habit screen and press Save to re-create alarms |

**Code rollback:** `.phase0_backup/pre-phase0-2026-11-24.tar.gz` (full source snapshot, excluding build outputs). Git history now starts from the Phase 0 commit on GitHub (`main`).

## M1 — Phase 1: SharedPreferences → Drift/SQLite ✅ implemented

1. Ship Drift schema v1 alongside SharedPreferences (read-only from prefs).
2. On first launch: in one transaction, import every `habits_v1` record into typed tables:
   - `habits` (common fields) + per-category tables (`medicine_schedules`, `water_goals`, …) instead of the nullable "god object".
   - Daily counters (`waterCompleted`, `meditationTodayMin`, `exerciseTodayMin`, `stepsToday` + their `*LastDate`) become the first rows of `habit_logs` for that date.
   - `exerciseScheduleJson` / `exerciseMilestonesJson` parsed into tables; on parse failure keep the raw JSON in a `legacy_blob` column (never drop).
   - `streak` / `lastCompleted` kept as-is (history before migration can't be reconstructed).
3. Verify: row counts and a checksum of ids match; only then write `migration_v1_done`.
4. Keep `habits_v1` untouched for at least two releases (rollback = ignore DB, read prefs).
5. Tests: golden JSON fixtures from real v1.0.0 data shapes → expected DB rows; corrupted/partial JSON; re-run idempotency.

**As implemented** (`LegacyHabitMigrator`, `HabitRepository`, tests in `test/db/`):
- Single transaction, de-duplicates ids, verifies row count, then sets `migrated_habits_v1` in `app_meta`. Corrupt JSON → rollback, no flag, retried next launch.
- Round-trip of every v1 field is lossless (tested per category).
- Every save still writes `habits_v1` too (dual-write) → downgrade to v1.0.0 sees current data.
- If the DB can't open/migrate, `StorageService` falls back to `habits_v1` so the app keeps working.
- Deleting a habit deletes its settings and history (cascade) — user intent + privacy.
- Deviation from plan: exercise week plan / milestones are stored as JSON text columns in `exercise_settings` (not yet normalised); table names are `medicine_details`, `water_settings`, `meditation_settings`, `exercise_settings`.

## M2 — Phase 4: Local → Cloud sync (planned)
- Local DB stays the source of truth; Firestore is a replica.
- Stable UUIDs per record (existing timestamp ids are kept as `legacyId`).
- Outbox table for pending writes; idempotent upserts keyed by record id + version.
- Conflict policy: append-only for logs (medicine taken/skipped, water, sessions) — **never last-write-wins on medication history**; field-level LWW with version vectors only for editable settings.
- Account switch: per-account DB file; guest data offered for merge on first sign-in.
