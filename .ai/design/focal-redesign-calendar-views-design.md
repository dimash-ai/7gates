# Design summary

Add day/3-day/month views by extracting the slice-1 week grid into a behavior-preserving
**`TimeGrid`** (the day-column grid, parametrized by the visible `days` list), and adding read-only
**`MonthView`** + a **`MiniMonth`** navigator in a new left rail. `CalendarPage` stays the single
controller: one `view` + one `anchor` derive the visible day range and the `listEvents` window, and it
keeps the popover/scope-dialog wiring, mutations, errors, and the new keyboard shortcuts. Two hinge
decisions: (1) **one window helper** maps `view`+`anchor` → `{days, startIso, endIso, step}` so every
view (incl. the query and navigation) flows from it; (2) the **now-line is a `TimeGrid` invariant** —
it renders only on the column whose date is today, and only when today is among the visible `days`.
Traces to `.ai/think/…-views.md` + `.ai/plans/…-views-plan.md`.

# Architecture

```
CalendarPage  (owns: view, anchor, the derived window, events query, mutations, popover/dialog,
   │           error/loading, keyboard shortcuts — unchanged ownership from slices 1-2)
   │  windowFor(view, anchor) → { days: Date[], startIso, endIso, step(dir) }
   │  events = useQuery(['events', startIso, endIso], () => listEvents(startIso, endIso))
   ▼
 ┌─ view ∈ day/3day/week → <TimeGrid days events todayIso onCreate onEdit />   (slice-1 grid lifted)
 └─ view === month        → <MonthView monthDays events todayIso onPickDay />  (read-only previews)
 left rail → <MiniMonth anchor today onPick />   (+ empty region reserved for the slice-5 side panel)
 popover/scope-dialog (slice 2) ← opened by TimeGrid onCreate/onEdit; unchanged
```

- **`TimeGrid.tsx`** (new) — a behavior-preserving lift of the slice-1 grid: hour gutter, sticky day
  headers, today-column tint, slot buttons, the now-line, lane layout + `EventBlock`. Props: `{ days:
  Date[]; events: CalendarEvent[]; todayIso: string; locale: string; onCreate: (dateIso, hour,
  AnchorSource) => void; onEdit: (event, AnchorSource) => void }`. The column count is **dynamic** (1/3/7),
  so it uses an **inline** `style.gridTemplateColumns = "3.5rem repeat(" + days.length + ", 1fr)"` — NOT a
  Tailwind arbitrary class with a runtime `N` (the JIT cannot generate `grid-cols-[…]` from a runtime value).
  **Now-line invariant:** rendered on the column with `toIsoDate(day) ===
  todayIso`, which only exists when today ∈ `days` — so day-anchored-off-today and today-excluded
  3-day/week windows show no now-line, and month (no `TimeGrid`) never does.
- **`MonthView.tsx`** (new) — read-only 6×7 grid: weekday headers, in/out-of-month + weekend styling,
  today highlight, ≤3 event previews/day (dot + title) + a localized **`+N more`**, day-cell button →
  `onPickDay(date)`. Groups events by `toIsoDate(day)` (no client recurrence expansion). Props: `{
  monthDays: Date[]; anchorMonth: number; events; todayIso; locale; onPickDay: (date) => void }`.
- **`MiniMonth.tsx`** (new) — compact navigator with its own displayed month/year (re-synced when
  `anchor` changes), own prev/next-month chevrons, weekday headers, today/selected styling, day pick →
  `onPick(date)`. **No booking marks** (slice 7). Props: `{ anchor: Date; today: Date; onPick: (date)
  => void }`.
- **`CalendarPage.tsx`** — refactored controller: `view`/`anchor` state, `windowFor`, the view switcher
  + per-view nav + range label, the left rail (~290px on desktop; stacks/hides responsively on narrow
  screens so it never crushes the grid) + conditional `TimeGrid`/`MonthView`, the popover wiring
  (`openCreate`/`openEdit` unchanged), and the keyboard listener. `MiniMonth.onPick` sets `anchor`,
  **preserving `view`**; `MonthView.onPickDay` sets `anchor` + `view='day'`.
- **`dates.ts`** — add `firstOfMonth(d)`, `addMonthsClamped(d, n)` (clamp day to the target month's
  last day — no JS month rollover), `monthGridDays(d)` (42 dates from `startOfWeek(firstOfMonth)`).

# Data model

| entity | change | notes |
|--------|--------|-------|
| — | **None** | No persistent state, schema, migration, or API change. `view` is client state; the query just widens/narrows its window. |

# Interfaces & contracts

**`windowFor(view, anchor)`** (in `CalendarPage`) → `{ days: Date[]; startIso: string; endIso: string;
step: (dir: 1 | -1) => Date }`:

| view | days | startIso / endIso | step(dir) |
|------|------|-------------------|-----------|
| `day` | `[anchor]` | `toIsoDate(anchor)` / same | `addDays(anchor, dir)` |
| `3day` | `anchor..+2` | `toIsoDate(anchor)` / `toIsoDate(addDays(anchor,2))` | `addDays(anchor, 3·dir)` |
| `week` | `weekDays(mondayOf(anchor))` | `toIsoDate(mondayOf(anchor))` / `…+6` | `addDays(anchor, 7·dir)` |
| `month` | `monthGridDays(anchor)` | `toIsoDate(days[0])` / `toIsoDate(days[41])` | `addMonthsClamped(anchor, dir)` |

