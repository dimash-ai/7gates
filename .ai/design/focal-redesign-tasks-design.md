# Design — focal-redesign-tasks (core parity)

Rewrite `superapp-tasks/apps/focal/client/src/features/tasks/TasksPage.tsx` to old-focal Tasks
**core parity** (tasks-only, dual-stripe rows, Active/Completed cards, old-focal header), over the
existing `api/tasks` + `taskSort`, inheriting the slice-0 tokens. Binding contract:
`apps/old-focal/client/src/pages/Tasks.tsx`. Frontend-only; no API/behaviour change. Filters panel +
full TaskDialog are deferred follow-ups; the dialog's `recurrence`/multi-participant is a backend gap.

## 1. Files changed (surgical to features/tasks/* + locales)

| path | change |
|---|---|
| `features/tasks/TasksPage.tsx` | Remove tabs/events; rebuild as tasks-only with old-focal header, Active/Completed cards, old-focal rows. |
| `features/tasks/TasksPage.test.tsx` | Replace tab/event assertions with the core-parity test set (§7). |
| `i18n/locales/en.json` + `ru.json` | Add `focal.tasks.*` keys (§6); reuse old-focal copy. Remove none unless extraction proves unused. |

**Unchanged:** `taskSort.ts`/`taskSort.test.ts`, `api/tasks.ts`, `api/projects.ts`, `api/events.ts`
(import simply dropped from this page), shell, shadcn primitives. No new dependency.

## 2. Remove (tab/events coupling)

Delete: `type Tab`, `tab`/`setTab` state, `TABS`/`tabs`, the `Layers`/`Calendar`/`CalendarEvent`
imports + `listEvents` import, `week`/`dayFormatter`/`events` query/`eventDays`/`eventCount`,
`EventRow`, `WeekEvents`, and the `tab === 'all'`/`'events'` branches + `summaryAll`/`summaryEvents`.
The page renders the tasks view unconditionally.

## 3. Header (old-focal controls via `PageHeader`)

Keep the shell `PageHeader` (do not edit it). `title` = `focal.tasks.title`, `icon` = `CheckSquare`,
`help` = `focal.tasks.help`.

- **`leftActions`** = the **Add** button — old-focal's **icon-size** button (`Tasks.tsx:920`) with
  `Plus`, focusing the interim quick-add (§5).
- **`rightActions`** = a **Filter** toggle button using old-focal's **`Filter`** icon
  (`Tasks.tsx:938`) that toggles `showFilters` (the anchor for the deferred `…-tasks-filters` panel —
  **not** rendered here). **No active-count** is shown on the Filter button in this slice: old-focal's
  `hasActiveFilters`/`activeFiltersCount` (`Tasks.tsx:470`,`:483`) deliberately **exclude** the
  always-visible orphan/priority selects, so the Filter count arrives with `…-tasks-filters`. Then the
  **orphan select** (`all`/`orphans`/`classified`/`completed`/`active`, old-focal `Tasks.tsx:344-352`
  semantics), the **priority select** (`all`/`high`/`medium`/`low`), and the **count badge** (§4). The
  two selects stay **native `<select>`** styled via `selectClasses` (the new app's established control,
  visually matching old-focal's compact selects — tune to old-focal's `h-8`), a deliberate
  visually-equivalent choice; shadcn `Select` (old-focal `:948`/`:960`) is an optional higher-fidelity
  follow-up.

State: `orphanFilter`, `priorityFilter`, `showFilters` (default `'all'`/`'all'`/`false`). Drop the
old `projectFilter`/`statusFilter` (those were the tab-era header dropdowns).

## 4. Filtering, grouping, count badge

**Priority normalization (contract — old-focal `Tasks.tsx:355`, `taskSort.ts:73`):**
`priorityOf(task) = task.priorityLevel ?? 'medium'` — **no** `?? task.priority` fallback.

**Filter chain** over `allTasks = tasks.data ?? []`:
- orphan: `all`→keep; `orphans`→`task.isOrphan`; `classified`→`!task.isOrphan`;
  `completed`→`task.completed`; `active`→`!task.completed`.
- priority: `all`→keep; else `priorityOf(task) === priorityFilter`.

**Groups** (orphans inline within Active, per old-focal — no separate orphan group):
`activeTasks = filtered.filter(t => !t.completed).sort(compareTasksForDisplay)`;
`completedTasks = filtered.filter(t => t.completed).sort(compareTasksForDisplay)`.

**Count badge (incomplete-only — old-focal `Tasks.tsx:906`,`:987-991`):**
`totalActive = allTasks.filter(t => !t.completed).length` (raw, unfiltered);
`filteredActive = filtered.filter(t => !t.completed).length`;
text = `filteredActive !== totalActive ? t('focal.tasks.countOf', {filtered: filteredActive, total: totalActive}) : t('focal.tasks.countActive', {count: filteredActive})`.
Never use `allTasks.length`/all-status counts in the badge.

## 5. Body — interim quick-add + Active/Completed cards

- **Quick-add form** (interim create path; kept until `…-tasks-dialog`): the existing title/priority/
  project form + `createMutation`, restyled to sit above the cards without fighting them
  (`rounded-lg border bg-card p-3 shadow-xs`). The header **Add** button focuses its title input.
