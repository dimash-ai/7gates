# Design — focal-redesign-habits (slice 2)

Bring the new Habits page to exact parity with **old-focal's actual habits components** (not the
aspirational mockup screenshots), over the existing API, on the shell foundation. Worktree
`/Users/allosta/Desktop/superapp-habits-wt`, branch `feat/focal-redesign-habits`. old-focal reference
read from the main checkout `superapp/apps/old-focal`.

**Binding contract = the real old-focal components** (resolves the plan-review Should-Considers):
`pages/Habits.tsx` (Tabs: Журнал/Графики + Add header + `HabitCreateDialog`),
`components/habits/HabitJournal.tsx`, `HabitCharts.tsx`, `HabitCreateDialog.tsx`. **The
`habits-matrix.png` / numeric-`habits-chart` screenshots are NOT the contract** — old-focal has **no
matrix component**, and the model has no quantity/partial field (`HabitEntryRead.status ∈ {yes,no,skip}`),
so the matrix is **dropped** (not faked, not built). Charts bind to old-focal `HabitCharts.tsx` exactly.

## 1. Page shell — `features/habits/HabitsPage.tsx` → controller

Refactor the 396-line journal-only page into a thin controller composing the shell + tabs (mirrors
old-focal `Habits.tsx`):
- `<PageHeader icon={Repeat} title={t('focal.app.nav.habits')} rightActions={<AddHabitButton/>} />`
  (PageHeader already supplies the shared toolbar + AI button — do **not** add a second).
- shadcn `<Tabs>` with `journal` | `charts` (labels `focal.habits.journal` / `focal.habits.charts`).
- Owns the create-dialog open state + the shared React-Query invalidation; renders `<HabitJournal/>`
  and `<HabitCharts/>` (new local components). Keeps the route stable.

## 2. API wrapper — `api/habits.ts` (only API change: a typed client for an existing route)