`eventsKey = ['events', startIso, endIso]`. The **week row reproduces the current derivation exactly**,
so the existing `toHaveBeenCalledWith(weekStartIso, weekEndIso)` test stays green.

**Navigation labels (i18n — keep slice-1 keys load-bearing):** the prev/next buttons' accessible names
come from `navLabel(view, dir)`: **for `week` it returns the existing `focal.calendar.prevWeek` /
`nextWeek` keys verbatim** (three existing tests query by these — they must not be renamed); for
day/3-day/month it returns new `focal.calendar.nav.prev`/`next` interpolated with
`focal.calendar.units.{day|3day|month}`. `Today` keeps `focal.calendar.today`.

**`+N more` plural:** `focal.calendar.monthMore` uses **i18next count pluralization**
(`monthMore_one`/`monthMore_few`/`monthMore_many`/`monthMore_other` for ru; `_one`/`_other` for en),
called `t('focal.calendar.monthMore', { count })` — so ru is grammatical.

**Other new strings (i18next, ru + en — no hardcoded text):** the view-switcher labels
(`focal.calendar.views.{day,3day,week,month}`), the mini-month prev/next-month controls, and the month
+ mini-month day-cell accessible labels (date + event count) all resolve through i18next.

**Keyboard guard** (page-scoped `keydown`): no-op when `event.defaultPrevented`, any of
`meta/ctrl/altKey`, the target is `INPUT`/`TEXTAREA`/`SELECT`/`isContentEditable`, or `popover` /
`pendingOp` is open. Map `d`→day, `3`→3-day, `w`→week, `m`→month, `t`→today, `n`/`j`→next, `p`/`k`→prev;
shortcuts call the **same** handlers the buttons do (no drift).

# Flow (happy + unhappy paths)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — switch view | click switcher / shortcut | `setView` → `windowFor` re-derives | grid type + query window change |
| happy — navigate | prev/next / `n`·`p`·`j`·`k` / Today | `step(dir)` / `setAnchor(new Date())` | anchor moves by the view unit; query re-runs |
| happy — create/edit | slot/event click in `TimeGrid` | existing `openCreate`/`openEdit` → popover | unchanged from slice 2 |
| happy — month pick | `MonthView` day-cell click | `setAnchor(day); setView('day')` | zoom to that day |
| happy — mini-month pick | `MiniMonth` day click | `setAnchor(day)` (view preserved) | grid moves there in the current view |
| edge — now-line off-today | day anchored off today / today ∉ window | `TimeGrid` (no matching column) | no now-line; month never shows it |
| edge — month rollover | prev/next on the 31st into a short month | `addMonthsClamped` | clamps to the month's last day, no double-rollover |
| edge — empty window | query returns `[]` | `TimeGrid`/`MonthView` from `events.data ?? []` | empty grid; loading/error stay page-level |
| unhappy — load error | `listEvents` rejects | existing `events.isError` | existing load alert; shell stays |
| unhappy — mutation error | create/update/delete rejects | existing `onMutationError` | existing save alert; popover stays |
| edge — shortcut while typing / popover open | key pressed | the guard | no-op; the input/dialog handles the key |

# Alternatives rejected

- **Inline all views in `CalendarPage`** (no `TimeGrid` extraction) — rejected: tangles the grid +
  month + mini-month, untestable, and slice-4 drag would wrap inline JSX (think Option B).
- **A calendar library** — rejected at the epic level (pixel-parity + tokens + the custom popover).
- **Client-side recurrence expansion in month view** (the prototype's `instancesOn`) — rejected:
  frontend-only constraint; render exactly what `listEvents` returns (grouped by `event.date`).
- **Renaming `prevWeek`/`nextWeek` to generic `prev`/`next`** — rejected: three existing tests pin
  those keys; week keeps them, other views get new keys.
- **Mini-month always switching to day** (the prototype's month→day jump) — rejected for the
  GCal-faithful preserve-current-view behavior (a surfaced, intentional divergence).

# Test strategy

- **Extraction first:** the slice-1/2 tests (default-week `listEvents` window, prev-week, Today,
  now-line, create/edit/delete/popover/recurring-scope) stay green through the `TimeGrid` lift with no
  rewrite. The now-line test is **kept verbatim** (week view + current week → today visible → present;
  prev week → absent), and a **new** test asserts day-view anchored off-today shows no now-line.
- **New (page-level):** view switching renders the right grid type (1/3/7 columns vs month grid);
  per-view `listEvents` window (assert via the same date helpers, not hard-coded month edges);
  per-view prev/next step + Today; month grid (42 cells, ≤3 previews + `+N more`, day-click → day
  view + matching window); mini-month (chevrons move only the mini display; pick preserves view +
  re-windows); shortcuts (`d`/`3`/`w`/`m`/`t`/`n`/`p`/`j`/`k`) + the **guard** (popover open + input
  focused → key is a no-op).
- **"Verified"** = `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green + screenshots
  (each view + mini-month, light + dark) vs the prototype.

# Security & release notes

- **None.** Frontend-only, presentational; no authz/injection/secret surface; no migration. The events
  API, mutations, recurrence scope, and the slice-2 popover are untouched. Release risk **Low**;
  rollback = revert `CalendarPage.tsx`, the three new components, the `dates.ts` helpers, the locale
  additions, and the test delta.
