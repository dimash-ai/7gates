# Summary

Bring `superapp-tasks` Tasks to old-focal core parity without expanding the slice into the advanced filters or full edit dialog. The implementation should remove the new all/events/tasks tabs and `listEvents` coupling, keep the existing tasks API wiring and `taskSort.ts`, render old-focal-style Active/Completed cards and task rows, and replace the current project/status/priority header filters with the old-focal header controls that are in scope: Add, help, Filter toggle shell, task-count badge, orphan select, and priority select. The interim quick-add form remains the create path until `focal-redesign-tasks-dialog`; the active-row edit affordance is shown for visual parity but final edit behavior belongs to that dialog follow-up.

Assumptions carried from the approved think/task docs: this slice is frontend-only; old-focal is the visual contract; filters panel and full TaskDialog are deferred; `recurrence` plus multi-participant task dialog fields are a backend gap because `TaskCreate`/`TaskUpdate` do not carry them; no API, schema, generated OpenAPI, shell, or `taskSort.ts` change is planned.

# Files to change

| path | change | why |
|------|--------|-----|
| `/Users/allosta/Desktop/allosta/superapp-tasks/apps/focal/client/src/features/tasks/TasksPage.tsx` | Remove tab/events rendering and `listEvents`; rework local header actions, filtering state, task grouping, row markup, and quick-add placement over the existing `list/create/update/delete` mutations. | This is the Tasks page surface under redesign. |
| `/Users/allosta/Desktop/allosta/superapp-tasks/apps/focal/client/src/features/tasks/TasksPage.test.tsx` | Replace tab/event assertions with core-parity assertions for tasks-only rendering, header controls, orphan/priority filtering, Active/Completed grouping, old-focal row affordances, and preserved create/toggle/delete errors. | The current tests depend on the tabbed UI and must prove the new behavior. |
| `/Users/allosta/Desktop/allosta/superapp-tasks/apps/focal/client/src/i18n/locales/en.json` | Add or adjust `translation.focal.tasks` keys for Add/focus labels, edit affordance label, Filter toggle/count text, orphan filter options, orphan reason labels, project-type labels, and count-badge text. Remove no keys unless they become unused and extraction confirms it. | New visible and accessible text must stay localized. |
| `/Users/allosta/Desktop/allosta/superapp-tasks/apps/focal/client/src/i18n/locales/ru.json` | Add the same keys in Russian, reusing old-focal copy where it maps cleanly. | RU and EN remain complete first-class locales. |

No change is planned for `taskSort.ts`, `taskSort.test.ts`, `api/tasks.ts`, `api/events.ts`, generated `api/openapi.d.ts`, shared shell components, or shadcn primitives.

# Implementation slices

1. Add locale keys and test fixtures without changing behavior.
   - Add the missing `focal.tasks` keys for header controls, orphan filters (`all`, `orphans`, `classified`, `completed`, `active`), orphan reasons, project-type badges (`mission`, `provision`), edit affordance, and count-badge phrasing.
   - Extend the `makeTask` fixture in `TasksPage.test.tsx` only as needed for row parity fields already present on `Task`: `priorityLevel`, `projectType`, `projectName`, `productId`, `orphanReason`, and `isOrphan`.
   - Keep build green because the page has not consumed the new keys yet.

2. Collapse the page to tasks-only while preserving current CRUD.
   - Remove `Tab`, tab state, tab buttons, `Calendar` / `Layers` / `CalendarEvent` imports, `listEvents`, week/date memoization, `EventRow`, `WeekEvents`, all/events branches, and event mocks in tests.
   - Render the task-management body directly: mutation error banner, interim quick-add form, loading/error/empty state, and grouped task lists.
   - Keep `TASKS_KEY`, `listTasks`, `createTask`, `updateTask` for completion toggle, `deleteTask`, mutation invalidation, and `compareTasksForDisplay` unchanged.
   - Update tests so rendering the page never calls `eventsApi.listEvents`, no tab buttons or week-events heading appear, and create/toggle/delete still call the same task API payloads.

