# Design: focal-parity-calendar-event-actions

## Problem & decision

old-focal's `EventInfoDialog` (a read-only event view) carried a set of quick **actions** the new app's
event surface lacks: **duplicate** the event (`onCopy`), **change status** (`onChangeStatus`), and
**convert to task** (`onConvertToTask`). The new app collapsed old-focal's separate info dialog + full
editor into one anchored **`EventPopover`** (create/edit), which already does edit / mark-done / delete /
color / links — but offers **no duplicate and no status change**.

**Decision:** rather than revive a separate read-only `EventInfoDialog` (which would duplicate the
event-display surface the popover already owns), **add the missing actions to the existing `EventPopover`
edit mode**, reusing the popover's draft + dirty-tracking + save path:
- **Status** — a `planned / confirmed` select (the **same `STATUS_OPTIONS = ['planned','confirmed']` and
  `focal.events.status.*` labels** the Events-page `EventDialog` already uses) bound to the draft,
  persisted by the **existing** save (`updateEvent` accepts `status`); `EventBlock` restyles to the chosen
  variant. (`tentative` is a meeting-attendance variant `EventBlock` can render, but is **not** a user-set
  status — old-focal and the new `EventDialog` both expose only `planned | confirmed`, so this slice does
  the same.)
- **Duplicate** — a button that creates a copy through the **existing** `createEvent`, built by a
  dedicated `duplicatePayload(event)` that copies **all** copyable fields and **strips recurrence** (see
  below).

**Convert-to-task is explicitly out of scope here** — it needs the tasks API and is the event→task half
of the **task↔event convert** feature (the task-panel slice), which owns both convert directions. Folding
it there keeps all convert logic in one place and this slice purely event-API.

**Duplicate fidelity (matches old-focal).** old-focal's copy preserved the event's metadata and
**intentionally stripped recurrence** (a copy is a standalone single event, not part of a series). So
`duplicatePayload(event)` maps `CalendarEvent` → `EventCreate` copying **every** copyable field —
`title, date, startTime, endTime, description, location, color, timezone, otherParticipants, status,
completed, tags, contactIds, projectId, productId, activityId` — and sets `recurrence: 'none'`,
`recurrenceEndDate: null`, `recurrenceExceptions: []`. It does **not** go through the lean popover
`editDraft` (which omits description / location / tags / contacts), so no metadata is lost.

**Reuse-first (CLAUDE.md #2):** status rides the existing draft/dirty/`updateEvent` save path (no new
mutation, scope-dialog-aware for recurring); duplicate reuses `createEvent`; the status options + labels
reuse `EventDialog`'s. No new dialog, no new API, no backend change.

**Alternatives rejected:**
- **A separate read-only `EventInfoDialog`** (1:1 old-focal port): rejected — the new app deliberately has
  one event surface (`EventPopover`); a second display surface is redundant (Simplicity/Surgical).
- **Duplicate via `createPayload(editDraft(event))`:** rejected — the lean `editDraft` drops description/
  location/tags/contacts, so the copy would silently lose metadata. A dedicated full-field payload builder
  is required.

## Assumptions & scope

- **(confirmed — code)** `EventPopover` owns an editable `EventDraft` (which already declares
  `status?: string`), reports edits via `onPatch`, saves via `onSave`; `CalendarPage` owns the draft, the
  `dirty` set, `updatePatch` (builds the `EventUpdate`), `editDraft`, `createEvent`, and the events
  query/invalidation + the recurring scope-dialog routing.
- **(confirmed — code)** `EventCreate` accepts `title,date,startTime,endTime,description,location,color,
  timezone,otherParticipants,status,completed,tags,contactIds,projectId,productId,activityId,recurrence,
  recurrenceEndDate,recurrenceExceptions`; `EventUpdate.status?: string | null`. The Events `EventDialog`
  defines `STATUS_OPTIONS = ['planned','confirmed']` with `focal.events.status.*` labels — **reuse both**;
  no new label keys.
- **(confirm at build)** the `CalendarEvent` `tags`/`contactIds` shapes vs what `EventCreate` expects (map
  in `duplicatePayload`); that `editDraft` adding `status` and `updatePatch` sending it only when dirty
  leaves the existing exact-patch tests green.
- **Out of scope:** convert-to-task (the task-panel slice owns it); a no-open one-click status pill; bulk
  actions. Status + duplicate apply to single **and** recurring events; recurring status edits route
  through the existing scope dialog (no special-casing); a duplicate is always a single event.
- **Open questions:** None blocking.

## Success criteria

- [ ] In the edit popover, a **status** control shows the event's current status and lets the user pick
      `planned` / `confirmed`; saving persists it via `updateEvent` and the block restyles to the variant.
- [ ] Changing status on a **recurring** event routes through the existing scope dialog (this / following /
      all), exactly like any other field edit — no separate path.
- [ ] A **Duplicate** action creates a copy carrying **all** of the event's copyable fields **with
      recurrence stripped** (a standalone single event) via `createEvent`; the copy appears in the grid, the
      popover closes, and the original is untouched.