Add (no backend change — `/api/habit-entries/stats` already exists in `openapi.d.ts`), matching the
file's existing `Schemas[...]` + `apiFetch(path, { query })` conventions (exactly like `listEntries`,
`habits.ts:37-38`):
```ts
export type HabitEntryStat = Schemas['HabitEntryStatRead'] // {habitId, period, yes, no, skip}
export type HabitStatsGranularity = 'day' | 'month'
export const listHabitEntryStats = (start: string, end: string, granularity: HabitStatsGranularity = 'month') =>
  apiFetch<HabitEntryStat[]>('/api/habit-entries/stats', { query: { start, end, granularity } })
```
Keep all existing wrappers/mutations unchanged (`listHabits`/`listEntries`/`listStreaks`/`createHabit`/
`upsertEntry`/`deleteEntry`/`updateHabit`/`restoreHabit`/`deleteHabit`/`reorderHabits`). **No `userId`
query param** — the new API derives the tenant from the JWT (unlike old-focal's `?userId=`).

## 3. Charts — `features/habits/HabitCharts.tsx` (port old-focal `HabitCharts.tsx` exactly)

Reproduce old-focal's component 1:1 on the new stack:
- **Controls row:** habit `Select` (`__all__` + per-habit with colour dot), period buttons
  `1w/1m/3m/6m/1y/3y` (`PERIODS` with `{days|months, granularity}` per old-focal HabitCharts.tsx:49-56),
  and a right-aligned completion-rate badge coloured by threshold (≥70 success / ≥40 warning / else
  destructive) — via the now-old-focal **tokens** (`text-success`/`text-warning`/`text-destructive`),
  not raw hex.
- **Chart:** Recharts `ComposedChart` — stacked `Bar yes` + `Bar no` on a left count axis, `Line rate`
  on a right 0-100% axis, `CartesianGrid`, custom tooltip, `Legend` (HabitCharts.tsx:216-277).
  **Exact series colours** (old-focal HabitCharts used raw `#22c55e`/`#ef4444`/`#3b82f6`; reproduce via
  the post-shell tokens that carry those values): `Bar yes` → `var(--focal-green-500)` (=`#22c55e`),
  `Bar no` → `var(--focal-coral-500)` (=`#ef4444`), `Line rate` → `hsl(var(--primary))` (the Focal
  blue, ≈ old-focal's `#3b82f6` trend, and it themes for dark). `ResponsiveContainer` in an `h-[350px]`
  box.
- **Summary table** (when `__all__`): per-habit yes/no/% rows, colour dot, click-to-filter
  (HabitCharts.tsx:281-328).
- Data: `listHabits()` + `listHabitEntryStats(periodStart, periodEnd, granularity)`; bucket-fill the
  full day/month range so sparse server stats render stable (port the `bucketMap` init,
  HabitCharts.tsx:101-148). Loading skeletons; explicit empty/error states so a stats error **does not
  break the journal tab**.
- **No matrix.** (old-focal HabitCharts has none.)

## 4. Chart utils — `features/habits/habitChartUtils.ts` (+ test)

Port old-focal's `components/habits/habitChartUtils.ts` (pure): `subtractPeriod`, `formatDateStr`,
`formatMonthLabel`, `formatDayLabel`, `PeriodKey`, plus bucket-fill + rate helpers — so date math and
data shaping are unit-tested outside Recharts. Labels are data-driven from i18n month/weekday names.

## 5. Journal — `features/habits/HabitJournal.tsx` (re-skin over EXISTING behavior)

Match old-focal `HabitJournal`'s **look** while keeping the new page's behavior:
- A 7-day week navigator (prev/Today/next) + day strip with today + selected highlight; query
  `listEntries(weekStart, weekEnd)` for the visible week (not a fixed today-ending range).
- Compact habit rows: colour dot, name, streak copy, and per-day status cells cycling the **existing**
  `none→yes→no→skip→none`; future-date cells disabled.
- Archived habits behind an old-focal-style collapsible, on the existing archived query.
- **Keep** the new app's up/down reorder buttons + archive/restore/delete. **Do not** port old-focal's
  DnD reorder, notes, edit-habit dialog, or project picker (behavior change — out of scope).

## 6. Create dialog — `features/habits/HabitCreateDialog.tsx`

Replace the inline create card with a dialog styled after old-focal's `HabitCreateDialog` (colour
swatches, type/frequency controls), producing the **exact current** `createHabit` payload
(`HabitsPage.tsx:147-155`): `{ name, color, type, frequency, targetDaysPerWeek: frequency==='weekly' ?
targetDays : 7, isArchived: false, sortOrder: active.length }`.
**Behavior-preservation (not schema absence):** old-focal's dialog also sets `description`,
`category`, and `projectId` — these **do** exist as *optional* fields on the new `HabitCreate` schema
(`openapi.d.ts:3554`/`:3567`/`:3580`), but the new app's current create flow does not use them, so this
slice **omits** them to keep create behavior unchanged. Adding those inputs would expand the create
flow = a behavior change, out of scope for a visual re-skin. On success: reset, close, clear error,
invalidate `['habits']`. Blank-name guard before mutating.

## 7. i18n — `i18n/locales/{en,ru}.json`

Extend `focal.habits.*` with journal/charts/dialog labels, period labels, completion-rate, chart
errors, weekday/month short names — reusing old-focal's `locales` copy where the keys line up. No
hardcoded strings.

## 8. Tests

- `api/habits.test.ts` — `listHabitEntryStats` hits `/api/habit-entries/stats?start&end&granularity`.
- `habitChartUtils.test.ts` — month-end clamp, day/month bucket fill of sparse stats, label formatting,
  rate (skip excluded from denominator; 0 on empty), habit filter + average aggregation.
- `HabitsPage.test.tsx` (extend the existing) — PageHeader + 2 tabs render; Add opens the dialog;
  create submits the existing payload + invalidates; blank-name guarded; week prev/next changes the
  `listEntries(start,end)` window + Today resets; status cycle calls `upsertEntry`/`deleteEntry`;
  archive/restore/delete/reorder still call their mutations; charts tab calls `listHabitEntryStats`,
  renders rates/table; period change switches range/granularity; a stats error keeps the journal tab
  usable. Mock Recharts where SVG is unstable; assert table/aria, not SVG internals.

## 9. Verification + visual QA

```sh
cd /Users/allosta/Desktop/superapp-habits-wt/apps/focal/client
pnpm install --frozen-lockfile && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```
Manual light+dark, desktop+mobile vs old-focal: journal (week strip, rows, status cells, archived),
charts (ComposedChart bars+line, period buttons, completion badge, summary table), create dialog.

## 10. Out of scope / failure modes / rollback

- **Matrix** (no old-focal component, unbacked numeric data) — dropped, not faked.
- Any server/API/schema/behavior change; old-focal DnD/notes/edit-habit/project-picker; shell tokens.
- Failure map (carried from the plan): every `list*`/mutation rejection surfaces a localized,
  tab-isolated error (a charts-stats error never breaks the journal); empty stats → zero state, no
  fake rows; future cells disabled; blank create guarded.
- **Rollback** = revert the habits feature files + the `api/habits.ts` wrapper + locale keys. No
  data/schema/contract change. Diff stays within `features/habits/*`, `api/habits.ts(.test)`, locales.
