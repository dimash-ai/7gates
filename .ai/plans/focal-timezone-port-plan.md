# Summary

Implement `focal-timezone-port` (Phase 2 step 8, server side): port the legacy `shared/timezone.ts`
DST-aware time/timezone utility to a pure Python module `app/domain/timezone.py`, with 1:1 behavioral
parity to `shared/timezone.test.ts`. **No** DB, model, migration, route, or service-wiring change — a
leaf domain utility, consumed by later phases (work-time math, AI handlers). Task:
[focal-timezone-port.md](../tasks/focal-timezone-port.md). Legacy source: `focal/shared/timezone.ts`.

The companion `shared/datePresetRange.ts` is **not** ported (client-only filter-UI logic; zero
`focal/server` callers — confirmed at Gate 1; the server already resolves windows via `daterange.py`).
It ports with the TS frontend.

## Decisions (design + the Gate-1 rulings)

- **`zoneinfo` for offsets/rendering + the legacy two-pass for the source instant.** Offsets and
  rendering use `datetime` + `ZoneInfo` (stdlib + the pinned `tzdata>=2026.2`). `convert_date_and_time`
  resolves the source UTC instant with the legacy's two-pass (interpret the wall clock as if UTC →
  correct by the source offset → re-read once for transition days) so DST-transition days match the
  legacy **exactly** — including the nonexistent spring-forward hour (`02:30` LA on `2026-03-08` →
  `09:30Z`, where the naive `.replace(tzinfo=...)` shortcut diverged by an hour to `10:30Z`). The New
  York fall-back still lands on the earlier (EDT) occurrence → `05:30Z`.
- **`get_timezone_offset_at` anchors at local noon** of the target date before reading `utcoffset()`,
  so a date's offset is never read across a 02:00–03:00 transition edge — the same intent as the
  legacy's anchor-shift dance, expressed directly.
- **`time_to_minutes("")` raises `ValueError`** (not JS `NaN`). Deliberate deviation (Gate-1
  Should-Consider): the only caller path is a validated `"HH:MM"`, and `convert_date_and_time`
  short-circuits empty `time` before parsing. Called out in the docstring + a test.
- **The two offset helpers (`get_timezone_offset` / `get_timezone_offset_at`) are intentional
  full-module parity** (Gate-1 Should-Consider): no server caller today, ported because they are part
  of the cohesive tz utility and plausibly used by Phase 3 (Google offsets). A module docstring note
  labels them as parity/future-use rather than dead code.
- **Typed returns via `NamedTuple`** — `TzDateTime(date, time)` and
  `NowInTimezone(hours, minutes, date_string, time_label)` — readable + mypy-clean, no Pydantic needed
  for a pure leaf util.
- **No wiring.** No route/service imports it yet; that is faithful (the legacy server consumers —
  work-time calc, AI handlers — are ported in later phases). No `app/main.py` / schema / migration edit.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/server/app/domain/timezone.py` | add | the ported pure utility (6 functions + 2 NamedTuples) |
| `superapp/apps/focal/server/tests/test_timezone.py` | add | 1:1 parity tests for every legacy case |

# Implementation slices

One slice (pure code, no DB), leaving `make verify` green:

1. **Module + tests.** Write `app/domain/timezone.py` and `tests/test_timezone.py`.
   *Verify:* `make verify` (ruff + ruff format + mypy + pytest) green; `alembic check` clean (no
   migration); no other suite touched.

# Tests

Ported 1:1 from `shared/timezone.test.ts`, behavioral names (no spec/phase IDs):

- **`time_to_minutes`:** `00:00→0`, `01:30→90`, `12:00→720`, `23:59→1439`, `09:05→545`; `""` raises
  `ValueError`.
- **`minutes_to_time`:** `0→"00:00"`, `90→"01:30"`, `720→"12:00"`, `1439→"23:59"`; wrap `-60→"23:00"`,
  `-1→"23:59"`, `1440→"00:00"`, `1500→"01:00"`.
- **`get_timezone_offset`:** `UTC→0`, `"Invalid/Timezone"→0`, `""→0`, `Asia/Almaty ∈ [300,360]`.
- **`get_timezone_offset_at`:** `UTC` on any date `→0`, `"Not/Real"→0`, `Asia/Almaty` winter == summer
  (no DST).
- **`convert_date_and_time`:** same-zone identity; empty `time` → unchanged; empty `from==to` →
  unchanged; UTC↔Almaty ±5h; midnight roll forward (`22:00`/`23:59` UTC → Almaty, date +1) and back
  (`02:00` Almaty → UTC, date −1); `00:00` → `05:00`; invalid `from_tz` / `to_tz` → inputs unchanged;
  DST LA spring-forward (`2026-03-08 23:30 LA → 06:30Z 03-09`), Berlin spring-forward
  (`2026-03-29 00:30 UTC → 01:30` CET), NY fall-back (`2026-11-01 01:30 NY → 05:30Z`); Almaty stable
  winter/summer; round-trips UTC↔Almaty and LA↔UTC.
- **`get_now_in_timezone`:** `UTC` well-formed (`hours ∈ [0,24)`, `minutes ∈ [0,60)`, `date`
  `YYYY-MM-DD`, `label` `HH:MM`); invalid zone → fallback, still well-formed; `Asia/Almaty` vs `UTC`
  wall-clock diff ∈ [300,360] min (mod 1440).

# Error & rescue map

| failure mode | behavior | where |
|--------------|----------|-------|
| Invalid/empty IANA zone in `get_timezone_offset*` | return `0` | narrow `ZoneInfoNotFoundError`/`ValueError` catch |
| Invalid IANA zone in `convert_date_and_time` | return `(date_str, time)` unchanged | same catch |
| Empty `time` or `from_tz == to_tz` in `convert_date_and_time` | short-circuit `(date_str, time)` | guard before parse |
| Invalid zone in `get_now_in_timezone` | fall back to system-local now | same catch |
| Malformed `"HH:MM"` in `time_to_minutes` | `ValueError` (deliberate) | no catch (validated upstream) |

# Review lenses (pre-answer)

- **Scope / strategy.** One pure file + its tests; no DB/model/migration/route/wiring. The minimum that
  ports the module faithfully.
- **Architecture.** Leaf domain utility under `app/domain/` beside `daterange.py`/`recurrence.py`;
  invalid input falls back exactly as the legacy `try/catch`; typed `NamedTuple` returns.
- **Completeness.** Every legacy test case is ported; the two intentional deviations (`ValueError`,
  offset-helper parity) are documented and tested.
- **Tests & verification.** `make verify` green; `alembic check` clean.

# Risks & migrations

- **No migration** (pure code) — `alembic check` stays clean.
- **`tzdata` availability:** pinned `tzdata>=2026.2`; `calendar.py` already relies on `zoneinfo`
  (`available_timezones()`), and the suite runs green, so IANA data is present in dev + CI.
- **DST correctness** is the only real risk; it is pinned by the LA/Berlin/NY parity tests.
- **No call-site changes** → nothing else can regress; no existing suite is touched.

# Scope check

- [x] Matches the task Scope / Out of scope (timezone ported in full; `datePresetRange` deferred; no
      model/migration/route/wiring).
- [x] Reviewable in one pass — one module + one test file.
- [x] Size smell: no model, no migration, no new error code, no schema, no router edit.

# Out of scope

`shared/datePresetRange.ts` (client-only → TS frontend track); wiring the helpers into any route/service
(later-phase consumers); the React UI; Google sync; ETL; the client `use-timezone.tsx` hook.