3. Rebuild the in-scope old-focal header controls.
   - Keep the shell-owned `PageHeader` unless implementation proves its flex wrapping cannot match the old-focal desktop/mobile split; do not edit `PageHeader`.
   - Pass `help={t('focal.tasks.help')}` and put the in-scope controls in `leftActions` / `rightActions`: icon-only Add button, Filter toggle shell with active-count badge, task-count badge, orphan select, and priority select.
   - Match the old-focal task-count badge branches from `Tasks.tsx:987-991`: compute `totalActive = tasks.filter(t => !t.completed).length` and `filteredActive = filtered.filter(t => !t.completed).length` after the orphan and priority selects, matching old-focal `pendingTasks.length`. If `filteredActive !== totalActive`, show localized `focal.tasks.*` text `{filteredActive} of {totalActive}`; otherwise show localized `{filteredActive} active`. Do not use `tasks.length` or all-status counts anywhere in the badge.
   - Do not add a task-local `AIAssistantHeaderButton` or tag-manager button. If `PageHeader` renders the global `PageToolbar`, treat it as shell-owned and do not duplicate or modify it in this slice.
   - Add `orphanFilter` state with old-focal semantics: `all` no status/orphan constraint, `orphans` only `task.isOrphan`, `classified` only `!task.isOrphan`, `completed` only completed tasks, `active` only incomplete tasks.
   - Add `priorityFilter` using old-focal priority normalization: `(task.priorityLevel ?? 'medium')`.
   - Keep a `showFilters` state only as the future panel anchor for `focal-redesign-tasks-filters`; do not render the advanced panel or query spheres/products/activities/tags here.
   - Make the Add button focus or reveal the interim quick-add form instead of opening a dialog.

4. Port old-focal Active/Completed cards and task rows.
   - Replace the current `TaskGroup` section headings with `Card`, `CardHeader`, `CardTitle`, and `CardContent` groups: Active tasks and Completed only.
   - Remove the separate orphan group; orphans stay inline inside Active via the amber dashed row treatment, matching old-focal.
   - Compute `activeTasks = filtered.filter(!completed).sort(compareTasksForDisplay)` and `completedTasks = filtered.filter(completed).sort(compareTasksForDisplay)`.
   - Match old-focal empty-state behavior: render the localized empty task state only when the successful task query returns `tasks.length === 0`. If filters reduce a non-empty task list to zero rows, render the Active/Completed card shell with no row matches rather than a separate no-match hint.
   - Replace `TaskRow` with old-focal row markup:
     - Shared: `relative overflow-hidden flex items-center gap-3 p-3 rounded-md flex-wrap`, priority left stripe from `task.priorityLevel ?? 'medium'`, top stripe from `projects.data` color lookup using `productId` first, then `projectId`, falling back to `hsl(var(--primary))`.
     - Active rows: `hover-elevate`, `bg-muted/50` or amber dashed orphan treatment, checkbox, optional `AlertTriangle`, truncating title, orphan reason badge, project-type badge, Pencil ghost icon, Trash ghost icon. `EnrichedTaskRead.projectType` is `string | null`, so compare string values directly (`task.projectType === 'mission'` / `task.projectType === 'provision'`) and render no badge for any other value; do not cast it to a closed union.
     - Completed rows: `opacity-60`, muted/orphan background, checkbox, line-through title, Trash ghost icon only; no edit button and no project-type badge.
   - Keep the active-row Pencil visible for visual parity, but do not implement the full edit dialog in this slice. If it cannot perform a real backed action without scope creep, render it disabled or with a narrowly-scoped placeholder handler and document it in tests as deferred to `focal-redesign-tasks-dialog`.
   - Use existing `Checkbox`, `Badge`, `Button`, `Card`, and `Select` primitives; no new dependency or shared primitive change.