- **Loading** `focal.tasks.loading`; **load error** `focal.tasks.errors.load` (role="alert");
  **empty** hint rendered **only** when `allTasks.length === 0` (old-focal `Tasks.tsx:1438`) →
  `focal.tasks.empty`. A filter that yields zero rows renders **neither** card (each card below is
  conditional on its own group having rows) and **no** empty hint — a blank content area, matching
  old-focal's single `tasks.length === 0` trigger.
- **Active card** (when `activeTasks.length`): `Card` › `CardHeader className="pb-3"` ›
  `CardTitle className="text-lg"` = `focal.tasks.groups.active` › `CardContent className="space-y-2"`
  with active rows.
- **Completed card** (when `completedTasks.length`): same, `CardTitle` muted, completed rows.
- Container: `flex-1 overflow-auto p-4 md:p-6` › `mx-auto max-w-4xl space-y-6`.

## 6. Row markup (old-focal exact — `TaskRow` rewritten)

Shared container: `relative overflow-hidden flex items-center gap-3 p-3 rounded-md flex-wrap`
(**`hover-elevate` is added on active rows only** — old-focal completed rows have none). Project-color
**top stripe**: `absolute top-0 left-0 right-0 h-1 rounded-t-md`, color =
`projectColor(task)` (look up `projects.data` by `productId` then `projectId`; fallback
`hsl(var(--primary))`). **Left priority stripe**: `w-1 self-stretch rounded-full shrink-0`, color by
`priorityOf(task)` — old-focal palette **high `#ef4444` / medium `#eab308` / low `#9ca3af`**
(`Tasks.tsx:1292`-region). Checkbox = shadcn `Checkbox` (toggle → `toggleMutation`). Title =
`flex-1 truncate text-sm`.

- **Active rows:** add **`hover-elevate`**; container `bg-muted/50`, **or** orphan treatment when `task.isOrphan`:
  `bg-amber-50 dark:bg-amber-950/20 border border-dashed border-amber-400` + an `AlertTriangle`
  (`text-red-500`, old-focal `Tasks.tsx:1314`) + the orphan **badge** (`variant="outline"`,
  `text-amber-600 border-amber-300 text-xs`,
  label from `focal.tasks.orphanReasons.*`/generic). **Project-type badge** (`variant="secondary"`):
  `mission` → `bg-red-500/20 text-red-600 dark:text-red-400`, `provision` →
  `bg-gray-500/20 text-gray-600 dark:text-gray-400` (compare `task.projectType` as `string | null`;
  no closed-union cast). **Edit (Pencil)** ghost `size="icon"` + **Delete (Trash2)** ghost
  `size="icon"`. The Pencil is **rendered for parity but disabled** (`aria-label`
  `focal.tasks.actions.edit`, `title` noting edit arrives with the dialog) — the full edit dialog is
  `…-tasks-dialog`; do not wire a partial dialog.
- **Completed rows:** `opacity-60` + title `line-through`, **delete only** — no edit, no project-type
  badge (old-focal `Tasks.tsx:1415`). **No `hover-elevate`.** Container = `task.isOrphan` ? old-focal's
  **dimmer** completed-orphan amber (`bg-amber-50/50 dark:bg-amber-950/10 border border-dashed
  border-amber-300`, old-focal `Tasks.tsx:1384`-`1387`) : `bg-muted/30`.

`TaskLinkChips`/`Flag`/`Unlink` pill from the current row are replaced by old-focal's badge/stripe
treatment above; `EventRow`/`WeekEvents` deleted.

## 7. Tests (`TasksPage.test.tsx` rewritten)

Mock `api/tasks`, `api/projects`, `api/events`. Cover: (a) **tasks-only** — `listEvents` never
called, no tab buttons, no week-events heading; (b) **header controls** present (Add, Filter toggle,
orphan select, priority select, count badge) + no AI/tag-manager button; (c) **count-badge numbers**
— with a filter active assert `2 of 5` (resolved i18n value / number regex, not the English literal);
no filter → `5 active`; (d) **orphan filter** semantics (`orphans`/`classified`/`completed`/`active`);
(e) **priority** uses `priorityLevel ?? 'medium'` (a task with `priorityLevel:null, priority:'high'`
buckets as medium); (f) **grouping** into Active/Completed, orphans inline in Active (no separate
group); (g) **active row** affordances (stripe, project-type badge, disabled edit, delete) vs
**completed row** (line-through, delete only, no edit/badge); (h) **CRUD payloads** unchanged
(create `{title, priority:'medium', projectId:null}`, toggle `{completed}`, delete by id) +
invalidation; (i) **load error** + **mutation error** banner; (j) **empty** only when zero tasks.

## 8. Verification + rollback

`cd superapp-tasks/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.
Screenshot light+dark vs `apps/old-focal` Tasks (filters panel + full dialog intentionally absent;
interim quick-add present). **Rollback** = revert `TasksPage.tsx` + its test + the locale keys; no
API/data/contract change. Failure modes carried from the plan's error map (list/projects/create/
toggle/delete failures → existing React-Query branches + the alert banner; missing project color →
primary fallback; filter→zero → blank cards; deferred edit/filter panel).
