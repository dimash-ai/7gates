# Goal

Port the focal `shared/timezone.ts` DST-aware timezone/time utility to the Python server as
`app/domain/timezone.py`, with full behavioral parity to the legacy test suite (Phase 2 step 8,
server side). These are the pure time-and-timezone helpers the server uses for work-time math and (in
later phases) AI time handling: `timeToMinutes` / `minutesToTime` (HH:MM ↔ minutes),
`getTimezoneOffset` / `getTimezoneOffsetAt` (offset in minutes, now / a given date),
`convertDateAndTime` (DST-correct date+time conversion across zones, handling the midnight crossing),
and `getNowInTimezone` (current wall-clock in a zone).

The companion `shared/datePresetRange.ts` is **deliberately not ported to Python** — see Out of scope.

# Scope

- **`app/domain/timezone.py`** — a pure module over `zoneinfo` (stdlib + the pinned `tzdata`), porting
  the six functions 1:1 by behavior:
  - `time_to_minutes(time: str) -> int` — parse `"HH:MM"` → minutes from midnight.
  - `minutes_to_time(total_minutes: int) -> str` — minutes → `"HH:MM"`, wrapping into `[0, 1440)`
    (`-60 → "23:00"`, `1440 → "00:00"`, `1500 → "01:00"`).
  - `get_timezone_offset(timezone: str) -> int` — offset in minutes for *now*; invalid/empty zone → 0.
  - `get_timezone_offset_at(timezone: str, date_str: str) -> int` — offset in minutes for a given
    `YYYY-MM-DD` (DST-correct; anchored at local noon to avoid transition edges); invalid → 0.
  - `convert_date_and_time(date_str, time, from_tz, to_tz) -> TzDateTime` — DST-correct conversion of a
    wall-clock `date_str`+`time` from one IANA zone to another, returning the rendered `(date, time)`
    and handling the midnight roll. Short-circuits when `time` is empty or `from_tz == to_tz`; any
    invalid zone falls back to the inputs unchanged.
  - `get_now_in_timezone(timezone: str) -> NowInTimezone` — `(hours, minutes, date_string, time_label)`
    for the current instant in `timezone`; invalid zone falls back to system-local now.
  - Typed returns: `TzDateTime(NamedTuple){date, time}` and
    `NowInTimezone(NamedTuple){hours, minutes, date_string, time_label}`.
- **`tests/test_timezone.py`** — port the legacy `timezone.test.ts` cases 1:1: time parse/format incl.
  negative / over-24h wrap; offsets for UTC / invalid / Almaty (no-DST stable); conversion incl. ±5h,
  midnight roll both directions, empty / invalid-zone fallbacks, and the DST cases (LA spring-forward,
  Berlin spring-forward, NY fall-back ambiguity → earlier / `fold=0` occurrence) + round-trips;
  `get_now_in_timezone` structure/range checks.

# Decisions (design rulings to confirm at Gate 1)

- **`zoneinfo`, not hand-rolled offset arithmetic.** The legacy works around `Intl`'s limits with a
  two-pass offset computation; Python's `datetime` + `ZoneInfo` is DST-correct natively, so the port is
  idiomatic (`astimezone`) and reproduces every legacy case — including the New York fall-back
  ambiguity, where `ZoneInfo`'s default `fold=0` picks the **earlier** (EDT) occurrence, matching the
  legacy "first occurrence" result (`01:30` NY → `05:30Z`).
- **`time_to_minutes("")` raises `ValueError`** (Python) rather than returning JS `NaN`. The function
  is only ever called with a validated `"HH:MM"`; `convert_date_and_time` short-circuits empty `time`
  before any parse. Mirrors the hardening already taken in `daterange.py`.
- **Invalid timezones fall back, never raise** out of `get_timezone_offset*` (→ 0),
  `convert_date_and_time` (→ inputs unchanged), and `get_now_in_timezone` (→ system-local), via a
  narrow `ZoneInfoNotFoundError` / `ValueError` catch — faithful to the legacy `try/catch`.
- **Pure domain module**, no DB, no `AppError` (leaf utilities); lives under `app/domain/` beside
  `daterange.py` / `recurrence.py`.

# Out of scope

- **`shared/datePresetRange.ts` is not ported to Python.** It is client filter-UI logic (preset chips →
  a `{from,to}` range on the Events / Tasks pages) with **zero** server callers — the server receives
  explicit `startDate` / `endDate` and already resolves the task-list window via
  `app/domain/daterange.py`. Under the Python-server / TS-client split a Python port would be dead
  code; it ports with the React UI on the frontend track (as TS, or a shared TS package).
- The React UI; wiring these helpers into routes/services (no current call-site changes — the AI and
  work-time consumers arrive in later phases); Google sync; ETL; no migration (pure code).

# Acceptance criteria

- [ ] `app/domain/timezone.py` exists with the six functions above; `make verify` green
      (ruff + ruff format + mypy + pytest).
- [ ] `time_to_minutes` / `minutes_to_time` round-trip and wrap exactly as the legacy
      (`-60 → "23:00"`, `1440 → "00:00"`, `1500 → "01:00"`); `time_to_minutes("")` raises `ValueError`.
- [ ] `get_timezone_offset("UTC") == 0`, invalid/empty → 0, `Asia/Almaty` ∈ [300, 360];
      `get_timezone_offset_at` is DST-stable for `Asia/Almaty` (winter == summer) and 0 for UTC/invalid.
- [ ] `convert_date_and_time` reproduces every legacy case: identity (same zone / empty time), ±5h
      Almaty↔UTC, midnight roll forward (+1 day) and back (−1 day), invalid from/to → unchanged, LA &
      Berlin spring-forward, NY fall-back → `05:30Z`, and round-trips (UTC↔Almaty, LA↔UTC).
- [ ] `get_now_in_timezone` returns a well-formed `(hours ∈ [0,24), minutes ∈ [0,60), date YYYY-MM-DD,
      label HH:MM)`; invalid zone falls back without raising.
- [ ] No migration; `alembic check` clean. No call-site / route changes (leaf utility port).

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```
