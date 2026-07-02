# Summary

Bring the new Focal habits page to old-focal visual parity by splitting the current journal-only `HabitsPage` into a small page controller plus local habits components: a shared-shell `PageHeader`, two tabs, an old-focal-style create dialog, a reskinned journal, and a stats-backed charts tab. The key implementation decision is to keep all data on the existing Focal client API surface: add the missing typed wrapper for `GET /api/habit-entries/stats`, reuse existing `listHabits` / `listEntries` / `listStreaks` / mutations, and make any screenshot-only value that is not backed by the current `yes/no/skip` entry model visibly absent rather than faked.

# Files to change

| path | change | why |
|------|--------|-----|
| `/Users/allosta/Desktop/superapp-habits-wt/apps/focal/client/src/api/habits.ts` | Add `HabitEntryStat` / `HabitStatsGranularity` types and `listHabitEntryStats(start, end, granularity)` for `/api/habit-entries/stats`. Keep existing wrappers and query semantics unchanged. | The generated OpenAPI schema already exposes the stats endpoint, but the client feature has no typed wrapper for chart data. |
| `/Users/allosta/Desktop/superapp-habits-wt/apps/focal/client/src/api/habits.test.ts` | Add API wrapper tests for the stats endpoint and any existing habits wrappers touched while editing. | Proves the new wrapper calls the backed route with `start`, `end`, and `granularity` query params instead of hardcoding chart data in UI tests. |
| `/Users/allosta/Desktop/superapp-habits-wt/apps/focal/client/src/features/habits/HabitsPage.tsx` | Turn the file into the page controller: `PageHeader`, Add button, `Tabs`, shared query/mutation wiring, create-dialog state, and error banner. Move journal/charts rendering into local components. | Keeps the route surface stable while making the two-tab page reviewable. |
| `/Users/allosta/Desktop/superapp-habits-wt/apps/focal/client/src/features/habits/HabitCreateDialog.tsx` | Add a dialog styled after old-focal's create dialog, using current `createHabit` payload semantics: name, color swatches, type, frequency, and weekly target days. | Replaces the inline create card with the old-focal header/Add-dialog pattern without expanding creation behavior beyond the current habits flow. |
| `/Users/allosta/Desktop/superapp-habits-wt/apps/focal/client/src/features/habits/HabitJournal.tsx` | Add the old-focal-style journal view: week navigator, day strip, habit rows, status cells, streak text, archive section, and current reorder controls. | This is the visual reskin of the existing journal behavior. |
| `/Users/allosta/Desktop/superapp-habits-wt/apps/focal/client/src/features/habits/HabitCharts.tsx` | Add the charts tab using Recharts, stats period controls, completion-rate lines, summary table, and a status matrix only from existing habit entries. | Ports the missing charts tab over backed data. |
| `/Users/allosta/Desktop/superapp-habits-wt/apps/focal/client/src/features/habits/habitChartUtils.ts` | Add pure date/period/bucket helpers derived from old-focal's `habitChartUtils`, plus aggregation helpers for rates and matrix rows. | Keeps date math and chart data shaping testable outside Recharts. |
| `/Users/allosta/Desktop/superapp-habits-wt/apps/focal/client/src/features/habits/habitChartUtils.test.ts` | Add focused unit tests for month-end period math, labels, empty buckets, completion rates, habit filtering, and matrix row shaping. | Proves the non-visual chart logic without brittle SVG assertions. |
| `/Users/allosta/Desktop/superapp-habits-wt/apps/focal/client/src/features/habits/HabitsPage.test.tsx` | Update existing page tests for the dialog, tabs, journal controls, chart query flow, and preserved mutations. Mock Recharts only where needed; assert visible behavior and data calls, not SVG internals. | Existing tests cover the current journal; they need to prove the new shell and charts still preserve behavior. |
| `/Users/allosta/Desktop/superapp-habits-wt/apps/focal/client/src/i18n/locales/en.json` | Extend `translation.focal.habits` with old-focal journal/charts/dialog labels, period labels, matrix legend, chart errors, and accessible labels. | No visible or accessible string should be hardcoded. |
| `/Users/allosta/Desktop/superapp-habits-wt/apps/focal/client/src/i18n/locales/ru.json` | Add the same keys in Russian, reusing old-focal copy where it matches the new key structure. | RU and EN are equal first-class locales. |

No `package.json` or lockfile change is planned because `recharts` is already installed in the target client. No generated OpenAPI or backend file should change.

# Implementation slices

