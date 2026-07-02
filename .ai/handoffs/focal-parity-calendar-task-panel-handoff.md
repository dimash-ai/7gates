# Stage

3-Gate flow — Gate C (verify), release gate. Feature `focal-parity-calendar-task-panel`.

# What changed

Brings old-focal's **calendar task panel** and the **task↔event move** to the new focal calendar. The
pieces already existed (a full TasksPage, a `TaskDialog` that already schedules a task as an event, and
`listTasks`); what was missing was the calendar-side panel and the reverse convert:

- **B1 — TaskPanel.** A compact task list in the calendar sidebar (below the mini-month) under a small
  filter (all / today / overdue / completed), reusing `listTasks` + `compareTasksForDisplay`; clicking a
  row opens the **existing** `TaskDialog` (edit + **Schedule as event** — task→event, reused unchanged).
  Tasks are an OTHER_PAGES domain, so the panel (and its query) renders only when `canViewOtherPages`.
- **B2 — Convert to task.** A **Convert to task** action on the event edit popover (non-recurring,
  gated by `canCreateTasks = canEdit && canViewOtherPages`): it creates a task from the event
  (date→dueDate, start→dueTime, carrying title / priority / goal-map links) and then deletes the event.

The two convert calls are independent, so the failure contract is explicit: `createTask` runs first; a
create failure rolls back the optimistic event removal and shows a plain error (the event is untouched);
a **delete failure after the task was created** keeps the (real) task, reconciles both caches, and shows
a partial-failure banner — mirroring the existing task→event partial path. The convert is double-click
guarded, and Save/Duplicate/Delete are disabled while it is in flight.

The panel fetches a **wide window** (`2000-01-01 → 2100-12-31`, like bookings) because `listTasks` windows
on due date server-side — a bounded window would silently drop a long-overdue task from the all/overdue
filters. Undated tasks are always returned by the backend regardless of window.

# Files touched

- `apps/focal/client/src/features/calendar/TaskPanel.tsx` (new) — panel + pure `taskPanelFilter`.
- `apps/focal/client/src/features/events/eventsFilters.ts` — `taskFromEvent(event): TaskCreate` pure builder.
- `apps/focal/client/src/features/calendar/EventPopover.tsx` — `onConvertToTask` action (edit-mode).
- `apps/focal/client/src/features/calendar/CalendarPage.tsx` — tasks query (gated + wide window), panel +
  edit-`TaskDialog` wiring, `convertMutation` (optimistic + partial-failure), keyboard bail.
- `apps/focal/client/src/i18n/locales/{en,ru}.json` — `focal.calendar.taskPanel.*`, `edit.convertToTask`,
  `errors.convertPartial`.
- Tests: `TaskPanel.test.tsx`, `eventsFilters.test.ts` (taskFromEvent), `CalendarPage.test.tsx`
  (panel gating + wide window + convert happy/partial/create-fail/double-click/recurring/no-rights).

# Tests run

```sh
cd superapp-parity/apps/focal/client
pnpm typecheck   # 0 errors
pnpm lint        # 368 files, clean
pnpm test:run    # 129 files, 1564 tests passed (after rebasing onto #116 aichat + #117 PWA)
pnpm build       # OK
```

Gate A (design) APPROVED 9.1 (after adding the task-domain permission gates + the create-then-delete
partial-failure contract + non-recurring restriction) · Gate B (build) APPROVED 9.2 (after switching the
panel to a wide task window and disabling event-delete during a convert).

# Still needs review

- Deferred follow-ups: drag-a-task-onto-the-grid scheduling; an undo for the convert (the separate undo
  feature — the convert still surfaces an error + rolls back today); a recurring-event convert (ambiguous
  which occurrence; recurring delete routes through the scope dialog).

# PR / release notes (for users — stage 5)

The calendar gets a **task panel** and **task↔event** moves, matching the old Focal:

- A compact **task list** in the calendar sidebar, with a filter (all / today / overdue / completed). Click
  a task to open it — edit it, or **schedule it as an event**.
- On an event, **Convert to task** turns it into a task (its date and time become the task's due date and
  time) and removes the event.
- Read-only and limited-access shared calendars hide the actions they can't perform.

No secrets, tokens, keys, or PII in this text or the diff.

# Status

OPUS APPROVED (9.4) — release gate cleared. Rebased onto origin/feature/focal-migration fe3d181.
