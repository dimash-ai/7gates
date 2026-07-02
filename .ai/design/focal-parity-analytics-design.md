# Design — focal-parity slice 9: Analytics page parity

3-gate flow · slice 9 of the `focal-parity` epic. Branch `feat/focal-parity-analytics` → base
`feature/focal-migration`. **Frontend-only** — every gap is presentation-layer; the six
`*Analytics.ts` compute modules already return every number the missing UI consumes (verified by a
full old-vs-new gap audit). No server/API/schema/migration. No compute-module logic changes.

## Problem / intent

The new Analytics page ported the *charts and compute* faithfully but dropped six presentation
features old-focal (`apps/old-focal/client/src/pages/Analytics.tsx`) had. Close them for 100% parity:

1. **PDF export** — header button that exports the whole report to a PDF (one section-card per page).
2. **Per-section insight blocks** — the italic ⚠️/✅ insight sentences under Mission, Spheres,
   Projects, Products charts.
3. **Spheres summary cards + totals footer + work marker** — the two summary cards above the radar,
   the table `<tfoot>` totals row, and the `(💼)` marker on the work row.
4. **Per-metric help popovers** — the `HelpCircle` + popover hints on the budget/plan/fact metrics.
5. **Per-section collapse** — each section card collapses/expands via a header chevron.
6. **Products "Show all" reset link** — clears the parent-project filter from the empty state.

## Assumptions

- Compute parity is done and correct (the audit confirmed all six modules are 1:1 ports with tests);
  this slice reads their existing outputs only — it adds **no** field to any `*Analytics.ts` module.
- Client scoping is not security — analytics is read-only over the user's own data through the
  existing `useSpheresAnalyticsData` query; this slice adds no writes, no new queries, no calendarId
  surface. (The shared-calendar boundary is slice-2 backend RBAC/RLS; nothing here touches it.)
- The new app deliberately reordered sections and hoisted the period selector to one header control —
  that is kept as-is; parity here is feature-parity, not DOM-order parity.
- PDF export visual fidelity need not be pixel-identical to old-focal; "exports a readable,
  non-clipped multi-page report of the current period" is the bar.

## Approach

All changes live under `apps/focal/client/src/features/analytics/`. Reuse-first: the UI primitives
(`components/ui/{collapsible,popover}.tsx`), the export deps (`jspdf`, `html2canvas`), and the
`triggerDownload` helper (exported from `features/dashboard/dashboard.ts:198`, imported by
`DashboardPage` as `import { triggerDownload } from './dashboard'`) all already exist — nothing new
is installed.

### 1. PDF export (`AnalyticsPage.tsx` + new `analyticsExport.ts`)

- Add a `data-analytics-export` wrapper ref around the stacked sections, and a `Download`/`Loader2`
  export button in the `PageHeader` actions (alongside the period selector).
- New `analyticsExport.ts`: `exportAnalyticsPdf(root, { periodLabel, title })` — **lazy-import**
  `jspdf` + `html2canvas` (DashboardPage pattern, not top-level import), iterate the wrapper's
  `:scope > div` section cards, rasterize each card to its **own A4 page** (old-focal's one-card-per-page
  layout), prepend a rasterized title page (Cyrillic-safe via html2canvas) carrying the report title +
  period + export date, then `triggerDownload(blob, filename, 'application/pdf')` (reuse the
  `features/dashboard/dashboard.ts` helper). Filename `Focal_Analytics_<periodLabel>.pdf`
  (spaces → `_`). Before capture, temporarily relax `overflow:hidden`/ellipsis on descendants and pin
  card width so nothing clips; restore in a `finally`. Guard with an `isExporting` state (disables the
  button + spinner). All export-failure paths restore styles and clear `isExporting`.
- **Collapse interaction (explicit ordering):** the export handler (1) snapshots the current collapse
  map, (2) sets all sections expanded, (3) **awaits a commit/paint** (e.g. a `requestAnimationFrame`/
  double-rAF or a microtask after a flushed state set) so the now-expanded cards are in the DOM before
  html2canvas reads them, (4) runs the capture, (5) restores the snapshot collapse map and the relaxed
  styles in a single `finally`. (Collapse state lives on the page — see §5.)

### 2. Per-section insight blocks (Mission, Spheres, Projects, Products sections)

Each section computes its insight list locally from data it *already receives*, then renders an
italic block under its chart. Derivations port old-focal exactly:

- **Mission** (`MissionSection.tsx`): underplanning (`plan < budget*0.9` → diff), underperformance
  (`fact < plan*0.9 && plan>0` → diff), priorityShift (`budgetPercent - factPercent > 5`), else
  onTrack (when `totalFact>0`). Inputs already on the mission summary.
- **Spheres** (`SpheresSection.tsx`): deficitSpheres (rows `deficit && !isWork` → count+names),
  workOverload (work row `plan>0 && fact>plan*1.1` → percent), totalDeficit
  (`totalFact < totalPlan*0.75` → hours), else allGood. Reduces over the existing rows.
- **Projects** (`ProjectsSection.tsx`) and **Products** (`ProductsSection.tsx`): per-row, capped at 3
  — lagging (`budget>0 && fact<budget*0.8`), ahead (`fact>budget*1.1`), underplanned
  (`plan<budget*0.8`), else success. (Old-focal hardcoded these in Russian; this slice **i18n's
  them** in both locales — a parity-correct improvement, not a behaviour change.)

A tiny pure `analyticsInsights.ts` holds the four derivation functions (returning
`{ tone: 'warning'|'success'|'info', key, params }[]`) so each is unit-testable in isolation; the
sections map them through `t()`.