1. Add the stats wrapper, locale keys, and pure chart utilities.
   - In `api/habits.ts`, add `HabitEntryStat = Schemas['HabitEntryStatRead']`, `HabitStatsGranularity = 'day' | 'month'`, and `listHabitEntryStats(start, end, granularity = 'month')`.
   - Add `api/habits.test.ts` coverage that the wrapper calls `/api/habit-entries/stats?start=...&end=...&granularity=...` with the normal auth/header behavior.
   - Add `habitChartUtils.ts` with local-date formatting, month-clamped period subtraction, period config, empty bucket initialization, rate calculation, and matrix row shaping. Use the generated `Habit`, `HabitEntry`, and `HabitEntryStat` types at the boundary.
   - Add `habitChartUtils.test.ts` before any chart UI uses the helpers.
   - Add locale keys consumed by later slices. Build should stay green because the page can still use its current UI.

2. Convert the page shell and create flow without changing journal behavior.
   - Replace the bespoke header with `PageHeader icon={Repeat}` and `rightActions` containing an old-focal-style Add habit button. `PageHeader` keeps the shared toolbar; do not add a second AI button.
   - Add Radix/shadcn `Tabs` with `journal` and `charts`, initially wiring the journal tab to the existing journal markup or a behavior-preserving `HabitJournal` extraction and the charts tab to a localized empty/loading placeholder.
   - Extract the inline create form into `HabitCreateDialog`. On successful create, keep the current payload shape and invalidation: reset dialog draft, close, clear `errorMessage`, and invalidate `['habits']`.
   - Preserve existing mutation error handling so failed create leaves the draft available.
   - Update page tests for header title, Add button opening the dialog, dialog create payload, blank-name guard, and tab switching.

3. Reskin the journal over existing behavior.
   - Move active/archived habit rendering into `HabitJournal.tsx`.
   - Add `anchorDate` and `selectedDate` state for the old-focal 7-day navigator. Query `listEntries(weekStart, weekEnd)` from the visible week, not a hardcoded today-ending range.
   - Render old-focal-style date buttons, today highlight, selected day highlight, compact habit rows, color dots, streak copy, and status cells. Use existing status cycle `none -> yes -> no -> skip -> none`.
   - Preserve current behavior instead of transliterating old-focal's full 888-line journal: keep up/down reorder buttons rather than adding `dnd-kit`; keep archive/restore/delete; do not add notes or edit-habit flows.
   - Disable future-date cells when the navigator moves beyond today; old-focal did this and the current page never offered future toggles.
   - Keep archived habits collapsed behind an old-focal-style archive control, backed by the existing archived query.
   - Update tests for week navigation query params, selected/today rendering, status cycling, future-cell disabled behavior, archive/restore/delete, and reorder.

4. Port the charts tab over backed data.
   - Add `HabitCharts.tsx` with period buttons matching the design screenshots (`month`, `3m`, `6m`, `year`) and old-focal period math: day granularity for month, month granularity for longer periods.
   - Query active habits through `listHabits(false)` and chart stats through `listHabitEntryStats(periodStart, periodEnd, granularity)`.
   - Build one completion-rate line per habit plus an average line from stats buckets. Use habit colors with token fallbacks; use Recharts `ResponsiveContainer` and line/axis/tooltip components.
   - Add a stats summary table from the same rows so tests and users have a non-SVG representation of yes/no/rate.
   - Add the screenshot matrix as a status matrix only: query `listEntries(matrixStart, matrixEnd)`, render `yes/no/skip/empty` cells by habit and day, and show totals/rates. Do not fabricate numeric partial values because `HabitEntryRead` exposes only `status`, not quantity.
   - Add explicit loading, empty, and load-error states for stats and matrix data. A stats error must not break the journal tab.
   - Update page/chart tests to prove chart tab calls the stats wrapper, period changes switch query range/granularity, habit rows and rates render, empty stats render a zero/empty state, and matrix cells map existing entries.

