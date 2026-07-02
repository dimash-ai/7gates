# Problem

Slice 3 of the approved `focal-redesign-calendar` epic. Slices 1-2 gave the calendar a styled **week**
time-grid + the event popover, but Google Calendar — and the prototype — let you switch between
**day / 3-day / week / month** views, jump dates from a **mini-month**, and navigate by the view's
unit. This slice adds those views, the view switcher, the mini-month in a left-rail scaffold, per-view
navigation, and the **keyboard shortcuts** that slice 1 deliberately deferred to land here as one
coherent set. It matters now because the side panel (slice 5) lives in the same left rail and drag
(slice 4) operates across these views, so the view machinery + rail must exist first.

# Assumptions

- **[confirmed — git]** Slices 1-2 are merged in `feature/focal-migration` (`7cef2c6`): the week grid +
  `EventBlock` + the popover/scope-dialog are the base this slice parametrizes and reuses.
- **[confirmed — inspection]** The day/3-day/week views are the **same time grid** with a different
  day count (1/3/7) over a different start date; only **month** needs a new grid. The prototype proves
  this (`CalendarScreen` renders the grid for non-month views, `MonthView` for month).
- **[unverified — confirm at design gate]** `listEvents(start, end)` returns the events to render for
  any window (incl. whatever recurrence expansion the backend does), so widening the window to a month
  is sufficient and **no new client-side recurrence expansion is added**. The current grid already
  renders exactly what `listEvents` returns (filtered by `event.date`); month view keeps that model.
- **[confirmed — epic]** The prototype's **year** tab routes to the Booking screen and the mini-month /
  month **booking marks** need the `bookings` data — both deferred (year → separate feature; marks →
  slice 7). This slice ships the views without them.
- **[unverified]** The prototype is the visual target; Google Calendar is the interaction reference
  (view switcher, unit-step navigation, mini-month, shortcuts).

# Options considered

The substantive fork is **how much to extract** as the grid goes from one (week) to four views.

| option | what it is | pros | cons |
|--------|-----------|------|------|
| **A — Extract `TimeGrid` + `MonthView` + `MiniMonth`; CalendarPage stays the controller (chosen)** | Pull the day-column time grid into a `TimeGrid` parametrized by the visible days (1/3/7), add `MonthView` + `MiniMonth` as siblings; `CalendarPage` owns `view`/`anchor`/the query/the popover and the shortcuts, and renders the right child per view. | The grid logic is written once and reused by day/3-day/week; the month + mini-month are self-contained; CalendarPage stays the single owner of state + the popover wiring (which every view opens); each piece is testable. | Three new files; a modest refactor of the slice-1 grid JSX out of CalendarPage into `TimeGrid` (carefully, behavior-preserving). |
| **B — Inline everything in CalendarPage** | Keep the grid inline and branch on `view` inside CalendarPage's JSX. | No new files. | CalendarPage becomes a very large multi-view component; the grid + month + mini-month tangle; harder to test; the slice-4 drag layer would then wrap inline JSX. |
| **C — A calendar library for views** | Adopt a calendar lib that provides the views. | Views out of the box. | Rejected at the epic level (pixel-parity + Allosta tokens + the custom popover/blocks); re-litigating it here is out of scope. |

# Recommendation

**Option A.** Extract a **`TimeGrid`** (the day/3-day/week columns, parametrized by the visible day
list — a behavior-preserving lift of slice 1's grid), plus **`MonthView`** and **`MiniMonth`**.
`CalendarPage` keeps ownership of `view`, `anchor`, the events query, the popover/scope-dialog wiring,
and the keyboard shortcuts — and renders the `TimeGrid` for day/3-day/week or the `MonthView` for
month, with the `MiniMonth` in the new left rail. The **query window** is derived per view: day =
`[anchor]`, 3-day = `anchor..+2`, week = `mondayOf(anchor)..+6`, month = `startOfWeek(firstOfMonth)..
+41`. The popover opens from a **slot/event click in `TimeGrid`**; a **`MonthView` day-cell click
switches to day view** (month cells are read-only event previews — editing happens via the time-grid
popover, not from a month cell). The **`MiniMonth` pick sets `anchor` and preserves the current view**
(Google-Calendar-faithful: week stays week showing that week, day shows that day).
The tradeoff accepted: a careful refactor of the slice-1 grid into `TimeGrid`, kept behavior-identical
(the existing grid/now-line/lane/popover tests must stay green).

**On slice size:** this is the largest of the deferred-detail slices (4 views + month grid +
mini-month + rail + shortcuts). If the plan gate judges it too big, the clean cut is **the time-grid
views (day/3-day) + switcher + shortcuts** in this slice and **`MonthView` + `MiniMonth` + the rail**
as a focused follow-up — flagged for the plan gate.

# Out of scope

- Year view + the Booking screen; booking marks in the mini-month/month (slice 7); the side-panel
  **content** (slice 5 — the rail is only scaffolded here); drag/move/resize (slice 4); golden/
  prime-time (slice 8).
- Any server/API/schema change; new client-side recurrence expansion; a calendar-library adoption.

# Open questions

- **Recurrence over a wider window** (assumption above) — confirm at the design gate that `listEvents`
  returns the right events for a month window (backend expands recurring occurrences, or recurring
  events render on their stored date) so month view needs no new client expansion.
- **`anchor` semantics across views** — keep one `anchor` Date and derive the visible range per view
  (day = anchor, week = `mondayOf(anchor)`, month = `anchor`'s month); confirm the prev/next stepping
  + the mini-month pick update it consistently. Settled at design.
- **Shortcut set** — `d`/`w`/`m`/`3`/`t`/`n`/`p`/`j`/`k`; confirm exact keys + the input/popover-open
  guard at the design gate.
- **Slice split** — keep month + mini-month in-slice (recommended) vs split to a follow-up (above).

# Success criteria

- [ ] `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green; slice-1/2 calendar tests
      stay green through the `TimeGrid` extraction.
- [ ] View switcher toggles day/3-day/week/month; the time grid renders 1/3/7 columns; month renders
      the 6×7 grid with ≤3 events/day + "+N more"; light + dark.
- [ ] Prev/next steps by the view unit and `listEvents` is called with the matching window; Today
      resets; the range label adapts.
- [ ] Mini-month picks a date → the grid navigates there in the **current** view; today + selected
      highlighted; no booking marks.
- [ ] The popover opens from a slot/event in every time-grid view; month day-click → day view; CRUD +
      recurrence scope unaffected.
- [ ] Keyboard shortcuts switch view / navigate and are ignored while typing or while the popover/
      dialog is open (tested).
- [ ] i18next `ru` + `en`; surgical diff (`features/calendar/*` + `MonthView.tsx`/`MiniMonth.tsx` +
      locales); before/after screenshots per view vs the prototype.
