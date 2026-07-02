# Goal

**Slice 3 of the `focal-redesign-calendar` epic** (parent: `.ai/think/focal-redesign-calendar.md`;
builds on slice 1 grid + slice 2 popover, both in `feature/focal-migration` at `7cef2c6`). Add the
calendar's **views** — **day / 3-day / month** alongside the existing week — with a **view switcher**,
a **mini-month** navigator in a **left-rail scaffold**, per-view navigation, and the Google-Calendar
**keyboard shortcuts** (deferred here from slice 1). After this slice the calendar navigates like
Google Calendar: switch views, jump dates from the mini-month, and the time-grid / month grid render
the same real events.

> **Visual contract** = the prototype `design/focal/screens/Calendar.jsx` — `MonthView` (`:1546`-`1581`),
> `MiniMonth` (`:1493`-`1543`), `ViewSwitcher` (`:1584`-`1591`), and the `CalendarScreen` view-window
> logic (`:508`-`605`). **Interaction contract = Google Calendar:** the view switcher (Day/3-day/Week/
> Month), prev/next stepping **by the view's unit**, a "Today" jump, the mini-month date picker, and
> the keyboard shortcuts (`d`/`w`/`m` + `3`, `t` today, `n`/`p` or `j`/`k` prev/next; `c` create stays
> with the popover slice). **Behavioral base** = the current `CalendarPage.tsx` (the week grid +
> `EventBlock` + the slice-2 popover, on the real `listEvents(start,end)` query).

> **Frontend-only.** No server/API/schema change. The views adjust the **events query window** per
> view (day = 1 day, 3-day = 3, week = 7, month = the visible 6-week grid) and render the events the
> backend returns for that window; **no new client-side recurrence expansion is added** (the grid
> already renders what `listEvents` returns). Strings via i18next (`ru` + `en`).

# Scope

**View state + switcher** — `CalendarPage.tsx`

- Add a `view` state: `'day' | '3day' | 'week' | 'month'` (default `week`, preserving today's behavior).
- A **`ViewSwitcher`** (segmented control) in the top bar (reproducing the prototype `ViewSwitcher`),
  wired to set `view`. **Year is omitted** (the prototype's year tab routes to the Booking screen —
  out of scope).
- Per-view **navigation**: prev/next steps by the view's unit (day ±1, 3-day ±3, week ±7, month ±1
  month); **Today** resets to now; the range label adapts (e.g. month → "Июнь 2026").

**Time-grid views (day / 3-day / week)** — parametrize the existing grid

- Extract the day-count + start-date from `view`+`anchor`: day → `[anchor]`, 3-day → `anchor..+2`,
  week → `mondayOf(anchor)..+6`. Render the slice-1 time grid with **N day columns** (1/3/7); the
  hour gutter, now-line (today's column), today highlight, lanes, `EventBlock`, and the slot-click →
  create-popover all carry over unchanged.
- The events **query window** = the visible day range (`[start, end]`).

**Month view** — new `features/calendar/MonthView.tsx`

- A 6×7 grid (reproducing the prototype `MonthView`): weekday headers, each day cell shows up to 3
  events (colour dot + title) + "+N more", **today** highlight, in-month vs out-of-month + weekend
  styling. Clicking a day-cell → switch to **day** view on that date. Month cells are **read-only event
  previews** — there is no per-event popover in month view (editing is via the time-grid views).
- Events from the real query over the **month grid window** (`startOfWeek(firstOfMonth)` .. +41 days).

**Mini-month + left-rail scaffold** — new `features/calendar/MiniMonth.tsx`

- A compact month navigator (reproducing the prototype `MiniMonth`): its own month chevrons, weekday
  headers, day cells with **today/selected** highlight; clicking a day sets the calendar `anchor`,
  **preserving the current view** (Google-Calendar-faithful: week stays week showing that week, day
  shows that day). **Booking marks are out of scope** (slice 7 — render the navigator without the
  bottom dot-strip).
- A **left-rail scaffold** (~the prototype's 290px rail) that holds the mini-month now and leaves room
  for the tasks/habits/goals **side panel** (slice 5 — a placeholder/empty region, not its content).

**Keyboard shortcuts** (the set deferred from slice 1)

- `d` → day, `w` → week, `m` → month, `3` → 3-day; `t` → today; `n`/`p` (and `j`/`k`) → prev/next.
  Scoped to the calendar page; ignored while typing in an input or while the popover/dialog is open.

# Out of scope

- **Year view** and the **Booking screen** (the prototype's year tab → Booking — a separate feature).
- **Booking marks** in the mini-month / month cells (slice 7 — needs the `bookings` data).
- The **side-panel content** (tasks/habits/goals tabs — slice 5; this slice only scaffolds the rail).
- **Drag / move / resize** (slice 4); **golden/prime-time** bands (slice 8).
- New **client-side recurrence expansion** — render what `listEvents` returns; no server/API change.

# Acceptance criteria

- [ ] `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`
      all green.
- [ ] The view switcher toggles **day / 3-day / week / month**; the time-grid renders 1 / 3 / 7 day
      columns; month renders the 6×7 `MonthView` with up to 3 events/day + "+N more".
- [ ] Prev/next steps by the view's unit and `listEvents` is called with the **matching window**;
      Today resets to now; the range label adapts per view.
- [ ] The **mini-month** in the left rail picks a date → the grid moves there **in the current view**;
      today + selected day are highlighted; no booking-mark dots.
- [ ] The slice-2 **popover** still opens from a slot/event click in **every** time-grid view; month
      day-click switches to day view; events CRUD + recurrence scope unaffected.
- [ ] **Keyboard shortcuts** (`d`/`w`/`m`/`3`, `t`, `n`/`p`/`j`/`k`) switch view / navigate, and are
      ignored while typing in a field or while the popover/dialog is open (tested).
- [ ] No hardcoded strings (i18next `ru` + `en`); the diff is surgical — `features/calendar/*`
      (+ `MonthView.tsx`/`MiniMonth.tsx`) and locale files; no server change.
- [ ] Before/after screenshots (each view + the mini-month, light + dark) vs the prototype.

# Verification commands

```sh
cd superapp/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```