- [ ] On a **read-only** calendar (`!canEdit`), the status control is disabled and Duplicate is hidden/
      disabled — consistent with the popover's existing Save/Delete gating.
- [ ] A failed duplicate or status save surfaces the existing localized error and does not corrupt the grid
      (no phantom event / rollback), matching current save/delete error behavior.
- [ ] All strings i18next ru + en (reusing `focal.events.status.*`); the suite stays green
      (`pnpm lint && typecheck && test:run && build`).

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| B1 | Status change | `EventPopover.tsx` (status `Select`, edit mode, gated by `readOnly`, reusing `focal.events.status.*`), `CalendarPage.tsx` (`editDraft` seeds `status`; `updatePatch` sends `status` when dirty; mark dirty on change) | status not sent / sent always; recurring not routed | editing status to `confirmed` and saving calls `updateEvent` with `status:'confirmed'`; a title-only edit still omits status (exact-patch contract preserved); recurring routes through the scope dialog; disabled when `readOnly` |
| B2 | Duplicate | `EventPopover.tsx` (Duplicate button, edit mode, gated by `readOnly`), `CalendarPage.tsx` (`duplicatePayload(event)` full-field + recurrence-stripped; `handleDuplicate` → `createEvent` → invalidate → close) | copy drops metadata; copy stays recurring; mutates original; double-create | clicking Duplicate calls `createEvent` with all copyable fields and `recurrence:'none'` (original untouched), closes the popover; hidden/disabled when `readOnly`; a rejected create surfaces the error |

Each slice leaves `pnpm lint && typecheck && test:run && build` green and is committed on the branch.

## Architecture & contracts

```
EventPopover (edit mode)
  ├─ <Select status: planned|confirmed> → onPatch({status}) + mark dirty   // B1 — rides the existing draft/save
  └─ <Button Duplicate> → onDuplicate()                                    // B2 — new callback
CalendarPage
  ├─ editDraft(event): seed draft.status                                    // B1
  ├─ updatePatch(draft, dirty): add status when dirty.has('status')         // B1 → updateEvent (existing path, scope-dialog aware)
  ├─ duplicatePayload(event): EventCreate — all copyable fields, recurrence stripped   // B2
  └─ handleDuplicate(event) → createEvent(duplicatePayload(event)) → invalidate(eventsKey) → close   // B2
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `EventPopover` props | add `onDuplicate?: () => void` | status needs no new prop — it binds to `draft.status` via `onPatch`; reuse `focal.events.status.*` labels + `['planned','confirmed']` |
| `EventDraft` / `editDraft` | seed `status` from `event.status` | draft already declares `status?` |
| `updatePatch` | include `status` when `dirty.has('status')` | preserves the exact-patch contract (only changed fields beyond the core five) |
| `duplicatePayload` (new) | `CalendarEvent` → `EventCreate`: copy all copyable fields, `recurrence:'none'`, `recurrenceEndDate:null`, `recurrenceExceptions:[]` | matches old-focal copy (preserve metadata, strip recurrence); maps tags/contacts to the create shape |
| `CalendarPage` | `handleDuplicate` (createEvent(duplicatePayload) + invalidate + close); pass `onDuplicate` | reuses `createEvent`; recurring scope path unchanged (status is just another dirty field) |
| data model | **None** | reuses `createEvent` + `updateEvent` (both accept `status`) |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| change status | pick a status, save | `EventPopover` → `onPatch` (dirty) → `onSave` → `updatePatch` → `updateEvent` | persists `status`; the block restyles |
| recurring status | change status on a recurring event, save | `CalendarPage` opens the existing scope dialog | chosen scope applied via `updateEvent` |
| duplicate | click Duplicate | `EventPopover` → `onDuplicate` → `CalendarPage.createEvent(duplicatePayload)` | a single-event copy (all fields, no recurrence) appears; popover closes; original untouched |
| create/update fails | `createEvent`/`updateEvent` rejects | existing mutation `onError` | localized error; no phantom/rollback |
| read-only | `!canEdit` | `EventPopover` | status disabled, Duplicate hidden/disabled (server enforces anyway) |

## Test strategy, security & rollback

- **Test strategy.** Component (happy-dom): the popover renders a `planned|confirmed` status select seeded
  from the event and, on change + save, the patch carries `status`; a title-only edit omits status
  (exact-patch contract); the Duplicate button calls `onDuplicate`; both disabled/hidden when `readOnly`.
  Unit: `duplicatePayload` copies all copyable fields and strips recurrence. Integration (`CalendarPage`):
  saving a status change calls `updateEvent` with `status`; a recurring status change opens the scope
  dialog; Duplicate calls `createEvent` with the full copied payload (`recurrence:'none'`) and closes the
  popover; a rejected create surfaces the error. "Verified" = those + `pnpm lint && typecheck && test:run
  && build` green.
- **Security.** No new surface. Both actions reuse the existing `createEvent`/`updateEvent`; write
  authorization stays server-side (RBAC + RLS); the `readOnly`/`canEdit` client gate is UX. No secrets/PII;
  all strings i18n.
- **Rollback.** Pure frontend, no migration — revert the PR.
