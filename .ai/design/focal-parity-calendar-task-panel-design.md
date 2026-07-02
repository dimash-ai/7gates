# Design: focal-parity-calendar-task-panel

## Problem & decision

old-focal puts a **task panel** on the calendar — a compact, filtered list of tasks beside the grid so
you can see what's due while you plan (`apps/old-focal/client/src/components/TaskPanel.tsx`), with
**schedule-as-event** (task→event) and **convert-to-task** (event→task) to move work between the two.
The new app has the **pieces** — a full `TasksPage`, a `TaskDialog` that already owns a
**`scheduleMutation`** (`buildSchedulePayload(task) → createEvent`, i.e. task→event is **done**), `listTasks`,
and `tasksFilters` — but the **calendar itself has no task panel**, and there is **no event→task convert**
(that action was deferred from the event-actions feature).

**Decision (the two real gaps):**
- **B1 — TaskPanel:** a compact task list in the calendar sidebar (below the mini-month) showing the
  user's tasks under a small filter (today / upcoming / overdue / completed), each row clickable to open
  the **existing `TaskDialog`** — which already offers edit + **Schedule as event**. Tasks are an
  **OTHER_PAGES** domain, so the panel (and its `listTasks` query) renders **only when
  `canViewOtherPages`** — a calendar `editor` has `canEdit=true` but `canViewOtherPages=false`, and reading
  tasks would 403; on such a calendar the panel is simply absent.
- **B2 — event→task convert:** a **Convert to task** action on the event edit popover, gated by
  **`canCreateTasks = canEdit && canViewOtherPages`** (the same gate the existing «New task» button uses —
  tasks are OTHER_PAGES). It creates a task from the event (`createTask` with the event's title /
  date→dueDate / time→dueTime / description / project links) and then **deletes the event**.
  **Partial-failure contract (the two calls are independent):** `createTask` runs first; on success the
  event is deleted; if the **delete fails after the task was created**, a cache rollback cannot un-create
  the task, so — like the existing `TaskDialog.scheduleMutation` partial path — the UI shows a
  **partial-failure** message ("converted to a task, but couldn't remove the event") and — this design's
  explicit contract, not inherited from `scheduleMutation` (which surfaces the message but does **not** itself
  dual-invalidate) — invalidates **both** the events and tasks caches to reconcile, leaving the (real) task in
  place; a `createTask` failure
  before any delete shows a plain error and changes nothing. **Recurring events are out of scope** for
  convert (which occurrence becomes the task is ambiguous, and recurring delete routes through the scope
  dialog) — the action is offered only on non-recurring events.

**task→event is NOT rebuilt** — it already exists in `TaskDialog` (`scheduleAsEvent`); the panel simply
routes there.

