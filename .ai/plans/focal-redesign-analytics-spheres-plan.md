# Summary

Implement `focal-redesign-analytics-spheres` in the redesign worktree as a frontend-only port of
old-focal's Spheres section. Replace the current month-only plan/fact bars and
`/api/analytics/spheres` query with a shared month/quarter/year period selector, client-side data
hooks over `/api/events`, `/api/projects`, and `/api/spheres`, old-focal-compatible aggregation,
a log-scaled Recharts radar, a 12-month completion trend, and a sortable budget/plan/fact table.

The load-bearing data decision: **do not use** `getSpheresAnalytics`, `/api/analytics/spheres`, or
time-budget settings for this section. Plan is all event duration in the selected period, fact is
completed-event duration only, and budgets are annual project/sphere allocated hours prorated as
`Math.round(annualHours * (periodDays / 365))`. The generated client exposes these fields as
camelCase: `event.sphere`, `event.completed`, `project.isWorkTime`, `project.parentProjectId`,
`project.allocatedWorkHours`, and `sphere.allocatedHours`.

# Files to change

| path | change | why |
|------|--------|-----|
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics/apps/focal/client/src/features/analytics/analyticsPeriods.ts` | Add shared `PeriodType`, inclusive date-range, ISO date, label, shift, and day-count helpers. | Later analytics sections reuse month/quarter/year selection; testing date math separately prevents UI regressions. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics/apps/focal/client/src/features/analytics/PeriodSelector.tsx` | Add a small reusable selector with month/quarter/year `Select`, previous/next icon buttons, and current period label. | Replaces the current month-only controls and becomes the shared scaffold for later sub-slices. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics/apps/focal/client/src/features/analytics/spheresAnalytics.ts` | Add pure helpers for event duration, period aggregation, radar log values, 12-month trend data, sort toggling/sorting, totals, and display-row types. | Ports old-focal's computation out of the component and gives the risky semantics direct unit coverage. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics/apps/focal/client/src/features/analytics/useSpheresAnalyticsData.ts` | Add a local hook wrapping React Query calls to `listEvents(period)`, `listEvents(year)`, `listProjects`, and `listSpheres`. | Keeps data fetching explicit, uses existing API wrappers, and avoids the incorrect analytics endpoint. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics/apps/focal/client/src/features/analytics/AnalyticsPage.tsx` | Replace the bar UI with the period selector, loading/error/empty states, radar, trend, summary metrics, and sortable table; remove `PlanFactBars`, `barWidth`, `factShare`, `getSpheresAnalytics`, and `SphereAnalytics` usage. | This is the binding Spheres page surface. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics/apps/focal/client/src/features/analytics/AnalyticsPage.test.ts` | Replace bar-helper tests with helper and focused page tests for period ranges, aggregation, radar/trend data, sorting, and endpoint usage. | Existing tests prove removed behavior; new tests must pin the old-focal parity behavior. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics/apps/focal/client/src/i18n/locales/en.json` | Add/replace `translation.focal.analytics` strings for period selector, chart labels, table columns, trend labels, empty/loading/error text, and accessible labels. | New user-facing strings must be localized. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics/apps/focal/client/src/i18n/locales/ru.json` | Add the same keys in Russian. | Keeps both supported locales complete. |

# Implementation slices

1. **Period selector + helpers.**
   - Add `analyticsPeriods.ts` with native-Date helpers only: `getPeriodRange(anchor, type)`,
     `shiftPeriod(anchor, type, delta)`, `toIsoDate(date)`, `inclusiveDays(start, end)`, and
     `formatPeriodLabel(anchor, type, locale)`.
   - Add `PeriodSelector.tsx` using existing `Button` and `Select` UI components, with icon-only
     prev/next buttons and localized accessible labels.
   - Wire `AnalyticsPage` to the new period state, but keep the old bars temporarily so the page
     remains reviewable before data semantics change.
   - Verify with focused helper tests and typecheck.

2. **Data hooks over existing APIs.**
   - Add `useSpheresAnalyticsData(periodRange, anchorYear)` using query keys
     `['analytics', 'spheres', 'events', startIso, endIso]`,
     `['analytics', 'spheres', 'trend-events', year]`, `['projects']`, and `['spheres']`.
   - Call `listEvents(periodStartIso, periodEndIso)`, `listEvents(year-01-01, year-12-31)`,
     `listProjects()`, and `listSpheres()`.
   - Do not import `getSpheresAnalytics` and do not change `src/api/{events,projects,spheres,analytics}.ts`.
   - Combine loading/error states in one hook result so `AnalyticsPage` has one predictable data
     branch.

