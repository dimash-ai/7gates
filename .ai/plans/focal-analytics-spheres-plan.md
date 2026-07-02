# Summary

Implement `focal-analytics-spheres` (Phase 4): `GET /api/analytics/spheres` — plan-vs-fact hours per
life sphere over a period. **Pure composition** over `CalendarService.list_events`, `LifeSphere`, and a
read-only `TimeBudgetSettings` select — no model/migration. Task:
[focal-analytics-spheres.md](../tasks/focal-analytics-spheres.md). Legacy: `routes.ts:5419`.

## Decisions (design + the Gate-1 ruling)

- **Reuse `CalendarService.list_events(start, end, today)`** for the recurrence-expanded, enriched,
  windowed events, then **post-filter to `period_start <= event.date <= period_end`** by the
  *effective* date — so an occurrence an override moved out of the window is excluded (matching the
  legacy by-`event.date` filter), and the legacy's latent bug is fixed: its analytics route called
  `getAllEventsEnriched(userId)` with no dates, defaulting to the **current month**, so this port
  queries the actually-requested period. `LifeSphere` rows for the spheres; a **read-only**
  `select(TimeBudgetSettings)` by `(user_id, year)` for the work plan (NOT `get_year` — analytics must
  not seed). Settings absent → `working_days_in_year=246`, `working_hours_per_day=8`.
- **Computation:** `days = (end - start).days + 1`; `work_plan = round1(wd * wh / 365 * days)`; per
  event with an `end_time`, `duration = (time_to_minutes(end) - time_to_minutes(start)) / 60` (skip
  `<= 0`); null `sphere` → `work_fact`, else the matching sphere's fact (unknown sphere dropped);
  `sphere.plan = round1(allocated_hours * days / 365)`. The **output** `work.fact` and every
  `sphere.fact` are `round1(...)` too — the legacy rounds both plan and fact.
- **`round1(x) = floor(x*10 + 0.5)/10`** (half-up) for parity with the legacy `Math.round(x*10)/10`.
- **Tenant from the JWT `sub`**; `periodStart`/`periodEnd` required `date` query params → 422.
- camelCase; pure read (no typed `AppError` path beyond validation); `today=period_end` is only the
  `get_date_range` fallback.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/schemas/analytics.py` | add | `SpheresAnalyticsRead` + the nested `period`/`work`/sphere models + `round1` lives in the service |
| `app/services/analytics.py` | add | `AnalyticsService.spheres` (composition + computation + `round1`) |
| `app/api/analytics.py` | add | `/api/analytics` router (`GET /spheres`) + session-backed service dep |
| `app/main.py` | modify | register the router |
| `tests/test_analytics_db.py` | add | attribution / windowing / skips / settings / no-seed / recurrence / tenant / 422 |

# Implementation slices

1. **Schema + service.** *Verify:* `make verify`.
2. **Router + main.** *Verify:* `make verify` + `alembic check` (no migration).
3. **Tests.** *Verify:* full `make verify` green.

# Tests

- **attribution + rounding:** a null-sphere (work-time) event adds to `work.fact`; a sphered event
  adds to that exact-named sphere's `fact`; an event whose sphere is not one of the user's spheres is
  ignored; a fractional-hour total proves `work.fact` and `sphere.fact` are `round1`-rounded in the
  output (not raw aggregate floats).
- **windowing:** an event outside `[periodStart, periodEnd]` is excluded.
- **skips:** an event with no `end_time` and a zero/negative-duration event are skipped.
- **recurrence + moved override:** a recurring daily event contributes one duration per in-window
  occurrence (proving the `list_events` reuse); an occurrence an override moves to a date **outside**
  `[periodStart, periodEnd]` is **excluded** by the effective-date filter.
- **plan:** with settings present, `work.plan` uses `workingDaysInYear`/`workingHoursPerDay`; with
  none, 246/8; each sphere's `plan` is its `allocated_hours` prorated to the period.
- **no-seed:** after calling analytics for a fresh year, `time_budget_settings` has **no** new row and
  `time_budget_categories` is still empty.
- **validation:** missing or malformed `periodStart`/`periodEnd` → 422.
- **tenant isolation:** a second user's events/spheres never affect the caller's result.

# Error & rescue map

| failure mode | error | response |
|--------------|-------|----------|
| missing / malformed `periodStart`/`periodEnd` | FastAPI `date` validation | 422 |
| malformed `start_time`/`end_time` on a stored event | n/a — DB rows are normalized `"HH:MM"`; `end_time` None is skipped | — |
| no auth | `AuthRequiredError` | 401 |

# Review lenses (pre-answer)

- **Scope / strategy.** One read endpoint; zero new domain logic beyond the aggregation; no model,
  migration, or error code. Composition of a shipped service + two reads.
- **Architecture.** Tenant-scoped via the JWT; settings read is side-effect-free; durations via the
  ported `time_to_minutes`; half-up rounding matches the source.
- **Completeness.** Attribution, windowing, skips, recurrence, plan source, no-seed, validation, tenant
  isolation each map to a test.
- **Tests & verification.** `make verify` green; `alembic check` clean (no migration).

# Risks & migrations

- **No migration** — read-only over migrated tables; `alembic check` stays clean.
- **No-seed invariant** — using `select` (not `get_year`) is the load-bearing choice; pinned by the
  no-seed test.
- **Effective-date windowing** — the `event.date` post-filter is load-bearing (excludes
  override-moved occurrences and fixes the legacy current-month-default bug); pinned by the
  moved-override test.
- **Rounding parity** — `round1` half-up matches `Math.round`; Python's bankers' `round()` would
  differ on `.x5`.
- **No behavior change** to calendar/spheres/time-budget endpoints — only read.

# Scope check

- [x] Matches the task (one analytics read; heatmap/dashboard out; no model/migration).
- [x] Reviewable in one pass — schema + small service + thin router + tests.
- [x] Size smell: no model, no migration, no new error code.

# Out of scope

Heatmap (AI/client concept), dashboard (cohort MV handoff); the React UI; Google; ETL.
