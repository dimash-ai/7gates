# Design: focal-parity-calendar-year

3-gate flow · Slice B of the calendar follow-up. Branch `feat/focal-parity-calendar-year` → base
`feature/focal-migration`. **Frontend-only** — adds a view that reuses the existing events query and
view-switch infra; no server/API/schema/migration, no new dependency.

## Problem & decision

Old-focal's calendar has a **Year** view (Г); the migrated calendar has only day/3-day/week/month
(`CalendarPage.tsx:44-51`). The user wants the year view. But old-focal's year view is a **booking-centric
"Календарь брони / Booking Calendar"** (`old-focal CalendarViews.tsx:4664-4900`): a 4×3 grid of months
whose day cells render **booking** density and open **booking** popovers (it keys off `bookings`, not
`events`). The migrated calendar never fetches `bookings` (no bookings query/state), which is exactly why
the redesign bundled "year view + bookings" and deferred it.

**Decision (agreed scope).** Ship the **lightweight event-density year navigator** now and defer the
bookings layer to its own slice. Add `'year'` to `CalendarView` + a **Год/Year** toggle; render a new
presentational **`YearView`** — a responsive 12-month grid (each month: name header + weekday row + day
cells with an **event-density dot**) — driven by **CalendarPage's existing events query widened to the
year window**. Clicking a **day** → Day view on that day; clicking a **month** header → Month view on that
month. The bookings content (booking spans, booking popovers, the "Booking Calendar" framing) is the
deferred follow-up.

**Alternatives rejected.**
- *Port old-focal's booking-centric year view now (full parity).* Rejected: the migrated calendar doesn't
  fetch `bookings` at all — that's a separate, larger slice the user agreed to defer. Shipping the
  navigator first delivers the year view without blocking on the bookings data layer.
- *12 per-month queries (one per month, like 12 `MiniMonth`s).* Rejected: `CalendarPage` already owns ONE
  events query keyed on the view window (`CalendarPage.tsx:198-202`); widening it to the year is the
  established pattern (`MonthView` uses the same query for its 6-week window). One fetch, no new query
  surface.
- *Reuse `MiniMonth` 12×.* Rejected: `MiniMonth` owns its own displayed-month state, its own per-month
  query, prev/next chevrons, and anchor-sync (`MiniMonth.tsx:30-65`) — none fit a static year grid. Its
  compact day-grid + density-dot **pattern** is the model, shared via an extracted `monthCells` helper.

## Assumptions & scope
- Assumption (confirmed): a view is defined by a `CalendarView` union member + a `VIEW_TABS` entry + a
  `windowFor` case + a render branch, all in `CalendarPage.tsx:44-101,488-510`; `windowFor` returns
  `{days, startIso, endIso, step}` and the single events query keys on `startIso/endIso`. Adding `'year'`
  follows that contract exactly.
- Assumption (confirmed): `listEvents(startIso, endIso, calendarId)` accepts any window; the events query
  just widens to Jan 1–Dec 31 (`MonthView`/`MiniMonth` already use it for their windows). **No backend.**
- Assumption (confirmed): old-focal's year view is booking-centric (`old-focal CalendarViews.tsx:4664+`),
  so an **event-density** navigator is a deliberate, agreed substitute for the booking-density original.
- Assumption (confirmed): year density counts events by `event.date` exactly as returned (no client
  recurrence expansion) — identical to `MonthView`/`MiniMonth` (`MiniMonth.tsx:66-72`).
- Out of scope: the **bookings layer** (booking spans/popovers/the "Booking Calendar" content) — its own
  slice; drag; the now-line (N/A to year); per-year recurrence expansion; any create/write (the year view
  is read-only navigation).
- Open questions: None.

## Success criteria
- [ ] A **Год/Year** toggle appears in the view switcher; selecting it renders a 12-month grid for the
  anchor's year, and the events query fetches the **Jan 1–Dec 31** window (assert `listEvents` args).
- [ ] Each month shows its localized name + weekday headers + day cells; a day with ≥1 event shows a dot.
- [ ] Clicking a **day** switches to **Day** view anchored on that day; clicking a **month** header
  switches to **Month** view on that month (assert the resulting `listEvents` window).
- [ ] Prev/next steps a **whole year**; **Today** returns to the current year; the range label shows the
  year; the `y` keyboard shortcut switches to year (guarded like the others).
- [ ] `pnpm typecheck`, `pnpm lint`, `pnpm test:run`, `pnpm build` pass; new EN keys have RU counterparts;
  diff confined to `features/calendar/*` + i18n + tests.

## Build approach (slices)

One cohesive slice (a single new view); built in order, each step leaving the tree green:

| # | step | files | main failure mode | what its test proves |
|---|------|-------|-------------------|----------------------|
| 1 | `windowFor('year')` + `'year'` in `CalendarView`/`VIEW_TABS` + range label + prev/next (`addMonthsClamped(anchor, 12·dir)`) + `y` shortcut | `CalendarPage.tsx`, `dates.ts` (`monthsOfYear`), i18n, `CalendarPage.test.tsx` | wrong query window / nav step | year toggle fetches `Jan1..Dec31`; prev/next steps a year; `y` switches; label = year |
| 2 | `YearView` (12-month grid + density dots + day→day / month→month) + extract `monthCells` (adopted by `MiniMonth`) | `YearView.tsx` (new), `dates.ts` (`monthCells`), `MiniMonth.tsx` (adopt helper), i18n, `YearView.test.tsx` + `CalendarPage.test.tsx` | dots wrong / clicks navigate wrong | a day with events shows a dot; day-click → day window; month-click → month window |