**Reuse-first (CLAUDE.md #2):** `listTasks`, the `TaskDialog` (edit + schedule), `tasksFilters`/`taskSort`,
`createTask`, `deleteEvent`, the events optimistic-mutation pattern, and the sidebar's existing layout all
exist — B1 is a list + filter, B2 is a payload builder + one action wired to two existing mutations.

**Alternatives rejected:**
- **Rebuild task→event in the panel:** rejected — `TaskDialog.scheduleMutation` already does it; routing
  the panel through `TaskDialog` reuses it and avoids a second schedule path.
- **A full task board on the calendar:** rejected — the calendar panel is a *compact* contextual list;
  the full task management UI is the `TasksPage`.
- **A drag-task-onto-grid scheduler:** rejected for the first cut — old-focal's `onScheduleAsEvent` is a
  button/action, not a grid drop; the dialog-based schedule matches it and needs no new DnD surface.

## Assumptions & scope

- **(confirmed — code)** `listTasks(...)` → `Task[]` (`EnrichedTaskRead`: `id,title,dueDate,dueTime,priority,
  completed,status,description,projectId,...`). `TaskDialog` takes `task` (null=create, set=edit) and owns
  edit + `scheduleMutation`. `createTask(payload, calendarId?)` and `deleteEvent(id, target?, calendarId?)`
  exist; `TaskCreate` has `title,description,dueDate,dueTime,priority,tags,recurrence,projectId,productId,
  activityId,...` (no `eventId` — the backend owns any link).
- **(confirmed — code)** tasks are an **OTHER_PAGES** domain — `canCreateTasks = canEdit && canViewOtherPages`
  already gates the «New task» button; the panel's read + the convert's create use the same
  `canViewOtherPages` / `canCreateTasks` gates (a calendar `editor` has `canEdit` but not `canViewOtherPages`).
- **(confirm at build)** the exact `TaskDialog` open contract for an existing task; the panel's tasks query
  **window** — `listTasks()` defaults to the current month + undated, so overdue/upcoming need a wider range (a
  wide window like bookings, or `getTaskQueryRange`); whether `taskFromEvent` lives in `eventsFilters`.
  Settle in B1/B2.
- **Out of scope:** drag-task-onto-grid scheduling; an undo stack for the convert (that's the separate undo
  feature — the convert still surfaces an error + rolls back on failure); editing tasks inline in the panel
  (the panel opens `TaskDialog`); a recurring-task→event special case (reuses whatever `scheduleMutation` does).
- **Open questions:** None blocking.

## Success criteria

- [ ] When `canViewOtherPages`, the calendar sidebar shows a **task panel** listing the user's tasks under a
      filter (today / upcoming / overdue / completed); each row shows title + due + a done indicator and opens
      the `TaskDialog` on click. On a calendar without other-pages read (e.g. an `editor`), the panel is absent.
- [ ] From a task's dialog, **Schedule as event** still works (reused, unchanged) — the panel is the entry.
- [ ] When `canCreateTasks`, a **non-recurring** event's edit popover has a **Convert to task** action that
      creates a task from the event and deletes the event; the grid reflects it optimistically. If the delete
      fails after the task was created, a **partial-failure** message shows + both caches invalidate (the task
      stays); a create failure shows a plain error and changes nothing.
- [ ] On a calendar where `!canCreateTasks`, Convert-to-task is **absent**; recurring events never show it.
- [ ] The panel never breaks the grid layout (it's a scrollable sidebar section; hidden on small screens like
      the rest of the sidebar).
- [ ] All strings i18next ru + en; the suite stays green (`pnpm lint && typecheck && test:run && build`).

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| B1 | TaskPanel | `features/calendar/TaskPanel.tsx` (list + filter; reuse `listTasks` + a small `taskPanelFilter` pure helper), `CalendarPage.tsx` (tasks query + panel gated on `canViewOtherPages`; open `TaskDialog` for the clicked task) | filter off-by-one (today/overdue); panel shown without other-pages read (403) | `taskPanelFilter` narrows by today/overdue/completed; the panel lists tasks + opens a task's dialog on click; **absent when `!canViewOtherPages`**; empty filter → empty state |
| B2 | Convert to task | `features/events/eventsFilters.ts` (`taskFromEvent(event): TaskCreate` pure builder), `EventPopover.tsx` (Convert-to-task action — non-recurring, `canCreateTasks`-gated), `CalendarPage.tsx` (`handleConvertToTask` → `createTask` then `deleteEvent`; optimistic event removal + rollback on create failure; partial-failure message + dual invalidate if delete fails) | convert drops event metadata; event not removed; partial state silently swallowed | `taskFromEvent` copies the event's fields (date→dueDate, time→dueTime); a convert calls `createTask` then `deleteEvent` and the event disappears; a create failure rolls back + errors; a **delete-after-create** failure shows the partial message + invalidates both caches; the action is **absent when `!canCreateTasks` or the event recurs** |

Each slice leaves `pnpm lint && typecheck && test:run && build` green and is committed on the branch.

## Architecture & contracts

```
CalendarPage
  ├─ useQuery(tasksKey) → listTasks → Task[]
  ├─ sidebar: <TaskPanel tasks onSelect={openTaskDialog} />            // B1 → opens the existing TaskDialog
  ├─ <TaskDialog task={selectedTask} … />                             // existing: edit + scheduleAsEvent (task→event reused)
  └─ EventPopover «Convert to task» → handleConvertToTask(event)      // B2
        → createTask(taskFromEvent(event)) + deleteEvent(event.id)  (optimistic on both caches + rollback)
features/calendar/TaskPanel.ts(x): taskPanelFilter(tasks, filter, todayIso) (today/upcoming/overdue/completed)
features/events/eventsFilters.ts: taskFromEvent(event): TaskCreate  (title, dueDate=date, dueTime=startTime, description, project/product/activity)
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `TaskPanel` (new) | list + filter; `tasks`, `onSelect(task)` props | presentational; reuse `listTasks` data from `CalendarPage` |
| `taskPanelFilter` (new, pure) | `(tasks, filter, todayIso)` | unit-tested filter (today/upcoming/overdue/completed) |
| `taskFromEvent` (new, pure) | `CalendarEvent → TaskCreate` | date→dueDate, startTime→dueTime, copy title/description/project links |
| `EventPopover` props | add `onConvertToTask?: () => void` (edit mode, non-recurring, `canCreateTasks`-gated) | sibling to Duplicate/Delete |
| `CalendarPage` | tasks query; `TaskPanel` + `TaskDialog` wiring; `handleConvertToTask` (optimistic createTask + deleteEvent + rollback) | mirrors the events/bookings optimistic pattern; a synchronous guard on convert |
| data model | **None** | reuses `listTasks`/`createTask`/`deleteEvent` |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| list tasks | tasks query resolves | `TaskPanel` | filtered task rows |
| open task | click a panel row | `CalendarPage` → `TaskDialog` | the existing dialog (edit + schedule-as-event) |
| schedule as event | Schedule in the task dialog | existing `TaskDialog.scheduleMutation` | event created from the task (unchanged) |
| convert to task | Convert-to-task on a non-recurring event | `CalendarPage.handleConvertToTask` | `createTask` then `deleteEvent`; event removed optimistically |
| convert — create fails | `createTask` rejects | mutation `onError` | nothing changes; localized error |
| convert — delete fails | `createTask` ok, `deleteEvent` rejects | mutation `onError` | partial-failure message; both caches invalidated; the task stays |
| no task rights | `!canCreateTasks` | popover / panel | panel absent; Convert-to-task absent |

## Test strategy, security & rollback

- **Test strategy.** Unit: `taskPanelFilter` (today/upcoming/overdue/completed, no-due handling); `taskFromEvent`
  (date→dueDate, time→dueTime, copied links). Component (happy-dom): the panel lists + filters tasks and opens
  the dialog on click; the popover's Convert action is gated by `canCreateTasks` + non-recurring. Integration (`CalendarPage`): convert
  calls `createTask` with the event's fields **and** `deleteEvent`, reflects optimistically, and rolls back with
  an error on a rejected create/delete; a double-convert is guarded. "Verified" = those + `pnpm lint && typecheck
  && test:run && build` green.
- **Security.** No new surface; reuses `listTasks`/`createTask`/`deleteEvent` (server RBAC + RLS). The `canEdit`/
  `canCreateTasks` client gates are UX. No secrets/PII; all strings i18n.
- **Rollback.** Pure frontend, no migration — revert the PR.
