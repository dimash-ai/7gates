# Problem

First sub-slice of the analytics epic: rebuild the **Spheres web** section to old-focal parity, and
in doing so land the **shared analytics scaffold** (period selector + recharts) the other five
sections reuse. Today's `AnalyticsPage.tsx` shows spheres as horizontal **plan/fact bars** for a
single month; old-focal's section (`Analytics.tsx` ~617–853 compute, ~2595–2847 render) is a
**radar/spider chart** (log radius; budget/plan/fact for "work" + each sphere), a **12-month area
trend** (avg completion %), and a **sortable table**, under a **month/quarter/year** period selector.

**Critical data-semantics finding (gate-1 review):** the new `/api/analytics/spheres` endpoint does
**not** reproduce old-focal's numbers, so this section must **not** be built on it. old-focal computes:
- **plan** = sum of *all* calendar-event durations in the period, grouped by `event.sphere`
  (`Analytics.tsx:627`); **fact** = sum of durations of **completed** events only
  (`event.completed`, `:634`);
- **work budget** = root work projects' `allocatedWorkHours` (`:649`); **sphere budget** = sphere
  `allocated_hours`, each scaled to the period.

The new backend service instead derives `plan` from time-budget settings / sphere allocated hours
(`services/analytics.py:64,89`) and its `fact` loop is **not** gated by completion (`:70`). So to
match old-focal exactly this section is computed **client-side from `/api/events` + `/api/projects` +
`/api/spheres`** (как old-focal), reproducing its plan/fact/budget formulas — all backed; the
existing `/api/analytics/spheres` wrapper is simply not this section's source.

# Assumptions

- **[confirmed — fs]** recharts `^3.8.1` is in `apps/focal/client/package.json`; typed wrappers exist:
  `api/events.ts`, `api/projects.ts`, `api/spheres.ts`, `api/timeBudgets.ts`, `api/analytics.ts`.
  `EnrichedEventRead` carries `sphere`, `completed`/`completed_at`, and the duration inputs needed to
  reproduce old-focal's plan/fact; `ProjectRead` carries `is_work_time` + `allocated_work_hours`;
  `SphereRead` carries `allocated_hours`. No new dependency.
- **[confirmed — gate-1 review]** `/api/analytics/spheres` semantics differ from old-focal (plan from
  budget settings not events `:64`; fact not gated by `completed` `:70`), so the radar/table values
  come from **client-side event aggregation**, not that endpoint. **Budgets scale by calendar-days/365**
  of the annual project/sphere `allocated_hours` (old-focal `:645-663`) — **no** time-budget settings
  are involved in this section.
- **[confirmed — fs]** Current `AnalyticsPage.tsx` (219 lines) drives a month picker + `PlanFactBars`;
  `AnalyticsPage.test.ts` covers pure helpers `barWidth`/`factShare`. The shell foundation (slice 0)
  is present (worktree off `afaaeba`), so tokens/PageHeader are available.
- **[confirmed — Explore + old-focal]** old-focal Spheres section = `RadarChart` (budget/plan/fact, log
  radius), `AreaChart` (12-month avg completion %), sortable table (budget/plan/fact/diff/percent,
  deficit at fact < 75% plan); period selector month/quarter/year (`:173`) + prev/next.
- **[confirmed — contract]** `/api/events` accepts a period range, so quarter/year are just wider
  pulls; the 12-month trend reads the year's events once and aggregates client-side per month.
- **[unverified — settle at design gate]** the exact old-focal plan/fact/budget formulas + period
  divisor (read `Analytics.tsx:617-853` in full at design); recharts v3 `RadarChart` log-radius wiring;
  the table sort columns + deficit threshold; whether `PlanFactBars` is removed with the bars.

# Options considered

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Full Spheres section computed client-side from events, + shared scaffold (chosen)** | Reproduce old-focal's client-side plan/fact/budget from `/api/events`+`/api/projects`+`/api/spheres`; render radar + 12-mo trend + sortable table; land the month/quarter/year period selector + recharts wiring, replacing the bars. | Exact old-focal values **and** look; lands the scaffold the other 5 sections reuse; frontend-only, all backed. | Largest single sub-slice; we own the event aggregation + radar/budget/trend logic (порт old-focal's). |
| **B — Use `/api/analytics/spheres` as-is** | Keep today's endpoint, just restyle to radar. | Less client code. | **Wrong numbers** — endpoint semantics differ from old-focal (plan/fact), so not parity. Rejected. |
| **C — Radar only, defer trend + table** | Just the radar now. | Smaller. | Not "exact old-focal" for the section; splits one cohesive section. Rejected. |

# Recommendation

**Option A** — reproduce old-focal's Spheres section by porting its **client-side computation** over
`/api/events` + `/api/projects` + `/api/spheres`, then render radar + 12-month trend + sortable table
with recharts themed to the foundation tokens, under the shared month/quarter/year period selector.
This is the only option that matches old-focal's **values**, not just its chart shapes. Budgets =
annual project/sphere `allocated_hours` × (period calendar-days / 365); no time-budget settings.

Plan shape (settled at gate 2, after reading `Analytics.tsx:617-853` in full at design): (1) shared
period selector (month/quarter/year + prev/next) + period→range helper; (2) data hooks — events
(period + the year for trend), projects, spheres; (3) port old-focal's
plan/fact/budget aggregation per sphere + "work"; (4) recharts `RadarChart` (log radius, 3 series)
themed to tokens; (5) `AreaChart` 12-month trend; (6) sortable table + deficit flag; (7) remove the
bars + migrate their tests to the new aggregation helpers; i18next ru+en; light+dark.

# Out of scope

- The other 5 sections + PDF export; any server/API/schema change; other pages.

# Open questions

- **`/api/analytics/spheres` fate:** this section no longer uses it; leave the endpoint + wrapper in
  place (may serve other callers) — do not delete backend in a frontend sub-slice. Confirm at design.
- **Trend source:** one yearly `/api/events` pull + client aggregation (assumed) vs heavier
  alternatives — decided at the design gate on a perf basis.
- **Period selector home:** built here but as a reusable component (the epic scaffold), not
  spheres-private.

# Success criteria

- [ ] `pnpm lint && typecheck && test:run && build` green in the worktree.
- [ ] Spheres section matches old-focal in **values and look**: radar (budget/plan/fact log-scale, from
      client-side event aggregation), 12-month trend, sortable table, month/quarter/year selector,
      light + dark, by screenshot.
- [ ] No server/API change; i18next ru+en; surgical diff (analytics feature + tests; recharts already
      a dep); the period selector is reusable by later sub-slices.