## Architecture & contracts

```
CalendarPage (view: +'year'; windowFor('year') → {days: 12 month-starts, startIso Jan1, endIso Dec31,
   │           step ±12 months}; the one events query fetches the year; rangeLabel = year)
   ├─ view === 'year' → <YearView months events todayIso locale onPickDay onPickMonth />   (NEW)
   ├─ view === 'month' → <MonthView .../>            (unchanged)
   └─ else            → <TimeGrid .../>              (unchanged)
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| API / DB | **None** | the events query just widens its window |
| `CalendarView` / `VIEW_TABS` | add `'year'` + `{key:'year', labelKey:'focal.calendar.views.year'}` | the 5th toggle, after Month |
| `windowFor` | add `case 'year'` → `{days: monthsOfYear(year), startIso: Jan1, endIso: Dec31, step: dir => addMonthsClamped(anchor, 12·dir)}` | reuses `addMonthsClamped`; `days` = the 12 first-of-month dates |
| `dates.ts` | add `monthsOfYear(year): Date[]` (12 month-starts) and `monthCells(year, month): (Date\|null)[]` (leading blanks + the month's days) | `monthCells` = the exact computation inlined in `MiniMonth.tsx:51-56`, extracted |
| `MiniMonth.tsx` | adopt `monthCells` in place of its inline `cells` (identical output) | reuse-first; behavior-preserving, its tests stay green |
| `YearView.tsx` | **new** presentational component: `{months: Date[]; events: CalendarEvent[]; todayIso: string; locale: string; onPickDay: (d:Date)=>void; onPickMonth: (m:Date)=>void}` | reduces `events`→`Map<ymd,count>`; responsive grid `grid-cols-2 sm:grid-cols-3 lg:grid-cols-4`; month header is a button → `onPickMonth`, day is a button → `onPickDay`, dot when count>0, today highlight |
| `CalendarPage` render | `onPickDay → setAnchor(d)+setView('day')`; `onPickMonth → setAnchor(m)+setView('month')`; suppress the empty-overlay for year (`isEmpty && view !== 'year'`) so the navigator grid isn't covered | mirrors `MonthView.onPickDay`'s zoom pattern |
| keyboard guard | add `case 'y': setView('year')` | same guard/deps as the existing shortcuts |
| i18n | add `focal.calendar.views.year`, `focal.calendar.units.year`, `focal.calendar.year.openMonth` (ru+en); reuse `focal.calendar.month.dayCell` for day aria-labels | no hardcoded strings |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — open year | click Год / press `y` | `setView('year')` → `windowFor` re-derives | year grid renders; events query fetches Jan1..Dec31 |
| happy — to a day | click a day cell | `onPickDay` → `setAnchor+setView('day')` | zooms to that day |
| happy — to a month | click a month header | `onPickMonth` → `setAnchor+setView('month')` | zooms to that month |
| happy — step year | prev/next / Today | `step(±12 months)` / `setAnchor(new Date())` | anchor moves a year; query re-runs |
| empty — year with no events | query returns `[]` | `YearView` from `events ?? []`; empty-overlay suppressed for year | grid renders, no dots, still navigable |
| loading | query in flight | existing `CalendarSkeleton` overlay | skeleton over the card, then the grid |
| unhappy — load error | `listEvents` rejects | existing `events.isError` page alert | the load-error alert shows **and** the card/grid still renders from `events.data ?? []` (empty → no dots), so navigation stays available — matches the existing month/time-grid behavior, no conditional change |
| edge — shortcut while typing / popover open | key pressed | the existing guard | no-op |

## Test strategy, security & rollback
- Test strategy (Vitest + Testing Library + a `dates.ts` unit test):
  - `windowFor`/page: selecting Год calls `listEvents(Jan1, Dec31, …)`; prev/next steps a year; `y` switches; range label = the year. Include a case with a **non-null `currentCalendarId`** so the widened query's shared-calendar scoping is pinned (the third `listEvents` arg), not only the date range.
  - `YearView` (component test): renders 12 month headers; a day with a mocked event shows the dot; clicking that day calls `onPickDay` with the right date; clicking a month header calls `onPickMonth`. At the page level, assert day-click → day window and month-click → month window via `listEvents`.
  - `monthCells` unit test (leading blanks + day count for a known month); confirm `MiniMonth` tests stay green after it adopts the helper.
  - "Verified" = `pnpm typecheck && pnpm lint && pnpm test:run && pnpm build` green + a manual smoke (the year grid, day/month click-through, light+dark).
- Security: none. Read-only navigation; no new endpoint/secret; the year window uses the same `listEvents` + calendar scoping as every other view. No write path (no create/edit in the year view).
- Rollback: revert `CalendarPage.tsx`, `YearView.tsx`, the `dates.ts` + `MiniMonth.tsx` deltas, the i18n additions, and the tests. No migration/data/config.
