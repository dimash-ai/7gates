# Design: focal-parity-calendar-drag-create

## Problem & decision

old-focal lets you **drag on an empty part of the day grid to create an event spanning the dragged time
range** (the "ghost" selection in `apps/old-focal/client/src/components/CalendarViews.tsx` —
`ghostEvent` / `EventGhost`). The new app can only **click** an hour slot, which always makes a fixed
one-hour event (`TimeGrid.tsx` slot button → `onCreate(dateIso, hour)` → `createDraft` = `hour:00`–
`hour+1:00`). There is no way to draw a 30-minute or a three-hour event in one gesture.

**Decision: add a native pointer drag-create on the day column, reusing the just-merged `geometry`
coordinate system and the existing create popover.** Concretely:
- The new app already drives move/resize with **native pointer events** (not dnd-kit, which old-focal
  uses), so drag-create is built the same way for consistency: `pointerdown` on an empty grid slot →
  track `pointermove` → `pointerup`. The pointer Y maps to a minute via **`yToMinutes`** (the variable-row
  module shipped in the previous slice), snapped to the 15-min grid; a translucent **ghost** block
  (`timeToY(start)`…`timeToY(current)`) previews the selection during the drag.
- On release: a real drag (moved past a small threshold) opens the **existing** create popover seeded with
  the dragged `[start, end]` range; a press with no drag is just a click and keeps today's one-hour create.
- Click-create stays for accessibility (the per-hour slot `<button>`s keep their keyboard focus + aria
  labels); drag is an enhancement layered on top, and a completed drag swallows the trailing slot click
  (the same `justDragged` guard `EventBlock` already uses for move).

