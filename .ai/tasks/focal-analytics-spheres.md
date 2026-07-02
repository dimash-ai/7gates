# Goal

Port the focal **life-sphere analytics** endpoint (Phase 4): `GET /api/analytics/spheres` — plan-vs-fact
hours per life sphere over a period, composing recurrence-expanded events + life spheres + time-budget
settings. The "heatmap" and "dashboard" are **out of scope** (the heatmap is an AI/client analysis
concept with no REST endpoint; the dashboard needs the cohort materialized-view handoff). Legacy:
`routes.ts:5419`.

# Scope

- **`app/schemas/analytics.py`** — `SpheresAnalyticsRead` (`period{start,end,days}`,
  `work{plan,fact}`, `spheres: [{name, color, plan, fact}]`), camelCase, floats for plan/fact.
- **`app/services/analytics.py`** — `AnalyticsService.spheres(user_id, *, period_start, period_end)`:
  - Events via `CalendarService(self.session).list_events(user_id, start=period_start.isoformat(),
    end=period_end.isoformat(), today=period_end)` (recurrence-expanded + enriched, windowed) — no
    re-query.
  - Spheres via `select(LifeSphere).where(user_id).order_by(sort_order)`.
  - Settings via a **read-only** `select(TimeBudgetSettings).where(user_id, year=period_start.year)`
    (NOT `get_year` — analytics must not seed settings/categories); `working_days_in_year` /
    `working_hours_per_day` fall back to **246 / 8** when absent.
  - `days = (period_end - period_start).days + 1`; `work_plan = round1(working_days * working_hours /
    365 * days)`; per event with an `end_time`, `duration = (time_to_minutes(end) -
    time_to_minutes(start)) / 60` (skip `<= 0`); a **null** `sphere` → `work_fact`, else the matching
    sphere's fact (an unknown sphere name is dropped); each sphere's `plan = round1(allocated_hours *
    days / 365)`.
  - **`round1(x) = floor(x*10 + 0.5)/10`** (half-up) for parity with the legacy `Math.round(x*10)/10`.
- **`app/api/analytics.py`** — `/api/analytics` router; `GET /spheres` with required `periodStart` /
  `periodEnd` `date` query params (camelCase aliases). Registered in `app/main.py`.
- **Tests** — work vs sphere attribution, period windowing, skipped events, settings-present vs
  default plan, no-seed side effect, tenant isolation, missing/invalid date → 422.

# Decisions (design rulings to confirm at Gate 1)

- **`periodStart` / `periodEnd` are required `date` query params** → 422 on missing/invalid (the
  superapp convention; legacy 400). Tenant from the JWT `sub` (no `?userId=`).
- **Reuse `CalendarService.list_events`** (recurrence-expanded, windowed, enriched with `sphere`) — no
  re-implementation of event fetching.
- **The settings read is non-creating** — a plain `select`, never `get_year`, so hitting analytics for
  a fresh year does **not** seed settings + default categories.
- **Work / non-work split by null sphere** (faithful: a null `sphere` counts as work; a non-null
  matching sphere adds to that sphere; an unknown sphere name is ignored — matching the legacy
  `spheresFact[name] !== undefined` guard).
- **Half-up rounding to 1 decimal** (`round1`) for parity with the legacy `Math.round`.
- **No model/migration**; pure read; camelCase; validation-only errors (422). `today=period_end` is
  only the `get_date_range` fallback (start/end are always supplied), so it does not affect the result.

# Out of scope

- The heatmap (AI/client concept — no REST endpoint) and the dashboard (cohort MV handoff, blocked);
  the React UI; Google; ETL. No model/migration.

# Acceptance criteria

- [ ] `GET /api/analytics/spheres?periodStart=&periodEnd=` returns `{period, work, spheres}`; a missing
      or invalid `periodStart` / `periodEnd` → 422.
- [ ] A work-time event (null sphere) adds to `work.fact`; a sphered event adds to that sphere's
      `fact`; an event whose sphere isn't one of the user's spheres is ignored; an event outside
      `[periodStart, periodEnd]` is excluded; a non-positive-duration or `end_time`-less event is
      skipped.
- [ ] `work.plan` uses the user's settings (`workingDaysInYear` / `workingHoursPerDay`) when present,
      else 246 / 8; each sphere's `plan` is its `allocated_hours` prorated to the period
      (`* days / 365`); `days = (end - start) + 1`.
- [ ] Reading analytics for a year with **no** settings does **not** create a settings row or seed
      default categories.
- [ ] Tenant isolation; `make verify` green; `alembic check` clean (no migration).

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```
