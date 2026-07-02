# Summary

Implement `focal-habits-entries` (Phase 4, slice 2 of 2): the habit tracking surface over the existing
`HabitEntry` model — `GET /api/habit-entries` (window), `GET /api/habit-entries/stats`, `POST
/api/habit-entries` (upsert), `DELETE /api/habit-entries`, `GET /api/habits/streaks`. Extends
`HabitsService` + the habits router; adds a `habit-entries` router. **No** model or migration change.
Task: [focal-habits-entries.md](../tasks/focal-habits-entries.md). Legacy: `routes.ts:3347` / `:3213`,
`storage.ts:6912`.

## Decisions (design + Gate-1 rulings)

- **Dates are `date`-typed** (FastAPI query / Pydantic body): `start`/`end`/`today`/entry `date` →
  missing or malformed → 422 natively (superapp convention; legacy 400).
- **`status` `Literal["yes","no","skip"]`**, **`granularity` `Literal["day","month"]`** (default
  `month`) → 422 on anything else.
- **Habit ownership required** for `upsert`/`delete` → `NotFoundError` (404) when missing or another
  user's (hardens the legacy 403, matching slice 1 / `projects.py`).
- **Upsert** via `pg_insert(HabitEntry).values(...).on_conflict_do_update(index_elements=["habit_id",
  "date"], set_={"status":…, "note":…})` (`user_id` only on insert), `.returning(...)` then re-read —
  mirrors the `calendar.py` override upsert; the `(habit_id, date)` unique key already exists.
- **streaks** = a pure backward day scan in Python over the in-window entries map: from `today`, count
  `yes`, a `skip` continues the run, a `no`/missing day breaks it; bounded 365 days; **active** habits
  only.
- **stats** = `select(habit_id, to_char(date, FMT) AS period, count() FILTER (status='yes'), …)
  group_by(habit_id, period) order_by(period)`; `FMT` is the fixed constant chosen by the validated
  `granularity` (no interpolated input).
- **Status codes:** `upsert` → 201; `DELETE` → 204; list/stats/streaks → 200. Typed `AppError`;
  camelCase; tenant = JWT `sub`. **No migration.**

# Files to change

| path | change | why |
|------|--------|-----|
| `app/schemas/habit.py` | modify | add `HabitEntryUpsert` / `HabitEntryRead` / `HabitStreakRead` / `HabitEntryStatRead` |
| `app/services/habits.py` | modify | add `list_entries` / `upsert_entry` / `delete_entry` / `streaks` / `entry_stats` (+ `_require_owned_habit`) |
| `app/api/habits.py` | modify | add `GET /streaks` (before `/{habit_id}`) |
| `app/api/habit_entries.py` | add | `/api/habit-entries` router (list / stats / upsert / delete) |
| `app/main.py` | modify | register the `habit_entries` router |
| `tests/test_habit_entries_db.py` | add | window / upsert / delete / streaks / stats / tenant / validation |

# Implementation slices

Each leaves `make verify` green.

1. **Schemas + service methods.** *Verify:* `make verify` (no DB-route change yet, service unit-safe).
2. **Routers + main.** `GET /api/habits/streaks` + the `habit-entries` router; register. *Verify:*
   `make verify` + `alembic check` clean.
3. **Tests.** *Verify:* full `make verify` green.

# Tests

- **list:** entries for the caller in `[start, end]`; an out-of-window entry excluded; another user's
  entries excluded; missing/invalid `start`/`end` → 422.
- **upsert:** first POST inserts (201); a second POST for the same `(habitId, date)` updates
  `status`/`note` and leaves **one** row; `status="bogus"` → 422; a non-owned `habitId` → 404.
- **delete:** removes that `(habitId, date)` entry (→ 204); deleting a non-existent day is a no-op 204;
  a non-owned `habitId` → 404.
- **streaks:** `yes,yes,yes` back from today → 3; a `skip` between `yes`es does not break (counts
  through it); a `no` or a missing day stops the count; an archived habit is excluded; `today` missing
  → 422.
- **stats:** `granularity=day` groups per date, `month` per month; `yes`/`no`/`skip` counts correct;
  ordered by period.
- **tenant isolation:** every endpoint scoped to the JWT `sub`.

# Error & rescue map

| failure mode | error | response |
|--------------|-------|----------|
| upsert/delete on a missing or non-owned habit | `NotFoundError` | 404 |
| bad `status` / `granularity`; missing/invalid `start`/`end`/`today`/`date` | Pydantic / FastAPI validation | 422 |
| delete a `(habit_id, date)` with no row | none (idempotent) | 204 |
| no auth / bad JWT | `AuthRequiredError` | 401 |

# Review lenses (pre-answer)

- **Scope / strategy.** Extends an existing service + adds one router over an existing model; no
  migration. The only non-trivial logic is the streak scan and the stats aggregation, both faithful
  ports.
- **Architecture.** Tenant-scoped via the JWT; ownership enforced on writes; upsert via the existing
  unique key; stats uses a parameter-free `to_char` constant.
- **Completeness.** Window, upsert insert+update, idempotent delete, streak edge cases (skip/no/missing/
  archived), stats grouping, validation, tenant isolation each map to a test.
- **Tests & verification.** `make verify` green; `alembic check` clean (no migration).

# Risks & migrations

- **No migration** — `HabitEntry` exists; `alembic check` stays clean.
- **Route ordering:** `GET /api/habits/streaks` must precede `GET /api/habits/{habit_id}`.
- **`count(*) FILTER` + `to_char`** are Postgres features (the dev/prod DB is Postgres) — fine; the
  stats test pins them.
- **streak DST safety:** the scan uses calendar `date` arithmetic (`date - timedelta(days=1)`), not
  timestamps, so it is offset-free (the legacy used local noon for the same reason).

# Scope check

- [x] Matches the task Scope / Out of scope (entries/streaks/stats; CRUD was slice 1; no
      model/migration).
- [x] Reviewable in one pass — 3 sequenced slices, each green.
- [x] Size smell: no model, no migration; schema + service extension + one new router + tests.

# Out of scope

Habit CRUD/archive/restore/reorder (slice 1); the React UI; Google; ETL.
