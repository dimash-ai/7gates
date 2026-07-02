# Findings: focal-drag-parity — what reaches exact old-focal drag behavior

> Output of the **explore gate** (`/gate-explore focal-drag-parity`). Two independent takes — Opus +
> GPT — synthesized. Raw answers in `.ai/scratch/focal-drag-parity-{opus,gpt}.md` (gitignored). Not
> scored. Date: 2026-06-29.

**Symptom:** on `focal-dev` the calendar drag is glitchy — dragging an event sometimes opens a stray
"Новое событие" create popover; the user wants it **exactly** like the working old-focal.

## Questions
1. Why does dragging an event open a stray "Новое событие" popover / feel glitchy?
2. How does new-focal's drag architecture differ from old-focal's — and is that the cause?
3. What's needed for EXACT old-focal parity — targeted fixes, or unify on dnd-kit?
4. Concretely, which pieces does old-focal have that new-focal lacks?

## Consensus

- **Root of the stray "Новое событие": a synthesized trailing click after the event's captured-pointer
  drag lands on a slot's single-click create, and nothing suppresses it grid-wide.** Confidence: **High.**
  Evidence: the event drag only swallows the click *on the event button itself* (`EventBlock.tsx`
  `justDraggedRef`), and `TimeGrid` only suppresses the trailing click after *slot* drag-create
  (`justDragCreatedRef`) — **not** after an event move. The empty slot creates on a single click
  (`TimeGrid.tsx:489` `onClick={onCreate}`). So a click delivered to a slot after an event drag fires
  `onCreate`. old-focal blocks this two ways new-focal lacks: a **post-drag cooldown** (`isDragCooldown`
  → grid `pointerEvents:none` ~300ms, `CalendarViews.tsx:1758/2247/2457`) **and** a **double-click**
  desktop slot-create (`CalendarViews.tsx:1629`) so a single stray click never creates.
- **Architecture is the underlying gap: new-focal is a hand-rolled HYBRID; old-focal is one unified
  dnd-kit gesture.** Confidence: **High.** New-focal = pointer-drag for events (`EventBlock`) + a
  separate pointer drag-create for slots (`TimeGrid`) + dnd-kit only for the task panel
  (`CalendarPage`). old-focal routes events through one `DndContext` (`useDraggable` events +
  `DragOverlay` + `MouseSensor{distance:8}` + `TouchSensor{delay:400,tolerance:8}` + central
  `onDragEnd`, `CalendarViews.tsx:46/757/1868`). Every new-focal glitch sits at a seam between two
  hand-rolled gesture systems; old-focal has one owner, so no race.
- **Two viable paths, and both models recommend the same sequencing.** Confidence: **High.**
  **(B) targeted now** — add a post-drag cooldown + suppress-the-next-slot-click after any event
  move/resize (+ optionally make desktop slot-create a double-click, + a touch activation delay): this
  kills the stray popover with a small diff. **(A) exact parity** — migrate the event drag onto the same
  dnd-kit `DndContext` as tasks (one overlay, one sensor set, central drag-end routing), deleting the
  hand-rolled event pointer-drag. "Exactly like old-focal" = path A.
- **Concrete pieces old-focal has that new-focal lacks** (Confidence: **High**):
  1. Post-drag **cooldown** (`pointerEvents:none` ~300ms) — the direct fix for the stray popover.
  2. **Double-click** (not single-click) desktop slot-create — a single stray click can't create.
  3. **Touch long-press to drag** (`TouchSensor{delay:400}`) — new-focal arms on 4px for any pointer
     type, so a mobile drag fights the scroll.
  4. **One owned gesture** (dnd-kit sensor) vs 3 hand-rolled pointer systems; broad guards
     (`closest('[data-event-id]') || closest('button')`) + an event-id marker on blocks.
  5. **Central drag-end routing + one `DragOverlay`** for events *and* tasks (new-focal has two paths:
     dnd-kit overlay for tasks, a manual portal for events).

## Divergence
- **None on substance.** GPT read a slightly **stale checkout** (pre-#131/#132), so it reported "no
  drag-to-convert, no event overlay." Those now exist in the merged code (the hand-rolled portal +
  geometric `isOverTaskPanel` convert) — but the point stands: they're **bespoke, not dnd-kit**, so
  they add seams rather than removing them. No decision needed; both takes agree on the gaps + path.

## Open
- **Confirm what "ошибки" means at runtime.** Both takes are code-grounded but neither saw the live
  console. To close: on focal-dev, open DevTools console, reproduce a failed drag, and capture (a) any
  thrown exception text, and (b) which handler opened the popover. If it's a real exception (not just
  the stray create), that's a separate, additional fix.

## Next
- **Decision for the user (sequencing):**
  - **PR-now (small, robust):** post-drag cooldown + suppress-next-slot-click after event move/resize +
    desktop double-click slot-create + touch activation delay → kills the stray popover + steadies touch.
  - **PR-parity (larger):** unify the event drag onto dnd-kit (the old-focal architecture) → exact parity.
- Recommend shipping PR-now first (unblocks the user today), then PR-parity for the "exactly like
  old-focal" goal. Either can seed `/gate-design focal-calendar-dnd-unify`.
