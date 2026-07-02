# Design: focal-parity-calendar-interactions

## Problem & decision

On the day / 3-day / week time grid, events cannot be **moved or resized by direct manipulation**.
old-focal lets you drag an event block to a new time/day and drag its top/bottom edge to change
duration; the new app's `EventBlock` is a plain button that only opens the editor (`features/calendar/
EventBlock.tsx` — "no drag/resize"). This is the most-felt missing calendar interaction now that the
grid itself (year view, all-day strip, scroll-to-work, now-line, lane packing, create buttons) has
landed.

**Decision:** add pointer-based **drag-to-move** and **edge-resize** directly on `EventBlock` inside
`TimeGrid`, snapped to **15-minute** increments, persisted through the **existing** `updateEvent`
mutation with an **optimistic** cache update + rollback, **gated by `canEdit`**, and routing a
recurring-event edit through the **existing** `RecurringScopeDialog`. The pixel↔time mapping is
already linear and uniform (`HOUR_HEIGHT = 48`), so this is geometry + native Pointer Events, no new
surface.

This feature is the **first slice of the remaining calendar-interaction parity (plan slice 6)** — the
direct-manipulation core. The rest of slice 6 (prime-time, task side-panel + convert, undo, bookings)
follows as subsequent 3-gate features (see Out of scope).

**Alternatives rejected:**
- **dnd-kit (or any DnD lib):** overkill for a single-surface, axis-aware drag where the mapping is
  already linear; native Pointer Events + a small helper is simpler and adds no dependency (reuse-first).
- **Variable row heights** (tall work hours / compressed non-work, from old-focal): the new app's
  **uniform** grid is a deliberate, cleaner choice and keeps the drag/resize math linear — not
  reintroduced.

## Assumptions & scope

- **(confirmed — code)** `TimeGrid` uses fixed `HOUR_HEIGHT = 48` with linear `top/height` geometry;
  `canEdit` already gates the click-to-create slots; the single scroll container owns both axes.
- **(confirmed — code)** `EventBlock` renders one timed event, absolutely positioned by `top/height/
  lane/laneCount`, and exposes `onSelect(event, anchor)` (opens the editor). All-day events render in
  a separate sticky strip and never enter the timed lanes.
- **(confirmed — audit)** `CalendarPage` already owns the `updateEvent` mutation and renders
  `RecurringScopeDialog` for the edit-popover path — both reused here.
- **(unverified — confirm at build)** `updateEvent`'s patch accepts `date` + `startTime` + `endTime`
  as wire strings; the events query cache key shape for the optimistic patch. Settle in B1.
- **Out of scope** (deferred — the remaining slice-6 follow-up features): prime-time band + dialog
  (needs settings backend), task side-panel + task↔event convert, the undo stack, the bookings/«пометки»
  overlay + filters, the read-only `EventInfoDialog` action set (copy/duplicate/convert/status),
  variable row heights, drag-to-create-by-drag (click-to-create stays).
- **Open questions:** None blocking.

## Success criteria

- [ ] Dragging an event's **body** to a new slot moves it: the block follows the pointer, lands on the
      15-min-snapped time, can cross day columns, **preserves duration**, and persists.
- [ ] Dragging the **top** or **bottom** edge changes start or end, snapped to 15 min, **min 15-min**
      duration, and persists.
- [ ] A failed update **rolls the block back** to its original position with a localized error.
- [ ] On a read-only calendar (`!canEdit`) there are **no** drag/resize affordances and the block can't
      be moved or resized.
- [ ] A drag on a **recurring** event routes through the existing scope dialog (this / following / all).
- [ ] A plain **click** (movement below the drag threshold) still opens the editor — no accidental move;
      and conversely a **completed drag/resize does NOT also fire the click-to-edit** (`EventBlock` is a
      `<button>` with `onClick`, so the drag must suppress the trailing click).
- [ ] A move/resize to the **bottom of the day never produces an out-of-range time** — `startTime`/
      `endTime` stay within `00:00–23:59` (the end-of-day boundary persists as `"23:59"`).
- [ ] Moving an **open-ended** event (`endTime: null`) keeps it open-ended (end stays `null`, start
      shifts); resizing its **bottom** edge materializes an `endTime`.
- [ ] **All-day** events are not draggable/resizable.

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| B1 | Drag-to-move | `features/calendar/dates.ts` (geometry helper), `EventBlock.tsx` (pointer move-drag + ghost), `TimeGrid.tsx` (thread `onMove`, day-from-x), `CalendarPage.tsx` (`onMove`→ scope dialog → optimistic `updateEvent` + rollback) | pointer math off-by-one; a click misfires as a drag | a body drag computes the snapped target day+start, preserves duration, calls `updateEvent`; a sub-threshold press opens the editor instead; rollback on error; **no-op when `!canEdit`**; recurring routes through the scope dialog |
| B2 | Edge-resize | `EventBlock.tsx` (top/bottom handles, shown only when `canEdit`), `TimeGrid.tsx`/`CalendarPage.tsx` (`onResize`→`updateEvent`) | resize below min duration; wrong edge moves both | resizing the top/bottom edge yields a new start/end snapped to 15 min with a 15-min floor; persists; **no handles when `!canEdit`** |

Each slice leaves `pnpm lint && typecheck && test:run && build` green and is committed on the branch.

## Architecture & contracts

```
TimeGrid (owns scroll geometry; passes onMove/onResize + day rects)
   └─ EventBlock (pointer drag/resize → local "ghost" offset; on pointerup → onMove/onResize)
        ↑ canEdit gates handles + body-drag
