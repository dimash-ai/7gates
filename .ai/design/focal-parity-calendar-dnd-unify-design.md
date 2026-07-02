# Design: unify calendar event drag onto dnd-kit (old-focal parity)

> **Status: BUILT — PR [#134](https://github.com/Allosta-Group/superapp/pull/134)** (`feat/focal-calendar-dnd-unify` → `feature/focal-migration`). All three pieces landed as designed; full focal-client suite green (1667), typecheck + Biome + i18n clean. Two test-driving notes worth keeping: dnd-kit's `MouseSensor` is drivable in happy-dom only if the 8 px threshold is crossed by an earlier move (then `delta.y = finalY − mousedownY`); and after a drag the sensor keeps a capture-phase `click` suppressor on the document for a **real** 50 ms, so a deliberate next click in a test (scope-confirm, undo) must wait it out. Runtime confirmation of the stray-popover fix is pending — focal-dev deploys from `feature/focal-migration`, so it can only be checked once this merges.

> Seeded by `/gate-explore focal-drag-parity` ([notes](../notes/focal-drag-parity.md)). The user chose
> **path A — go straight to the dnd-kit unification** (exactly old-focal's architecture), not the
> targeted patch. Slice branch `feat/focal-calendar-dnd-unify` off `feature/focal-migration`.

## Problem

New-focal's calendar event drag is a **hand-rolled pointer system** (`EventBlock` `onPointerDown/Move/Up`
+ `setPointerCapture` + a manual `createPortal` overlay), separate from the **dnd-kit** task drag and
the **hand-rolled** slot drag-create. The seams between these three systems cause the glitch the user
hit: after dragging an event, the browser's synthesized trailing click lands on a slot's single-click
`onCreate` and opens a stray "Новое событие" popover — there is no grid-wide post-drag suppression.

Old-focal has none of these seams: events are dnd-kit draggables in the **same** `DndContext`, with one
`DragOverlay`, and a **post-drag cooldown** (`isDragCooldown` → grid `pointerEvents:none` ~300ms) that
swallows the synthesized click.

## Goal / non-goals

- **Goal:** event body-drag becomes a dnd-kit `useDraggable` inside the existing `DndContext`; one
  `onDragEnd` routes task-schedule, event-move, and event→task-convert; a 300ms cooldown makes the grid
  inert after any drag. Behaviour (move math, convert, recurring-scope, optimistic move, undo) unchanged.
- **Non-goals:** edge-resize stays hand-rolled pointer (old-focal keeps it too); no change to the
  single-click slot-create gesture; no month-view event drag (it has none today); no backend change.

## Mechanism (the three old-focal pieces we port)

1. **Event = dnd-kit draggable.** `EventBlock` body uses
   `useDraggable({ id: eventDragId(event.id), data: { event }, disabled: !canEdit })`; `setNodeRef` +
   `{...listeners} {...attributes}` on the button, `data-event-id={event.id}`. While `isDragging`, the
   block stays in place dimmed (`opacity: 0.4`, no transform) — the moving copy is the page's
   `DragOverlay`. Delete the hand-rolled body drag (`dragRef`/`ghost`/`onPointer*`) and the `createPortal`
   clone. Keep the edge-resize pointer handlers and `justDraggedRef` (now guarding **only** the
   resize-click, since resize is not a dnd-kit gesture and is not covered by the cooldown).
2. **One DndContext, one onDragEnd, one DragOverlay** (in `CalendarPage`). Sensors switch from
   `PointerSensor{distance:6}` to **`MouseSensor{distance:8}` + `TouchSensor{delay:400,tolerance:8}`**
   (old-focal's exact constants — desktop drags after 8px, touch needs a 400ms long-press so it doesn't
   fight scroll). `onDragStart`: branch on `parseDragId` kind — a `task` sets `activeDragTask`; an
   `event` sets `activeDragEvent` (+ capture the source `[data-event-id]` rect for the overlay size) and
   `setEventDragActive(true)` (the task-panel convert hint). `onDragEnd` routes by kind:
   - **event over the task panel** (`isOverTaskPanel`) → `handleConvertEventToTask(event)`.
   - **event over a day column** → `resolveEventDrop` (below) → `handleMove(event, patch)` (which already
     routes recurring events through the scope dialog and non-recurring through the optimistic mutation).
   - **task** → existing `resolveGridSlot`/`resolveMonthDay` → `handleScheduleTaskOnDate`.
   The `DragOverlay` renders the active task chip **or** the active event clone (the colored title/time
   box lifted from the deleted portal). Always clear active state + `eventDragActive`, and **start the
   cooldown**, at the top of `onDragEnd`.
3. **Post-drag cooldown.** `CalendarPage` owns `dragCooldown` state + a timeout ref; `startCooldown()`
   sets it true and clears it after 300ms (cleared on unmount). `TimeGrid` takes a `dragCooldown` prop
   and applies `style={{ pointerEvents: dragCooldown ? 'none' : undefined }}` on its scroll container —
   so the synthesized post-drag click hits nothing (no stray create, no stray open). Applied for **any**
   drag end (event or task), matching old-focal's intent and covering the task-drop click too.

### `resolveEventDrop` (pure-ish helper in `dnd.ts`, unit-testable like `resolveGridSlot`)

```
resolveEventDrop(startTime, endTime, deltaY, pointerX) -> { dateIso, startTime, endTime } | null
```
- `dateIso` = the `[data-day-column]` whose x-span contains `pointerX` (null = outside any column →
  caller cancels). Day changes by which column the pointer ends over.
- New start = `yToMinutes(timeToY(minutesOf(startTime)) + deltaY)`, then `snapMinutes`, then
  `clampMinutes(_, 0, END_OF_DAY_MINUTES - duration)`. Using `timeToY`/`yToMinutes` (the variable-row
  geometry inverse) makes the delta-based start exactly match the `DragOverlay` visual — and matches
  what the old hand-rolled `resolveDrop(clientX, clientY, grabOffset)` computed, with no grab-offset
  bookkeeping (the algebra cancels: `pointerY - grabOffset = blockTop + deltaY`).
- Duration preserved; open-ended events (`endTime === null`) stay open-ended.
- Caller no-ops when `dateIso === event.date && newStart === event.startTime`.

`pointerX/Y` come from `activatorEvent.clientX/Y + delta` (same as the existing task path). The
`DndContext` stays **modifier-free**, so `delta` is the raw pointer delta (no snap modifier to distort
it — we snap inside the helper instead).

## Files

- `features/calendar/dnd.ts` — add `eventDragId`; extend `DragKind`/`parseDragId` to `'task' | 'event'`;
  add `resolveEventDrop` (imports `minutesOf`/`formatMinutes`/`snapMinutes`/`clampMinutes`/
  `DEFAULT_DURATION_MINUTES`/`END_OF_DAY_MINUTES` from `./dates`, `timeToY`/`yToMinutes` from `./geometry`).
- `features/calendar/EventBlock.tsx` — body → `useDraggable`; delete hand-rolled body drag + portal +
  `resolveDrop`/`onMove`/`onConvertToTask`/`onDragActiveChange` props + `isOverTaskPanel`/`createPortal`
  imports; keep resize + `onResize`; `justDraggedRef` now guards only resize.
- `features/calendar/CalendarPage.tsx` — sensors → Mouse+Touch; `activeDragEvent` + cooldown state;
  extend `onCalendarDragStart`/`onCalendarDragEnd`; `DragOverlay` renders event clone; stop drilling
  `onMove`/`onConvertToTask`/`onDragActiveChange` into `TimeGrid`; pass `dragCooldown`.
- `features/calendar/TimeGrid.tsx` — drop `onMove`/`resolveDrop`/`onConvertToTask`/`onDragActiveChange`
  from the `EventBlock` call + the `resolveDrop` `useCallback`; add `dragCooldown` prop →
  `pointerEvents` on the scroll container. Keep slot drag-create + `onResize`.

## Test plan

- `dnd.test.ts` — `parseDragId('event:…')`; `resolveEventDrop` (mock `[data-day-column]` rects): day
  change across columns, duration preserved, open-ended stays open-ended, clamp at end-of-day, null
  outside columns.
- `EventBlock.test.tsx` — drop the body-drag/portal/convert cases; assert the body is a drag handle
  (`setNodeRef`/listeners present, `data-event-id`), `isDragging` dims in place; keep the resize cases.
- `CalendarPage.test.tsx` — keep it green under the sensor swap; cover `onDragEnd` event routing at the
  helper level (full dnd-kit pointer simulation in happy-dom is brittle — assert `resolveEventDrop` +
  the convert/move branch wiring rather than synthesizing sensor gestures).
- Manual on focal-dev: drag a week event across days/times (overlay follows, drops correctly, **no stray
  "Новое событие"**); drag onto the task panel → converts; recurring drag → scope dialog; resize still
  works; touch long-press drags, short touch scrolls.

## Risks

- **Cooldown vs. synthesized-click timing** (React flush before the click macrotask). Mirror old-focal
  (setState cooldown); if it proves flaky in the browser, add a synchronous imperative `pointerEvents`
  set via a ref as a belt. Verify on focal-dev before merge.
- **Sensor swap** (`PointerSensor`→`Mouse+Touch`) could touch existing task-drag tests — adjust to the
  matching event type; the grip-handle task drag itself is unchanged behaviorally.
- **i18n:** no new user-facing strings expected (convert hint + untitled already exist). If any appear,
  add RU+EN.