### 3. Spheres summary cards + totals footer + work marker (`SpheresSection.tsx`)

- Two cards above the radar: **Work** (💼) and **Life-spheres (N)** (🎯), each with 4 columns
  Budget / Plan(+planVsBudget%) / Fact(+factVsPlan%) / Percent, computed as old-focal
  (`planVsBudget=(plan-budget)/budget*100`, `factVsPlan=(fact-plan)/plan*100`,
  `percent=fact/plan*100`). **Coloring:** the signed `planVsBudget`/`factVsPlan` deltas use
  positive(green)/negative(red) sign coloring; the **completion percent** uses green ≥75 / red. Work
  card carries the budget/plan/fact help popovers (§4).
- Table `<tfoot>` totals row: summed budget/plan/fact, a diff cell (red `< totalPlan*0.75`, green ≥0,
  else yellow), a percent cell. Row label uses a new mirrored key `analytics.total` (the new app has
  **no** `common` namespace; existing total labels live under `focal.budgets.total` — add a dedicated
  analytics key rather than cross-referencing the budgets namespace).
- `(💼)` marker appended to the work row's name in the table body.
- All values are reduces over the `aggregateSpheres` rows already in the component.

### 4. Per-metric help popovers (Mission, Spheres, Energy, Projects, DeepWork sections)

Small local `MetricHint` wrapper (`HelpCircle` trigger + `Popover` content) placed next to the
budget/plan/fact (and DeepWork planned/completed/execution) labels. Hint text comes from i18n:
Mission `mission.hints.*` and Spheres `spheres.hints.*` are new keys; Energy/Projects/DeepWork hints
(inline RU/EN ternaries in old-focal) become new keys; Products' `budgetHint/planHint/factHint`
already exist and are reused. Pure presentational.

### 5. Per-section collapse (all six sections + `AnalyticsPage.tsx`)

Add a header chevron per section that toggles its `CardContent`. **Default expanded; not persisted**
(matches old-focal's plain `useState`). To let export force-expand (§1), the collapse booleans live
on `AnalyticsPage` and pass `collapsed`/`onToggleCollapsed` to each section (a thin, uniform prop
pair). New `expand`/`collapse` aria/title keys.

### 6. Products "Show all" reset link (`ProductsSection.tsx`)

In the empty state, when a parent filter is active and yields nothing, render a button that resets the
parent filter to `ALL_PARENTS`. New `products.showAll` key.

### i18n

New keys under `translation.focal.analytics.*` in BOTH `en.json` + `ru.json`:
`export`, PDF title strings; `mission.insights.{underplanning,underperformance,priorityShift,onTrack}`,
`mission.hints.{budget,plan,fact}`; `spheres.insights.{deficitSpheres,workOverload,totalDeficit,allGood}`,
`spheres.hints.{budget,plan,fact}`, `spheres.lifeSpheres`; `projects.insights.*`, `projects.hints.*`;
`products.insights.*`, `products.showAll`; `energy.hints.*`; `deepWork.hints.*`; `expand`, `collapse`;
`analytics.total` (the spheres totals-row label — new key, since the new app has no `common`
namespace). Every EN key mirrored in RU with a real translation.

## Out of scope / deferred

- No compute-module changes (no new fields, no new queries). If any insight needs a number the
  modules don't already return, **stop and flag** rather than adding compute logic in this slice.
- No period-over-period compare, drill-down, or persistence of collapse state (old-focal has none).
- Section DOM reordering to match old-focal (intentional new-app layout, kept).

## Acceptance criteria

1. **Export:** header shows an export button; clicking it produces a multi-page PDF (title page +
   one page per section) of the current period; button shows a spinner and is disabled mid-export;
   a collapsed section still appears in the PDF; on any failure the page styles/collapse state are
   restored and the button re-enables. No top-level jspdf/html2canvas import (lazy only).
2. **Insights:** Mission, Spheres, Projects, Products each render the correct insight sentence(s) for
   representative inputs (one warning case + the success/onTrack case each), all via i18n in both
   locales; thresholds match old-focal exactly.
3. **Spheres summaries:** Work + Life-spheres cards show the 4 columns with correct
   planVsBudget/factVsPlan/percent math and green/red coloring; the table `<tfoot>` shows correct
   summed totals + diff/percent coloring; the work row shows the 💼 marker.
4. **Popovers:** budget/plan/fact (and DeepWork tiles) expose a HelpCircle popover with localized hint
   text; opening one shows the hint; no hardcoded strings.
5. **Collapse:** each section toggles open/closed from its header chevron; default expanded; toggling
   one does not affect others.
6. **Products reset:** with a parent filter active and no products, the "Show all" link clears the
   filter and the full list returns.
7. **i18n parity:** every new EN key has an RU counterpart (no missing-key fallbacks); no user-facing
   hardcoded text.
8. **Green bar:** `pnpm typecheck`, `pnpm lint`, `pnpm test:run` (new tests for the insight
   derivations, the spheres totals/marker, collapse toggle, export-button disabled/restore flow, and
   the products reset), `pnpm build` all pass. Diff is surgical and confined to
   `features/analytics/*` + the two locale files.

## Risk

Low–Medium. All frontend, no compute/data/schema. The only non-trivial mechanics are the PDF export
(mitigated by reusing the proven DashboardPage lazy-import + `triggerDownload` pattern and restoring
styles in `finally`) and the breadth of i18n keys (mitigated by a parity checklist asserting EN↔RU
key symmetry in the test). Rollback = revert the client files.