5. Final parity polish and verification.
   - Ensure light/dark classes use existing tokens and old-focal tones without introducing page-specific token files.
   - Keep quick-add as the interim create path, but align spacing enough that it does not visually fight the old-focal cards.
   - Keep delete non-optimistic and mutation errors routed through the existing alert banner.
   - Run focused tests first, then the required client checks:
     `cd /Users/allosta/Desktop/allosta/superapp-tasks/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.
   - Screenshot-compare the page in light and dark against `/Users/allosta/Desktop/allosta/superapp/apps/old-focal/client/src/pages/Tasks.tsx` and `components/TaskItem.tsx`, with filters panel and full dialog intentionally absent.

# Tests

- `renders tasks-only page and never loads events`: mock `listTasks` and `listEvents`; prove `listEvents` is not called, tab buttons are absent, and week-events text is absent.
- `renders the old-focal header controls and count-badge numbers`: proves title/help, Add, Filter toggle, task-count badge, orphan select, and priority select are present while the tag-manager button is absent and no task-local AI button is added; with priority/orphan filters active and fixtures, asserts the badge text is `2 of 5` (`filteredActive` of `totalActive`), and with no filter active on the same fixtures asserts `5 active`.
- `focuses the interim quick-add form from Add`: proves the in-scope Add button has useful behavior without opening the deferred dialog.
- `creates a task with the entered title and default priority`: preserves the existing create payload `{ title, priority: 'medium', projectId: null }`.
- `links the selected project on create`: preserves the existing project select create path and `projectId` payload.
- `filters with the orphan select using old-focal semantics`: with active, completed, orphan, and classified fixtures, proves `orphans`, `classified`, `completed`, and `active` show only the expected rows.
- `filters priority by old-focal priorityLevel normalization`: proves priority filtering uses `task.priorityLevel ?? 'medium'` and ignores `task.priority`, matching old-focal and `taskSort`.
- `groups filtered rows into Active and Completed cards`: proves active and completed rows are separated into the two old-focal groups and orphans do not get a separate group.
- `renders active row parity affordances`: proves active rows expose checkbox, title, priority stripe, top project-color stripe fallback, orphan icon/badge when relevant, project-type badge, edit affordance, and delete button.
- `renders completed row parity affordances`: proves completed rows have line-through/opacity treatment and delete only; no edit button and no project-type badge.
- `keeps taskSort order within each group`: fixtures with dates/priorities prove row order follows `compareTasksForDisplay`; `taskSort.ts` tests remain unchanged.
- `toggles completion via the checkbox control`: preserves `updateTask(id, { completed: true/false })` and invalidation behavior.
- `deletes a task`: preserves `deleteTask(id)` and invalidation behavior.
- `shows the list load error`: proves rejected `listTasks()` renders localized `focal.tasks.errors.load`.
- `shows mutation errors without clearing drafts`: proves create/toggle/delete rejections route through `onMutationError` and keep the current quick-add draft when applicable.
- `shows empty state only when the task query returns no tasks`: proves the localized empty task state appears for `tasks.length === 0`, and filtered-to-zero non-empty lists keep the grouped card shell without a separate no-match hint.
- Final command set: `cd /Users/allosta/Desktop/allosta/superapp-tasks/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `tasks.list.failed` | `listTasks()` rejects through React Query | `tasks.isError` branch in `TasksPage` | Centered localized `focal.tasks.errors.load`; quick-add and header remain visible. |
| `tasks.projects.failed` | `listProjects()` rejects through React Query | Derived project-color/project-select fallback in `TasksPage` | Rows use the primary top stripe fallback and the quick-add project select has no fetched project options; tasks still render. |
| `task.create.failed` | `createTask(input)` rejects | `createMutation.onError -> onMutationError` | Existing destructive alert with backend detail; quick-add draft remains for retry. |
| `task.toggle.failed` | `updateTask(id, { completed })` rejects | `toggleMutation.onError -> onMutationError` | Existing destructive alert with backend detail; row state returns to server state after no optimistic change/refetch. |
| `task.delete.failed` | `deleteTask(id)` rejects | `deleteMutation.onError -> onMutationError` | Existing destructive alert with backend detail; row remains because delete is not optimistic. |
| `task.blankCreate` | No exception; trimmed title is empty | `onCreate` guard before `createMutation.mutate` | No request is sent; the form stays editable. |
| `tasks.filter.zeroRows` | No exception; derived `filtered` is empty while `tasks.length > 0` | Grouped card render after successful task query | Active/Completed card shell remains visible with no row matches; no separate no-match empty state is shown. |
| `tasks.projectColor.missing` | No exception; `projectId`/`productId` has no fetched color | `topStripeColor(task)` fallback | Row top stripe uses `hsl(var(--primary))`, matching old-focal fallback. |
| `tasks.filterPanel.deferred` | No exception; advanced filters are out of scope | Filter button state in `TasksPage`; no panel render | The old-focal Filter button shell is present for the follow-up, but no advanced panel or extra filter-data queries appear in this slice. |
| `task.editDialog.deferred` | No exception; full TaskDialog is out of scope | Active-row edit affordance handler/state in `TasksPage` | The Pencil affordance is visible for row parity; final create/edit dialog behavior is deferred to `focal-redesign-tasks-dialog`. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** — This is the minimum core parity cut from the approved think doc: tasks-only page, old-focal rows, Active/Completed grouping, and in-scope header filters. Existing `api/tasks`, React Query mutations, and `taskSort.ts` remain the behavior base. Advanced filters and the full TaskDialog are explicitly named follow-ups, not partially rebuilt here.
- **Architecture** — State stays local to `TasksPage`: quick-add draft, orphan filter, priority filter, deferred filter toggle, mutation error, and optional edit affordance state. Data enters through `listTasks()` and `listProjects()` only. Filtering and grouping are pure derived arrays, sorted with `compareTasksForDisplay`. Upstream failures are handled by existing React Query branches or existing mutation `onError`.
- **Design** — The page becomes old-focal tasks-only: no tabs, no events, two cards, old-focal row stripes/treatments, old-focal header controls, and orphans inline within Active. Loading, load-error, mutation-error, `tasks.length === 0` empty, filtered-zero card shell, active, completed, orphan, and missing-project-color states are explicit. Responsive header work should stay in `TasksPage` classes unless `PageHeader` proves insufficient.
- **DevEx** — No new packages, routes, API wrappers, generated type edits, shared component edits, or abstractions. Tests should prefer accessible names, data-testid hooks for row affordances, API calls, and visible grouping behavior over brittle full-class snapshots; visual parity is still checked with light/dark screenshots.

