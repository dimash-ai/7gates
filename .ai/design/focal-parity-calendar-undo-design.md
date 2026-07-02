# Design: focal-parity-calendar-undo

## Problem & decision

old-focal keeps an **undo stack** of the user's recent calendar actions and a toolbar **Undo** button that
reverses the last one (`apps/old-focal/client/src/pages/Calendar.tsx` — `undoStack` capped at ~20,
`handleUndo` reversing by type: create↔delete, update→restore old data, plus task/convert variants). The
new app has no undo at all: a mis-drag, an accidental delete, or a wrong edit can't be taken back.

**Decision: add a bounded undo stack of inverse thunks in `CalendarPage`, fed by the existing event
mutations, with a toolbar Undo button + Cmd/Ctrl+Z.** Concretely:
- Each entry is `{ label, invert: () => Promise<void> }`. On the **success** of an event mutation, the
  handler pushes the inverse that undoes *that* action. The invert calls the **API directly**
  (`createEvent` / `deleteEvent` / `updateEvent`) — never the mutations — so running an undo never pushes
  a new entry (no recursion, no redo bookkeeping). The stack is capped (20) and lives in component state.
- Inverses by action (this is the whole behaviour):
  - **create / duplicate / drag-create** (`createMutation`, which returns the created event) → delete the
    created event by its id.
  - **delete** (non-recurring) → re-create it from `duplicatePayload(event)` (a new id, same fields).
  - **edit / move / resize** (non-recurring) → restore the pre-change event via `eventToUpdatePatch(event)`.
  - **convert to task** (`convertMutation`, event→task) → delete the created task by its id, then
    re-create the event from `duplicatePayload(event)` (parity with old-focal's `event_to_task` undo). The
    mutation already has the source event; it returns the created task so the inverse can target its id.
- Each entry **captures the `calendarId` it acted on** in its closure (so an undo always targets the
  calendar where the action happened, not whatever is selected now), and the stack is **cleared when
  `currentCalendarId` changes** — undo is scoped to the current calendar session.
- **Recurring (scope-dialog) mutations don't push** — a recurring delete/edit carries a `RecurrenceTarget`
  (occurrence vs series), whose inverse is ambiguous; those simply aren't undoable in this cut (noted).
- **Trigger:** a header-toolbar Undo button (`Undo2`, disabled when the stack is empty or `!canEdit`) and
  Cmd/Ctrl+Z in the existing keyboard handler, gated by the **same** `canEdit` + non-empty checks and only
  when **no dialog is open** (popover, recurring-scope, task, prime, **booking**, selected-task) and focus
  isn't in a field — so native text-undo still works while typing. A failed undo surfaces in the banner.

**Reuse-first (CLAUDE.md #2):** the mutations, `duplicatePayload` (event→`EventCreate`), `isRecurring`, the
error banner, and the keyboard handler all exist — this slice adds a small stack, one pure restore-patch
helper, and a button. The invert-thunk shape means new action types (convert, bookings) drop in later
without a growing type union.

**Alternatives rejected:**
- **A typed action union + a big `switch` (old-focal's shape)** — rejected; closures capturing exactly
  what each inverse needs are smaller and colocate the inverse with the mutation. No `data: any`.
- **Route undo back through the mutations** — rejected; it would re-push entries and tangle optimistic
  caches. Direct API calls + one invalidate are simpler and correct.
- **Full multi-level redo + cross-session persistence** — rejected for the first cut (old-focal had
  neither a redo nor persistence); the stack is in-memory and undo-only.

## Assumptions & scope

- **(confirmed — code)** `CalendarPage` owns `createMutation` (create/duplicate/drag-create; `createEvent`
  returns the created `CalendarEvent` with its id), `updateMutation` (edits; `target` set only for
  recurring), `deleteMutation` (`target` set only for recurring), `moveMutation` (drag-move **and** resize —
  both non-recurring, `target` undefined), and `convertMutation` (event→task; runs `createTask` then
  `deleteEvent`). `useMutation` `onSuccess(data, vars)` exposes both. `duplicatePayload(event): EventCreate`
  copies every copyable field; `createTask`/`deleteTask` exist. The keyboard effect bails on `INPUT/TEXTAREA/
  SELECT` focus and on `popover`/`pendingOp`/`taskDialogOpen`/`primeDialogOpen`/`selectedTask` — **but not
  `bookingDialog`**, which this slice adds to the guard.
- **(confirm at build)** the exact `onSuccess` signatures to thread `data`/`vars`; that re-creating a
  non-recurring deleted event via `duplicatePayload` round-trips its fields; the header slot for the button.
- **Out of scope:** undo of recurring (scope-dialog) mutations and bookings (natural follow-ups on the same
  stack — old-focal's `undoStack` covered events + tasks + convert, not bookings); redo; persistence across
  reloads; a success toast (the calendar has no toast surface — the visual change + the disabled state are
  the feedback; errors use the banner). Re-created deletes get a **new id**, so a same-event undo chain
  across delete→recreate won't preserve identity (matches old-focal, which also POSTs the data anew).
- **Open questions:** None blocking.

## Success criteria

- [ ] After creating (or duplicating / drag-creating) an event, Undo deletes it; after deleting a
      non-recurring event, Undo re-creates it; after an edit / move / resize, Undo restores its prior state;
      after a convert-to-task, Undo deletes the task and re-creates the event — each verified by the exact
      inverse API call(s), then a cache invalidate.
- [ ] Each entry undoes against the **calendar it acted on** (captured in the closure), and switching
      `currentCalendarId` clears the stack.
- [ ] The Undo button is disabled when the stack is empty and on a read-only calendar; Cmd/Ctrl+Z triggers
      undo under the **same** `canEdit` + non-empty gate, only when **no dialog** is open (popover,
      recurring-scope, task, prime, booking, selected-task) and focus isn't in a text field.
- [ ] Running an undo does **not** itself push a new undo entry (the inverse calls the API directly); the
      stack is bounded (a 21st push leaves 20 entries) and most-recent-first.
- [ ] A recurring (scope-dialog) delete/edit pushes **no** entry (it isn't reversed by this stack).
- [ ] A failed undo surfaces a localized error in the existing banner and leaves the stack as it was popped.
- [ ] All strings i18n ru + en; the suite stays green (`pnpm lint && typecheck && test:run && build`).

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| B1 | stack + create/delete undo + UI | `features/calendar/CalendarPage.tsx` (undo state + `pushUndo` + `handleUndo`; push on `createMutation`/`deleteMutation` success; Undo button + Cmd/Ctrl+Z), `i18n` | undo re-pushes itself; recurring delete pushed; button enabled read-only | create→Undo calls `deleteEvent(createdId)`; non-recurring delete→Undo calls `createEvent(duplicatePayload)`; undo doesn't grow the stack; button disabled when empty / read-only; Cmd+Z fires only outside dialogs/fields; recurring delete pushes nothing |
| B2 | edit/move/resize + convert undo | `features/events/eventsFilters.ts` (`eventToUpdatePatch(event): EventUpdate` pure restore), `CalendarPage.tsx` (push on `updateMutation`/`moveMutation` success non-recurring; push on `convertMutation` success → delete-task + recreate-event), tests | restore patch drops a changed field; recurring edit pushed; convert undo leaves the task | `eventToUpdatePatch` carries every editable field; move/resize→Undo calls `updateEvent` restoring the prior geometry; a non-recurring edit→Undo restores; convert→Undo calls `deleteTask(taskId)` + `createEvent`; a recurring edit pushes nothing |

Each slice leaves `pnpm lint && typecheck && test:run && build` green and is committed on the branch.

## Architecture & contracts

```
CalendarPage  (calId = currentCalendarId captured at push time, inside each closure)
  undo: UndoEntry[]                       // { label, invert: () => Promise<void> }, capped at 20, newest last
  pushUndo(entry)                         // bounded append (drop the oldest past 20)
  handleUndo()                            // if !canEdit || empty → no-op; else pop → await invert() → invalidate(['events'] + ['tasks']) → banner on error; never re-pushes
  useEffect([currentCalendarId])          → setUndo([])   // a calendar switch clears the stack
  createMutation.onSuccess(created)       → pushUndo({ invert: () => deleteEvent(created.id, undefined, calId) })
  deleteMutation.onSuccess(_, vars)       → if !vars.target: pushUndo({ invert: () => createEvent(duplicatePayload(vars.event), calId) })
  updateMutation.onSuccess(_, vars)       → if !vars.target: pushUndo({ invert: () => updateEvent(vars.event.id, eventToUpdatePatch(vars.event), undefined, calId) })
  moveMutation.onSuccess(_, vars)         → pushUndo({ invert: () => updateEvent(vars.event.id, eventToUpdatePatch(vars.event), undefined, calId) })
  convertMutation: mutationFn returns the created task; onSuccess(task, event) → pushUndo({ invert: async () => { await deleteTask(task.id, calId); await createEvent(duplicatePayload(event), calId) } })
  header: <Button Undo2 disabled={undo.length === 0 || !canEdit} onClick={handleUndo} />
  keydown: (meta|ctrl)+z, canEdit && undo.length, NO dialog (popover|pendingOp|task|prime|booking|selected), not in a field → preventDefault + handleUndo()
features/events/eventsFilters.ts: eventToUpdatePatch(event): EventUpdate   // all editable fields, for restore
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `UndoEntry` (new) | `{ label: string; invert: () => Promise<void> }` | closure-based; invert calls the API directly |
| `CalendarPage` undo state + handlers | stack + `pushUndo` + `handleUndo` + 4 mutation pushes + button + Cmd/Ctrl+Z | the whole feature; recurring paths skip |
| `eventToUpdatePatch` (new, pure) | `CalendarEvent → EventUpdate` | restores title/date/time/recurrence/completed/status/links/desc/location/tz/tags/participants |
| data model / API | **None** | reuses `createEvent`/`deleteEvent`/`updateEvent` (server RBAC + RLS) |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| undo a create | Undo after create | `handleUndo` → `deleteEvent(createdId)` | the new event is removed |
| undo a delete | Undo after a non-recurring delete | `handleUndo` → `createEvent(duplicatePayload)` | the event comes back (new id, same fields) |
| undo a move/resize/edit | Undo after a non-recurring change | `handleUndo` → `updateEvent(restore)` | the event returns to its prior state |
| undo a convert | Undo after convert-to-task | `handleUndo` → `deleteTask(taskId)` + `createEvent` | the task is removed and the event comes back |
| switch calendar | `currentCalendarId` changes | `useEffect` | the stack clears (no cross-calendar undo) |
| undo fails | an inverse API call rejects | `handleUndo` catch | localized error in the banner; the entry stays popped |
| nothing to undo / read-only | empty stack or `!canEdit` | button `disabled` | inert |
| recurring change | a scope-dialog delete/edit | mutation `onSuccess` (target set) | no entry pushed (not undoable here) |

## Test strategy, security & rollback

- **Test strategy.** Unit (`eventsFilters.test`): `eventToUpdatePatch` carries every editable field.
  Integration (`CalendarPage.test`): create→Undo calls `deleteEvent` with the created id; non-recurring
  delete→Undo calls `createEvent` with the duplicate payload; move/resize→Undo calls `updateEvent`
  restoring the prior date/time; an edit→Undo restores; convert→Undo calls `deleteTask(taskId)` **and**
  `createEvent`; the button is disabled when the stack is empty and on a read-only calendar; Cmd/Ctrl+Z
  triggers undo, and **not** while any dialog (incl. booking) is open or a field is focused; a recurring
  delete/edit pushes nothing; switching `currentCalendarId` clears the stack; a 21st push leaves 20
  entries; a rejected inverse shows the banner; undo doesn't grow the stack. "Verified" = those + `pnpm
  lint && typecheck && test:run && build` green.
- **Security.** No new surface; the inverses go through the same RBAC/RLS-guarded event endpoints, gated
  client-side by `canEdit`. No secrets/PII; all strings i18n.
- **Rollback.** Pure frontend, no migration — revert the PR; the stack + helper are self-contained.