**Reuse-first (CLAUDE.md #2):** `yToMinutes`/`timeToY` (geometry), `snapMinutes` + the minute→`HH:MM`
end-of-day cap (dates), the create popover + its mutation, and the click-vs-drag guard pattern all exist —
this slice is a pointer state machine + a ghost element + a range-seeded draft helper.

**Alternatives rejected:**
- **dnd-kit (as old-focal)** — rejected; the new grid deliberately uses native pointer events for
  move/resize, and adding a DnD library for one gesture is the opposite of reuse-first.
- **Replace the per-hour click buttons with one column pointer handler** (unify click+drag) — rejected;
  it would drop the per-slot keyboard buttons + aria labels (an a11y regression). Keep click, add drag.
- **Create immediately on release without the popover** — rejected; old-focal opens an editor and the new
  app's whole create flow is the popover; seeding it with the range matches both.

## Assumptions & scope

- **(confirmed — code)** `TimeGrid` day column (`[data-day-column]`) stacks: the prime-band (pointer-events-
  none), the per-hour slot `<button>`s (click → `onCreate(dateIso, hour, anchor)`), the now-line (inert),
  and the `EventBlock`s (`absolute z-[3]`, above the slots). `geometry.ts` provides `timeToY`/`yToMinutes`/
  `rowHeight`; `dates.ts` provides `snapMinutes` (15) + the minute→time cap. `CalendarPage.openCreate`
  seeds `createDraft(dateIso, hour)` and opens the popover.
- **(confirm at build)** the exact minute→`HH:MM` formatter to reuse for an arbitrary start/end (the one
  the existing drag-move/resize uses, which caps 1440→`23:59`); how to exclude a `pointerdown` that lands on
  an `EventBlock` (mark slots with `data-slot` and only start a drag from a slot — `EventBlock`s sit above
  the slots so they intercept their own presses); the ghost's z-order vs the prime-band/now-line.
- **Out of scope:** touch long-press create (old-focal's mobile path). Drag-create **ignores
  `pointerType === 'touch'`** (mouse/pen only) so a vertical touch-scroll is never hijacked; touch still
  taps to click-create. Also out: creating across day columns in one drag (one day, like the click);
  changing the click-create's one-hour default.
- **Open questions:** None blocking.

## Success criteria

- [ ] Pressing on an empty grid slot and dragging down (or up) draws a ghost selection, and releasing opens
      the create popover seeded with the dragged range, snapped to 15-min bounds (start < end, ≥ one slot).
- [ ] A plain click on a slot still creates the existing one-hour event (no regression); a completed
      drag-create does **not** also fire the slot's click.
- [ ] A drag never produces a time outside `00:00–23:59` (the bottom of the day clamps to `23:59`).
- [ ] `pointerdown` on an existing event still starts a move/resize (drag-create does not hijack it), and
      drag-create is disabled on a read-only calendar (`!canEdit`), like the click slots.
- [ ] Dragging up (end above start) creates the same range as dragging down (the bounds are ordered).
- [ ] All strings i18n ru+en (the create popover is unchanged; the ghost has an aria-label); the suite stays
      green (`pnpm lint && typecheck && test:run && build`).

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| B1 | range draft helper | `features/events/eventsFilters.ts` (`createDraftFromRange(dateIso, startMin, endMin): EventDraft` — snap + order + end-of-day cap, reusing the dates formatter), test | inverted/zero-length range; a time past 23:59 | a range seeds `startTime`/`endTime` (snapped, ordered); dragging up orders the bounds; a past-midnight end caps to `23:59`; the rest of the draft matches `createDraft` |
| B2 | drag-create interaction | `features/calendar/TimeGrid.tsx` (column pointer state machine + ghost + `data-slot` + threshold + click-swallow; **`setPointerCapture`/release** like `EventBlock` so a pointerup outside the column can't strand the drag; **ignore `pointerType==='touch'`**; `onCreateDrag` prop), `CalendarPage.tsx` (`openCreateDrag` → range draft + popover; wire `onCreateDrag`), tests | drag hijacks an event move; click double-creates; ghost misaligned; read-only leak; drag stuck after an outside release | a drag opens the popover with the ranged draft; a click still makes the 1-hour event and a drag suppresses it; a press on an event starts a move not a create; `!canEdit` disables it; the ghost spans `timeToY(start)`…`timeToY(end)` |

Each slice leaves `pnpm lint && typecheck && test:run && build` green and is committed on the branch.

## Architecture & contracts

```
features/events/eventsFilters.ts
  createDraftFromRange(dateIso, startMin, endMin) → EventDraft   // order + snapMinutes + minute→HH:MM cap; else = createDraft defaults

features/calendar/TimeGrid.tsx
  slot <button> gains data-slot (a11y click-create unchanged)
  day column onPointerDown → if target.closest('[data-slot]'): record startMin = snap(yToMinutes(clientY-colTop)); arm
            onPointerMove → past threshold: dragging; ghostRange = order(startMin, snap(yToMinutes(...))); render ghost
            onPointerUp   → if dragging: onCreateDrag(dateIso, lo, hi, anchor); set justDragCreated
            onClickCapture→ if justDragCreated: swallow the trailing slot click
  new prop onCreateDrag?(dateIso, startMin, endMin, anchor)

CalendarPage.tsx
  openCreateDrag(dateIso, startMin, endMin, anchor) → setDraft(createDraftFromRange(...)) + open create popover
  <TimeGrid onCreate={openCreate} onCreateDrag={openCreateDrag} … />
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `createDraftFromRange` (new, pure) | `(dateIso, startMin, endMin) → EventDraft` | snap + order + cap; reuses `createDraft`'s field defaults |
| `TimeGrid` props | add `onCreateDrag?` | absent / `!canEdit` → drag-create inert (click only) |
| `TimeGrid` internals | pointer state machine + ghost + `data-slot` + click guard | mirrors `EventBlock`'s native-pointer + `justDragged` pattern |
| `CalendarPage` | `openCreateDrag` seeds the range draft + opens the popover | reuses the existing create mutation/popover unchanged |
| data model / API | **None** | client interaction only; the create payload is unchanged |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| drag to create | pointerdown on a slot + move + up | `TimeGrid` → `onCreateDrag` | create popover seeded with the dragged 15-min-snapped range |
| click to create | pointerdown + up, no drag | slot `<button>` onClick | the existing one-hour create (unchanged) |
| drag past the bottom | pointer below the grid | `yToMinutes` cap → minute→time cap | end clamps to `23:59` |
| drag up | end above start | `order(lo, hi)` | same range as dragging down |
| press on an event | pointerdown on an `EventBlock` | `EventBlock` (above the slots) | a move/resize starts; drag-create never arms |
| read-only | `!canEdit` | `TimeGrid` | slots disabled + `onCreateDrag` not wired → inert |

## Test strategy, security & rollback

- **Test strategy.** Unit (`eventsFilters.test`): `createDraftFromRange` orders the bounds, snaps to 15-min,
  caps the end at `23:59`, and otherwise matches `createDraft`. Component (`TimeGrid.test`): a pointer
  down-move-up on a slot fires `onCreateDrag` with the ordered snapped range and renders a ghost spanning
  `timeToY(lo)`…`timeToY(hi)`; a down-up with no move does **not** fire `onCreateDrag` (the click path runs);
  a completed drag swallows the slot click; a press on an `EventBlock` fires move, not create; `!canEdit`
  arms nothing. Integration (`CalendarPage.test`): a drag opens the create popover with the range
  pre-filled. "Verified" = those + `pnpm lint && typecheck && test:run && build` green.
- **Security.** Pure client interaction; the create goes through the unchanged, RBAC/RLS-guarded create
  endpoint; `canEdit` gates it client-side; no secrets/PII; the time stays in the backend-valid `00:00–23:59`.
- **Rollback.** Pure frontend, no migration — revert the PR; the helper + interaction are self-contained.