# Risks & migrations

- No database migration, backend/API schema change, generated OpenAPI change, environment variable, package dependency, lockfile change, or data backfill.
- Main risk: exact old-focal header mobile split may not fit the generic `PageHeader` layout. Rescue: adjust only the `TasksPage` actions wrappers or, if unavoidable, use a local header inside `TasksPage`; do not edit shared shell components for this slice.
- Secondary risk: the active-row Pencil implies edit behavior while the full dialog is deferred. Rescue: keep the affordance visibly present for parity but avoid inventing a partial dialog; the follow-up owns backed edit fields and the flagged recurrence/multi-participant backend gap.
- Tertiary risk: project/product color lookup may not find a row if `listProjects()` omits nested products in a backend response. Rescue: keep the old-focal primary-color fallback and do not add product queries in this core slice.
- Rollback plan: revert the planned Tasks page, test, and locale changes. No persisted data shape or API behavior changes are introduced.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting if implemented in the ordered slices above.
- [x] Size smell checked: the page diff is structural because tabs/events are removed and rows/header are rebuilt, but it remains contained to one feature component, its tests, and locale keys. Filters panel, full dialog, API changes, and shell changes are deliberately excluded.

# Out of scope

- `focal-redesign-tasks-filters`: advanced collapsible filter panel, search, sphere/project/product/activity/tag MultiSelects, date presets, custom range, localStorage filter persistence, and filter-data API queries.
- `focal-redesign-tasks-dialog`: old-focal TaskDialog create/edit, tag creation in dialog, project -> product -> activity cascade, description/date/time editing, and replacing the interim quick-add form.
- Backend handoff for old-focal TaskDialog `recurrence` and multi-participant fields (`contactIds` / `otherParticipants`), which are not present on the current task write contract.
- Standalone Events page, week-events rendering, all/events/tasks tabs, or any `listEvents` usage from Tasks.
- Task tag-manager button, task-local AI-assistant button, per-task tag/recurrence/participant chips, server/API/schema changes, generated OpenAPI changes, `taskSort.ts` changes, shared shell changes, and unrelated redesign cleanup.