CalendarPage (onMove/onResize → [recurring? RecurringScopeDialog] → updateEvent optimistic + rollback)
   └─ updateEvent  (EXISTING mutation; backend RBAC+RLS enforce write perms — second line)
dates.ts: snapMinutes(pixels) ⇄ pixels; HOUR_HEIGHT, SNAP=15
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `dates.ts` | add `offsetToMinutes(px)`/`minutesToOffset(min)`, `snapMinutes(min)` (→ nearest 15), `formatMinutes(min)` | pure; `HOUR_HEIGHT/4` px per 15-min step. **`formatMinutes` caps minute `≥ 1440` to `"23:59"`** so every persisted time is in the backend-valid `00:00–23:59` range (matches `server/app/schemas/calendar.py` `_normalize_time`) — no `"24:00"`/overflow ever reaches the API |
| `EventBlock` props | add `onMove(event, {date,startTime,endTime})`, `onResize(event,{startTime,endTime})`, `canEdit`, day-column rects (or a `resolveDayFromX`) | a movement threshold (~4px) distinguishes drag from click; during drag, a local offset renders the ghost — **no** data mutation until pointerup |
| `TimeGrid` props | thread `onMove`/`onResize`; supply day-column geometry for cross-column moves | reuses the existing column rects it already computes for create |
| `CalendarPage` | `handleMove`/`handleResize` → recurring? scope dialog : direct → optimistic `updateEvent` patch on the events cache + rollback | mirrors the existing edit-popover update path; wire-string times, no epoch math |
| data model | **None** | no schema/API change — reuses `updateEvent` |

**Time clamp policy (backend-valid).** The backend accepts `00:00–23:59` only (`_normalize_time`),
so the geometry never emits an out-of-range time:
- **Move** (preserve duration `d`): `newStart = clamp(snapMinutes(raw), 0, 1440 − d)`, `newEnd = newStart + d`.
- **Resize top:** `newStart = clamp(snapMinutes(raw), 0, endMin − 15)`; **resize bottom:** `newEnd = clamp(snapMinutes(raw), startMin + 15, 1440)`. Minimum duration **15 min**.
- Every persisted `startTime`/`endTime` is rendered by `formatMinutes`, which maps the end-of-day
  boundary `1440` → `"23:59"` (the end-of-day form `dates.ts` `isAllDay` already accepts), all other
  minutes → `HH:MM`. So a drag/resize to the very bottom of the day stays valid; the only edge effect
  is a ≤1-min trim when an event is pushed to end exactly at midnight — documented and acceptable.
- **Open-ended events (`endTime: null`)** — a valid timed state (`dates.ts:38`; `TimeGrid` renders it
  with a 60-min default visual). **Move keeps the end `null`**: it shifts only the start (clamped by the
  *effective* duration `endMin ?? startMin + DEFAULT_DURATION`) and never materializes an end, so an
  open-ended event's duration/analytics semantics are preserved. **Resize-bottom** is the explicit act
  of giving an event an end, so it **materializes** `endTime` (null → the snapped dragged value);
  **resize-top** sets only `startTime` and leaves a null end null.

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — move | pointerdown on body, move >4px, pointerup on a slot | `EventBlock` drag → `onMove` → `CalendarPage` | persists at snapped new day/time, duration preserved |
| happy — resize | pointerdown on an edge handle, drag, pointerup | `EventBlock` → `onResize` | start or end updated, 15-min floor |
| recurring | move/resize a recurring event | `CalendarPage` opens `RecurringScopeDialog` | chosen scope applied via `updateEvent` |
| update fails | `updateEvent` rejects | mutation `onError` | block rolls back to original position; localized error |
| read-only | `!canEdit` | `EventBlock` renders no handles; body pointerdown ignored | no move/resize possible (and backend would reject anyway) |
| accidental click | pointerdown→pointerup below threshold | `EventBlock` | treated as click → opens the editor (no move) |
| all-day | event in the all-day strip | `TimeGrid` (strip has no drag handlers) | not draggable/resizable |

## Test strategy, security & rollback

- **Test strategy.** Unit: the `dates.ts` geometry helper (pixels↔snapped minutes, clamping, and
  day-from-x). Component (happy-dom + `pointer` events via `@testing-library/user-event`): a body drag
  moves a block and calls `onMove` with the snapped target + preserved duration; a top/bottom resize
  calls `onResize` with the 15-min floor; a sub-threshold press opens the editor while a **completed
  drag suppresses the click-to-edit**; a move/resize at the **day's bottom edge clamps to 00:00–23:59**
  (end-of-day → `"23:59"`); **a null-end event stays null-end on move and materializes its end on a
  bottom-resize**; `canEdit=false` renders no handles and ignores body-drag; a recurring drag
  opens the scope dialog; a rejected `updateEvent` rolls the block back. "Verified" = those plus
  `pnpm lint && typecheck && test:run && build` green.
- **Security.** No new surface. The drag/resize only calls the existing `updateEvent`; write
  authorization stays server-side (RBAC + RLS) — the `canEdit` client gate is UX, not the boundary, so
  a read-only viewer is blocked both client- and server-side. No secrets/PII.
- **Rollback.** Pure frontend, no migration — revert the PR.