5. Final parity polish and verification.
   - Compare light and dark screenshots against `/Users/allosta/Desktop/allosta/superapp/apps/old-focal/client/src/pages/Habits.tsx`, `components/habits/*`, and `design/focal/screenshots/habits-{chart,chart-year,matrix}.png`.
   - Keep visual fixes scoped to the planned habits files and locale keys. Do not edit shell tokens, shared `PageHeader`, shadcn primitives, or backend files.
   - Run the focused tests first, then the full required client checks:
     `cd /Users/allosta/Desktop/superapp-habits-wt/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Tests

- `api/habits.test.ts`: `listHabitEntryStats` calls `/api/habit-entries/stats` with `start`, `end`, and `granularity`; proves the chart tab is backed by the existing OpenAPI route.
- `habitChartUtils.test.ts`: month-end subtraction clamps correctly; proves date ranges do not roll into the wrong month.
- `habitChartUtils.test.ts`: day/month bucket initialization fills missing periods with zeroes; proves sparse server stats still render stable charts.
- `habitChartUtils.test.ts`: label formatting uses supplied month/weekday names; proves RU/EN labels are data-driven and testable.
- `habitChartUtils.test.ts`: completion rates ignore `skip` in the denominator and handle zero yes/no totals as `0%`; proves chart percentages match old-focal logic.
- `habitChartUtils.test.ts`: habit filtering and average-line aggregation use only selected/backed stats; proves the chart does not invent rows.
- `habitChartUtils.test.ts`: matrix row shaping maps `yes`, `no`, `skip`, and missing entries into the expected cell states; proves the matrix is status-backed.
- `HabitsPage.test.tsx`: renders `PageHeader`, the two tabs, and the shared toolbar; proves the page moved onto the shell foundation without losing page controls.
- `HabitsPage.test.tsx`: Add habit opens the dialog, submits the same current create payload, closes on success, and invalidates/refetches; proves create flow is preserved despite the visual move from inline card to dialog.
- `HabitsPage.test.tsx`: blank habit name cannot submit; proves the dialog guards local invalid input before calling `createHabit`.
- `HabitsPage.test.tsx`: journal renders habits with streaks and visible week cells; proves existing `listHabits`, `listStreaks`, and `listEntries` data still drives the journal.
- `HabitsPage.test.tsx`: previous/next week changes the `listEntries(start, end)` window and Today returns to the current week; proves the week navigator is API-grounded.
- `HabitsPage.test.tsx`: clicking an empty day calls `upsertEntry({ status: 'yes' })`, clicking a skipped day calls `deleteEntry`; proves the existing status cycle remains intact.
- `HabitsPage.test.tsx`: archive, restore, delete, and reorder still call `updateHabit`, `restoreHabit`, `deleteHabit`, and `reorderHabits`; proves non-chart behavior was not dropped during the reskin.
- `HabitsPage.test.tsx`: charts tab requests `listHabitEntryStats` for the selected period and renders rates/table rows; proves the missing tab is backed by the new wrapper.
- `HabitsPage.test.tsx`: changing chart period updates range/granularity; proves month versus longer-period queries do not drift.
- `HabitsPage.test.tsx`: stats rejection renders localized chart load error while the journal tab remains usable; proves chart failures are isolated.
- `HabitsPage.test.tsx`: matrix renders backed entry statuses and does not display numeric partial values; proves screenshot-only unsupported values are not faked.
- Final command set: `cd /Users/allosta/Desktop/superapp-habits-wt/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `habits.list.failed` | `listHabits(false)` rejects through React Query | `HabitsPage` / journal query state | Localized `focal.habits.errors.load`; create dialog remains available but active rows do not render. |
| `habits.archived.failed` | `listHabits(true)` rejects | Archived section query state | Archived section shows a localized archive-load error or remains collapsed; active journal still renders. |
| `habits.entries.failed` | `listEntries(weekStart, weekEnd)` rejects | `HabitJournal` entries query state | Journal rows render with disabled/empty day cells and a localized entries-load message. |
| `habits.streaks.failed` | `listStreaks()` rejects | `HabitJournal` streak lookup fallback | Rows render with `0`/hidden streak text and a localized non-blocking streak message if space allows. |
| `habit.create.failed` | `createHabit(input)` rejects | `createMutation.onError -> onMutationError` | Existing destructive alert with backend detail; dialog stays open with the draft intact. |
| `habit.entry.upsert.failed` | `upsertEntry(input)` rejects | `toggleMutation.onError -> onMutationError` | Existing destructive alert with backend detail; cell state is not optimistically changed permanently. |
| `habit.entry.delete.failed` | `deleteEntry(habitId, date)` rejects | `toggleMutation.onError -> onMutationError` | Existing destructive alert with backend detail; skipped cell remains visible after refetch. |
| `habit.archive.failed` | `updateHabit(id, { isArchived: true })` rejects | `archiveMutation.onError -> onMutationError` | Existing destructive alert; active row remains because archive is not optimistic. |
| `habit.restore.failed` | `restoreHabit(id)` rejects | `archiveMutation.onError -> onMutationError` | Existing destructive alert; archived row remains. |
| `habit.delete.failed` | `deleteHabit(id)` rejects | `deleteMutation.onError -> onMutationError` | Existing destructive alert; archived row remains. |
| `habit.reorder.failed` | `reorderHabits(orderedIds)` rejects | `reorderMutation.onError -> onMutationError` | Existing destructive alert; order returns to server order after refetch. |
| `habit.stats.failed` | `listHabitEntryStats(start, end, granularity)` rejects | `HabitCharts` stats query state | Localized chart-load error inside the charts tab; journal tab and create dialog continue working. |
| `habit.matrix.entries.failed` | `listEntries(matrixStart, matrixEnd)` rejects inside charts tab | `HabitCharts` matrix query state | Matrix card shows localized load error; the stats chart/table still render if stats loaded. |
| `habit.stats.empty` | No exception; stats query returns `[]` | `HabitCharts` empty-state branch | Empty chart/table state with zero completion; no fake rows or random demo data. |
| `habit.futureCell.disabled` | No exception; date is after today | Button disabled before mutation handler runs | Future day cell is muted and cannot submit `upsertEntry`. |
| `habit.blankCreate` | No exception; trimmed name is empty | Dialog submit guard / disabled submit | Create button is disabled or no mutation is fired; dialog stays open. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** — This is the minimum complete cut for the accepted think option: journal reskin plus charts port in one slice, but built in reviewable sub-slices. Existing habits API wrappers remain the behavior base; the only API change is adding a missing typed client wrapper for an already-existing OpenAPI endpoint. If implementation size balloons, the fallback split is journal/create first and charts second, but the plan keeps both because the task asks for the full habits page.
- **Architecture** — `HabitsPage` owns shared query invalidation and mutation error messaging. `HabitCreateDialog`, `HabitJournal`, and `HabitCharts` are local feature components with callback/data props. Chart data shaping lives in pure utilities so Recharts is only rendering, not business logic. Unhappy paths flow through React Query `isError` or mutation `onError`; there is no new global state.
- **Design** — `PageHeader` preserves the shell toolbar and gives the page the old-focal title/Add layout. Tabs use existing shadcn primitives. The journal gets the old-focal week navigator and compact status rows while avoiding controls that imply unimplemented behavior. The charts tab follows the old-focal/screenshot visual direction with backed stats and a status matrix; unsupported numeric partial cells are deliberately not shown.
- **DevEx** — No new dependency, backend route, OpenAPI regeneration, shared component edit, or CSS token edit. Tests prefer accessible labels, table/matrix text, and API calls over brittle class or SVG snapshots. Recharts can be mocked in tests where layout containers make SVG output unstable.

