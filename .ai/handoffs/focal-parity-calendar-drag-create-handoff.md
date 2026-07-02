# Stage

3-Gate flow — Gate C (verify), release gate. Feature `focal-parity-calendar-drag-create`.

# What changed

Brings old-focal's **drag-to-create** to the new Focal calendar: press on an empty grid slot and drag to
draw a time range, then release to open the create popover seeded with that range. The new app could only
click a slot to make a fixed one-hour event.

- **B1 — `createDraftFromRange`** (`features/events/eventsFilters.ts`): seeds the create draft from a
  dragged `[startMin, endMin]` — orders the bounds (drag up reads the same as drag down), snaps both to
  15-min, guarantees at least one slot, and caps the end at `23:59`; every other field matches `createDraft`.
- **B2 — the interaction** (`TimeGrid.tsx`): a native pointer state machine on the day column, built like
  the existing move/resize (no dnd-kit). `pointerdown` on a `data-slot` stores the **originating** column +
  date; `pointermove` past a 4px threshold captures the origin column and previews a ghost (`timeToY`);
  `pointerup` resolves against the origin and calls `onCreateDrag(originDate, startMin, endMin)`. The whole
  gesture is anchored to the origin, so a drag that wanders to an adjacent column still creates on the day it
  started. A real drag swallows the trailing slot click (so it doesn't also one-hour-create); a plain click
  still makes the one-hour event (the per-slot buttons keep their keyboard focus + aria labels). Touch
  pointers are ignored (vertical scroll keeps working), presses on an existing event start a move instead,
  pointer-cancel drops the selection, and the whole thing is gated by `canEdit`. `CalendarPage.openCreateDrag`
  seeds `createDraftFromRange` into the existing create popover.

# Files touched

- `apps/focal/client/src/features/events/eventsFilters.ts` + `eventsFilters.test.ts` — `createDraftFromRange` + tests.
- `apps/focal/client/src/features/calendar/TimeGrid.tsx` — the pointer state machine, ghost, `data-slot`, `onCreateDrag` prop.
- `apps/focal/client/src/features/calendar/CalendarPage.tsx` — `openCreateDrag` wiring.
- Tests: `TimeGrid.test.tsx` (drag→range+ghost, click-not-drag, click-swallow, drag-up, cross-column origin, stale-guard reset, pointercancel, touch-ignored, read-only, event-press), `CalendarPage.test.tsx` (a drag opens the popover pre-filled).

# Tests run

```sh
cd superapp-parity/apps/focal/client
pnpm typecheck   # 0 errors
pnpm lint        # 377 files, clean
pnpm test:run    # 132 files, 1630 tests passed
pnpm build       # OK
```

Gate A (design) APPROVED 9.2 · Gate B (build) APPROVED 9.1 (after anchoring the gesture to the originating
column so a cross-column release creates on the right date, + drag-up / stale-guard / pointer-cancel tests).

# Still needs review

- Deferred follow-ups: touch long-press create (old-focal's mobile path); creating across day columns in one
  drag (a drag stays one day).

# PR / release notes (for users — stage 5)

You can now **drag on an empty part of the calendar to create an event** of exactly the length you draw:
press where it should start, drag to where it should end, and release — the new-event form opens pre-filled
with that time range (snapped to 15 minutes). A plain click still creates a one-hour event, and dragging on
a read-only shared calendar does nothing.

No secrets, tokens, keys, or PII in this text or the diff.

# Status

OPUS APPROVED (9.4) — release gate cleared. Based on origin/feature/focal-migration 63f69a8.