3. **Plan/fact/budget aggregation port.**
   - In `spheresAnalytics.ts`, compute event duration from `startTime`/`endTime` in hours; skip null,
     malformed, zero, or negative durations without throwing.
   - Period plan/fact: `!event.sphere` contributes to the work row; `event.sphere` contributes to
     the matching current sphere by exact name; only `event.completed === true` contributes to fact.
   - Work budget: sum root work projects where `project.isWorkTime` is truthy and
     `!project.parentProjectId`, using `project.allocatedWorkHours ?? 0`, then prorate by
     `periodDays / 365`.
   - Sphere budget: each current sphere uses `sphere.allocatedHours`, prorated by `periodDays / 365`.
   - Rows: Work first, then spheres sorted by budget descending; `percent = plan > 0 ? round(fact /
     plan * 100) : fact > 0 ? 100 : 0`; `deficit = plan > 0 && fact < plan * 0.75`.
   - Unknown sphere names from events must not create rows; they may still count in the yearly trend
     total because old-focal's trend uses all events.

4. **Radar chart.**
   - Add Recharts `ResponsiveContainer`, `RadarChart`, `PolarGrid`, `PolarAngleAxis`,
     `PolarRadiusAxis`, `Radar`, and `Tooltip` to `AnalyticsPage`.
   - Feed it helper output with `budget`, `plan`, and `fact` transformed by
     `Math.log10(value + 1) * 100`, plus raw values for tooltip display.
   - Use design tokens/classes for card, text, grid, and muted colors; keep the old-focal series
     distinction: budget muted/dashed, plan blue, fact primary/accent.
   - Render a localized empty state if there is no chartable row data.

5. **12-month trend.**
   - Build trend rows from the yearly events query for the selected anchor year.
   - For each month, plan is all valid event duration, fact is completed valid event duration, and
     `avgPercent = plan > 0 ? round(fact / plan * 100) : 0`.
   - For future months in the current calendar year, return `avgPercent: null`, `hasData: false`,
     and keep `connectNulls={false}` in the chart.
   - Render Recharts `AreaChart` with 0-100 Y domain, 100% and 75% reference lines, localized
     tooltip text, and a compact legend.

6. **Sortable table.**
   - Add sort state to `AnalyticsPage`: `field: 'budget' | 'plan' | 'fact' | 'diff' | 'percent' |
     null`, `direction: 'desc' | 'asc'`, defaulting to `null` + `desc`.
   - Match old-focal's cycle: clicking a new column sets `desc`; clicking the same column changes
     `desc -> asc -> none`.
   - Render the existing UI `Table` primitives or a plain semantic table with sortable header
     buttons, rows for work + spheres, colored dots, budget/plan/fact hours, diff, percent, deficit
     coloring, and a totals footer.
   - Keep the table horizontally usable on narrow screens with overflow rather than shrinking text
     into overlap.

7. **Remove old bars + complete tests.**
   - Delete `PlanFactBars`, `barWidth`, `factShare`, the `SphereAnalytics` card renderer, and the
     `getSpheresAnalytics` import from `AnalyticsPage.tsx`.
   - Replace `AnalyticsPage.test.ts` with tests for the new helper contracts and a focused page
     smoke test that mocks API modules and Recharts if Happy DOM cannot measure responsive charts.
   - Confirm no references remain to `/api/analytics/spheres` from the analytics page.
   - Run the required client verification commands in the worktree.

# Tests

- `getPeriodRange returns inclusive month, quarter, and year ranges`: proves the selector sends the
  correct API windows and labels for all supported period types.
- `shiftPeriod moves by the selected period type`: proves prev/next does not keep month-only
  behavior after switching to quarter or year.
- `inclusiveDays is used for budget proration`: proves budgets are scaled by calendar days over 365,
  including multi-month periods.
- `aggregateSpheres rows match old-focal attribution`: proves null/empty `event.sphere` goes to
  work, named sphere events go to that sphere, unknown sphere names do not create rows, and Work
  stays first.
- `aggregateSpheres gates fact by completed`: proves incomplete events affect plan only and completed
  events affect both plan and fact.
- `aggregateSpheres uses annual allocated hours, not time budgets`: proves work budget comes from
  root `isWorkTime` projects' `allocatedWorkHours`, sphere budget comes from `allocatedHours`, and
  child projects are excluded from work budget.
- `aggregateSpheres rounds budget, plan, fact, percent, and deficit like old-focal`: proves row
  numbers, `percent`, and the `fact < 75% of plan` flag.
- `invalid event durations are skipped`: proves null `endTime`, malformed times, zero duration, and
  negative duration do not crash or pollute totals.
- `toRadarData log-scales chart values but preserves raw tooltip values`: proves the chart can
  smooth large scale differences while tooltips show real hours.
- `buildSpheresTrend creates 12 monthly rows`: proves each month uses fact/plan from events, future
  months in the current year are null, and past selected years keep all months populated.
- `sortSpheresRows follows none-desc-asc-none behavior`: proves sortable columns and default
  old-focal order.
- `AnalyticsPage fetches events/projects/spheres and not analytics/spheres`: proves the component
  calls `listEvents`, `listProjects`, and `listSpheres`, renders chart/table labels from mocked
  aggregates, and has no dependency on `getSpheresAnalytics`.