# Risks & migrations

- No database migration, backend/API schema change, generated OpenAPI change, environment variable, package dependency, or lockfile update.
- Main risk: visual-contract conflict between the actual old-focal `HabitCharts.tsx` and the separate `habits-chart*` / `habits-matrix` screenshots. Resolution in build: prefer backed behavior and the named old-focal component; reproduce screenshot-only structure only when current `HabitEntry` / stats data supports it.
- Secondary risk: the journal reskin accidentally ports old-focal interactions outside scope. Mitigation: no DnD, notes, edit dialog, project picker, or cross-feature queries unless a reviewer cites them as Must Fix.
- Tertiary risk: Recharts tests become brittle under happy-dom. Mitigation: move calculations to `habitChartUtils.test.ts` and assert chart-tab behavior through summary table/matrix plus wrapper calls.
- Rollback plan: revert the planned habits feature files, `api/habits.ts` / `api/habits.test.ts`, and locale additions. No persistent data shape changes are introduced.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting if implemented in the ordered slices above.
- [x] Size smell checked: this adds several local habits components because the source and target page shapes differ, but it stays within the habits feature, typed client wrapper, tests, and locales. No server, schema, shell, or dependency changes are planned.

# Out of scope

- Backend route, service, schema, model, migration, or OpenAPI generation changes.
- Heatmap / yearly heatmap work.
- Recreating old-focal's DnD reorder, note editing, edit-habit dialog, project picker, or cross-calendar/user branches.
- Numeric habit quantities or partial target values in the matrix; the current `HabitEntry` API only stores `yes`, `no`, and `skip`.
- Shared shell/token changes, `PageHeader` changes, shadcn primitive changes, or broader Focal redesign cleanup.
- Adding packages or lockfile churn.
