# Goal

Port the focal **habit tracking** surface (Phase 4, slice 2 of 2): habit entries + streaks + entry
stats over the already-scaffolded `HabitEntry` model. `GET /api/habit-entries` (window),
`GET /api/habit-entries/stats` (aggregation), `POST /api/habit-entries` (upsert per habit+day),
`DELETE /api/habit-entries` (reset a day), `GET /api/habits/streaks` (server-side streak). Legacy:
`routes.ts:3347` + `routes.ts:3213` (streaks), `storage.ts:6912`.

# Scope

- **`app/schemas/habit.py`** (extend) — `HabitEntryUpsert` (`habit_id` required, `date` (a `date`),
  `status` `Literal["yes","no","skip"]`, `note?`), `HabitEntryRead` (all columns, camelCase),
  `HabitStreakRead` (`habit_id`, `streak`), `HabitEntryStatRead` (`habit_id`, `period`, `yes`, `no`,
  `skip`).
- **`app/services/habits.py`** (extend `HabitsService`):
  - `list_entries(user_id, *, start, end)` → entries for the user with `start <= date <= end`
    (`getHabitEntriesByUser`).
  - `upsert_entry(user_id, payload)` → require the habit is **owned** (else `NotFoundError`); upsert on
    the `(habit_id, date)` unique key via `pg_insert(...).on_conflict_do_update(set_={status, note})`;
    `user_id` set on insert. Returns the row.
  - `delete_entry(user_id, *, habit_id, date)` → require the habit is **owned**; delete the
    `(habit_id, date)` row (idempotent — no row is fine).
  - `streaks(user_id, today)` → for each **active** habit, count consecutive `yes` days backward from
    `today` (a `skip` does **not** break the run; a `no`/missing day breaks it), bounded at 365 days
    (`getHabitStreaks`).
  - `entry_stats(user_id, *, start, end, granularity)` → per `habit_id` + period
    (`to_char(date,'YYYY-MM-DD')` for `day`, `'YYYY-MM'` for `month`), the `yes`/`no`/`skip` counts via
    `count(*) FILTER (WHERE status=…)`, ordered by period (`getHabitEntryStats`).
- **`app/api/habits.py`** (extend) — add `GET /streaks` (declared **before** `/{habit_id}`),
  `today` a required `date` query param.
- **`app/api/habit_entries.py`** (new) — `/api/habit-entries` router: `GET ""` (`start`/`end` required
  `date`), `GET /stats` (`+ granularity` `Literal["day","month"]`, default `month`), `POST ""`
  (upsert → 201), `DELETE ""` (`habitId`/`date` required → 204). Registered in `app/main.py`.
- **Tests** — entries window + tenant scope, upsert insert-then-update (same key), upsert
  cross-tenant habit → 404, delete (reset + idempotent + cross-tenant 404), streaks (yes run, skip
  doesn't break, no/missing breaks, archived excluded), stats (day vs month grouping, yes/no/skip
  counts), invalid/missing date params → 422.

# Decisions (design rulings to confirm at Gate 1)

- **Dates as FastAPI/Pydantic `date`** — `start`/`end`/`today`/entry `date` are `date`-typed (query or
  body); missing or malformed → 422 natively (the superapp convention; legacy returned 400).
- **`status` is `Literal["yes","no","skip"]`** → 422 on anything else.
- **Habit ownership required** for upsert/delete → `NotFoundError` (404) when the habit is missing or
  another user's (hardening the legacy 403, matching `projects.py`/slice 1).
- **`to_char` format is a fixed constant** (`'YYYY-MM-DD'` / `'YYYY-MM'`) keyed off the validated
  `granularity` — never interpolated user input.
- **streaks is a pure backward scan** in Python over the in-window entries map (faithful to the legacy
  365-day loop); `skip` continues the run, `no`/missing breaks it; only **active** habits.
- **`upsert` → 201; `DELETE` → 204; list/stats/streaks → 200.** Typed `AppError` only; camelCase;
  tenant = JWT `sub`. **No model/migration change** (`HabitEntry` already exists).

# Out of scope

- Habit CRUD/archive/restore/reorder (slice 1, shipped); the React UI; Google; ETL. No model/migration.

# Acceptance criteria

- [ ] `GET /api/habit-entries?start=&end=` returns the caller's entries in the window; missing/invalid
      `start`/`end` → 422; tenant-scoped.
- [ ] `POST /api/habit-entries` upserts on `(habitId, date)` — a second POST for the same key updates
      `status`/`note` (one row); a bad `status` → 422; a habit not owned → 404; → 201.
- [ ] `DELETE /api/habit-entries?habitId=&date=` removes that day's entry (→ 204), is idempotent, and
      404s for a non-owned habit.
- [ ] `GET /api/habits/streaks?today=` returns `{habitId, streak}` per active habit: a run of `yes`
      counts, an intervening `skip` does not break it, a `no`/missing day stops it; archived habits are
      excluded.
- [ ] `GET /api/habit-entries/stats?start=&end=&granularity=` returns per-habit per-period
      `yes`/`no`/`skip` counts; `day` groups by date, `month` by month.
- [ ] `make verify` green; `alembic check` clean (no migration); tenant isolation across all five.

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```