- `AnalyticsPage shows loading, error, and empty states`: proves all query unhappy paths produce
  localized UI instead of partial broken charts.

Verification command for the final slice:

```sh
cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-analytics
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `analytics.events.period.loadFailed` | `listEvents(periodStart, periodEnd)` rejects through React Query | `useSpheresAnalyticsData` exposes combined `isError`; `AnalyticsPage` error branch | Localized `focal.analytics.errors.load`; no stale bars or partial charts render. |
| `analytics.events.trend.loadFailed` | `listEvents(yearStart, yearEnd)` rejects through React Query | same combined query error branch | Same localized load error for the Spheres section; table/radar are withheld because the section cannot fully match old-focal. |
| `analytics.projects.loadFailed` | `listProjects()` rejects through React Query | same combined query error branch | Same localized load error; no budget values are guessed. |
| `analytics.spheres.loadFailed` | `listSpheres()` rejects through React Query | same combined query error branch | Same localized load error; no sphere rows are guessed. |
| `analytics.emptySpheres` | None; `listSpheres()` succeeds with an empty array | normal render branch | Work row can render if events/projects exist; the sphere chart/table area shows localized empty copy for life spheres. |
| `analytics.duration.unusable` | None; helper returns `null`/skips for null, malformed, zero, or negative event duration | `durationHours` inside `spheresAnalytics.ts` | No visible error; that event is omitted from totals, pinned by unit tests. |
| `analytics.unknownSphereName` | None; event carries a sphere name not present in current `listSpheres()` | aggregation helper | No extra row is created; the event still contributes to the all-events 12-month trend, matching old-focal trend semantics. |
| `analytics.noPlanForPercent` | None; row has `plan === 0` | aggregation helper percent formula | Percent displays `0%` unless fact exists, in which case it displays `100%`, matching old-focal's defensive formula. |
| `analytics.rechartsTestLayout` | Happy DOM lacks real `ResponsiveContainer` dimensions | component test mock for Recharts only | Tests assert page wiring/labels while pure helper tests prove chart data; production build still uses real Recharts. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** - This is the minimum viable Spheres parity slice: one analytics page section,
  local shared period scaffold, pure helper module, local data hook, tests, and locale keys. It
  explicitly leaves server/API/schema changes and other analytics sections out. The decision is
  reversible by reverting the listed frontend files.
- **Architecture** - Data flows from existing typed API wrappers into a local query hook, then through
  pure aggregation helpers, then into presentational Recharts/table UI. The wrong endpoint remains in
  `src/api/analytics.ts` for other callers but is not imported by this section. Unhappy paths are
  query errors, empty successful data, or skipped unusable event durations; none require a new global
  state or backend contract.
- **Design** - The page keeps the existing Focal card/tokens style, uses familiar icon buttons for
  period navigation, uses a `Select` for period type, and keeps chart/table text compact without
  overlap. Loading, error, no-spheres, no-chart-data, light, dark, desktop, and narrow-width table
  states are explicit.
- **DevEx** - No new dependency, no generated client change, no API wrapper change, and no broad
  analytics abstraction beyond the period selector/helpers the next sections need. Pure tests carry
  the complex math so future section work can reuse and review it cheaply.

# Risks & migrations

- No database migrations, server changes, API schema changes, generated client changes, environment
  variables, or data backfills.
- Main data risk: accidentally using `/api/analytics/spheres` or time-budget settings would produce
  wrong old-focal values. Rescue: remove the import from `AnalyticsPage.tsx`, keep API wrappers
  unchanged, and pin endpoint usage in tests.
- Date risk: inclusive ranges and `periodDays / 365` proration are easy to drift. Rescue: unit-test
  month, quarter, year, and leap-year day counts against expected budget values.
- Recharts risk: responsive chart components are brittle in unit DOM tests. Rescue: unit-test chart
  data helpers and mock only the Recharts components in the page smoke test if needed; the final
  build still imports real Recharts.
- Visual risk: radar labels and the table can crowd on mobile. Rescue: use fixed chart heights,
  compact labels, and table overflow, then verify manually in light and dark after the build.
- Rollback plan: revert the listed client files; no persisted data or backend contract changes are
  introduced.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting because the work is contained to the analytics feature,
      locale files, and tests.
- [x] Size smell addressed: this is a substantial page replacement, but the complexity is split into
      period helpers, a data hook, pure aggregation helpers, and three render slices. No unrelated
      pages, APIs, or backend services are touched.

# Out of scope

- The other five analytics sections and PDF export.
- Any server, API, schema, generated OpenAPI, migration, or time-budget-settings change.
- Deleting `src/api/analytics.ts` or the backend `/api/analytics/spheres` endpoint; this section just
  stops using them.
- Reworking the app shell, auth, calendar filters, projects/spheres CRUD pages, or unrelated
  analytics endpoint semantics.
