# Goal

Sub-slice 1 of the `focal-redesign-analytics` epic — the **Spheres web** section, and the **shared
analytics scaffold** every later section reuses. Replace today's spheres "plan/fact bars" view
(`features/analytics/AnalyticsPage.tsx`) with old-focal's **Паутинка сфер жизни** section: a
**radar/spider chart** (log scale; budget vs plan vs fact for "work" + each life sphere), a
**12-month area trend** (average completion %), and a **sortable table** — plus the shared
**period selector** (month / quarter / year + prev/next) and the **recharts** wiring. Frontend-only,
over the existing APIs.

> Binding visual contract = old-focal `apps/old-focal/client/src/pages/Analytics.tsx` Spheres section
> (computation ~617–853, render ~2595–2847). Behavioral/data base = the new app's typed `api/*`.
> Worktree `.worktrees/focal-redesign-analytics`, branch `feat/focal-redesign-analytics` (off `afaaeba`).

# Scope

- **Period selector (shared scaffold):** month / quarter / year toggle + prev/next, replacing today's
  month-only picker. `/api/events` takes a period range, so quarter/year are just wider pulls.
- **Radar/spider chart (recharts `RadarChart`, log radius):** axes = "work" + each life sphere; three
  series = budget, plan, fact, all computed **client-side по old-focal** — `/api/analytics/spheres`
  has different plan/fact semantics and is NOT this section's source. plan = all event durations in
  the period by `event.sphere`; fact = **completed** events only; work budget = root work projects'
  `allocated_work_hours`, sphere budget = sphere `allocated_hours`, scaled by (period calendar-days /
  365) — no time-budget settings (old-focal `:627,634,645-663`). Inputs: `api/events.ts` +
  `api/projects.ts` + `api/spheres.ts`.
- **12-month area trend (recharts `AreaChart`):** average completion % (fact/plan) per month over the
  year — client-side aggregation over `/api/events` (or 12 period-scoped analytics reads; decided at
  design).
- **Sortable table:** per sphere — budget / plan / fact / diff / percent, sortable; deficit flag
  (fact < 75% of plan), как old-focal `:671,782-797`.
- recharts (`^3.8.1`, already installed) themed to the foundation tokens; i18next ru + en for all new
  strings; light + dark.

# Out of scope

- The other 5 analytics sections (their own sub-slices) and **PDF export**.
- Any **server / API / schema** change — spheres plan/fact + sphere budgets + events are all backed.
- The current `AnalyticsPage.test.ts` helpers (`barWidth`/`factShare`) stay unless the bars they back
  are removed — then their tests move with them.

# Acceptance criteria

- [ ] `cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics && pnpm lint &&
      pnpm typecheck && pnpm test:run && pnpm build` green.
- [ ] The Spheres section matches old-focal: radar (budget/plan/fact, log scale), 12-month trend, and
      sortable table, with the month/quarter/year period selector — in light + dark.
- [ ] Data matches old-focal: plan/fact/budget computed client-side from events + projects + spheres
      (NOT `/api/analytics/spheres`), trend from events; no server/API change; i18next ru + en;
      surgical diff (the analytics feature + its tests; recharts already a dep).

# Verification commands

```sh
cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```
