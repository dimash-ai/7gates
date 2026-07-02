# Goal

Bring the new Focal **Tasks page** (`apps/focal/client/src/features/tasks`) to **exact visual
parity with `apps/old-focal`'s Tasks page** (`pages/Tasks.tsx` + `components/TaskItem`/`TaskDialog`),
over the new app's **existing** tasks API, inheriting the shell foundation (slice 0). Frontend-only,
no behaviour/API change. Part of the `focal-redesign-pages` epic ("exact old-focal everywhere").

> **Binding visual contract** = `apps/old-focal/client/src/pages/Tasks.tsx` (+ `components/TaskItem.tsx`,
> `TaskDialog.tsx`, `TaskInfoDialog.tsx`). **Thing changed** = `apps/focal/client/src/features/tasks/*`.
> **Worktree:** code work happens in `superapp-tasks/` (branch `feat/focal-redesign-tasks`, off the
> shell foundation `afaaeba`); `.ai/` artifacts stay in the pipeline root.

> **Fully backable (verified, no faking):** `EnrichedTaskRead` exposes `isOrphan`, `orphanReason`,
> `projectName`, `projectType`, `sphere`, `priority`/`priorityLevel`, `dueDate`/`dueTime`, `tags`,
> `projectId`/`productId`/`activityId`, `isWorkTime`, `projectHasProducts`; and `api/{projects,
> products,activities,tags,spheres}.ts` all exist. So old-focal's rows AND its advanced filters are
> backable on the existing contract — nothing is backend-blocked.

# Scope (this slice = Tasks page CORE parity)

The structural delta old-focal↔new is large, so this slice takes the **core page parity** and defers
two large self-contained chunks to named follow-ups (below):

- **Drop the new app's tabs.** old-focal's Tasks page is **tasks-only**; the new app folds
  `all`/`events`/`tasks` into a 3-tab UI. Match old-focal: the page shows tasks only (events live on
  their own page — the later `focal-redesign-events` slice). Remove the all/events tabs + `listEvents`
  usage from this page.
- **Task rows → old-focal exact.** **Active** rows: dual stripe (left **priority** + **top project-
  color**), checkbox, truncating title, **orphan** treatment (amber dashed container + amber badge),
  **project-type** badge (mission red / provision gray), **edit (pencil) + delete (trash)** ghost
  icon buttons, `hover-elevate`. **Completed** rows: `opacity-60` + line-through title + **delete
  only** — no edit, no project-type badge (per old-focal `Tasks.tsx:1415`).
- **Grouping → old-focal:** the two cards — **"Активные задачи"** and **"Выполненные"** — with
  old-focal's CardHeader/CardTitle styling (orphans shown inline within active via the amber
  treatment, as old-focal does).
- **Header → old-focal:** old-focal's desktop/mobile split header — title + **Add** button + help
  tooltip + **Filter** toggle (active count) + task-count badge **+ the always-visible orphan select
  + priority select** (`Tasks.tsx:948`/`:960`). **Deferred (explicit):** the **AI-assistant button**
  (`:930` — AI integration, separate) and the **tag-manager button** (`:971` → the tags/filters slice).
- Wire to the **existing** `api/tasks` (`list/create/update/delete` + toggle) — unchanged behaviour.

# Out of scope (named dependent follow-up slices — backable, deferred for size)

- **`focal-redesign-tasks-filters`** — the advanced collapsible filter panel (search + sphere /
  project / product / activity / tag **MultiSelect** + old-focal's 14-value date-preset union incl.
  `custom`), wired to `api/{spheres,projects,products,activities,tags}`. Large + self-contained;
  depends on this slice's header Filter toggle. (Backable — not faked.)
- **`focal-redesign-tasks-dialog`** — old-focal's **TaskDialog** create/edit for the **backable**
  fields (date/time, tags incl. create, project→product→activity cascade, single `contactId`,
  description), replacing the interim quick-add form. **Flagged backend gap (not faked):** old-focal's
  `recurrence` + multi-participant (`contactIds`/`otherParticipants`) are on the **event** contract,
  not `TaskCreate`/`TaskUpdate` — a named backend handoff precedes those dialog fields. (old-focal
  `TaskDialog.tsx` is 26 KB.)
- Any **server / API / schema / behaviour** change; the standalone **Events** page (its own slice);
  per-task tag/recurrence/participant chips on the row (old-focal's Tasks row doesn't show them
  either — they live in the dialog).

# Acceptance criteria

- [ ] From `superapp-tasks/apps/focal/client`: `pnpm lint && pnpm typecheck && pnpm test:run &&
      pnpm build` all green (incl. updated `TasksPage.test.tsx`).
- [ ] The Tasks page matches old-focal in **light and dark**: tasks-only (no tabs), the dual-stripe
      rows with orphan + project-type treatment and edit/delete buttons, the Active/Completed cards,
      and the old-focal header — verified by screenshot vs `apps/old-focal`.
- [ ] Behaviour preserved on real data: list/create/toggle/delete still work; sort order unchanged
      (`taskSort.ts`); no regression beyond the intentional tab removal.
- [ ] Surgical diff scoped to `features/tasks/*` (+ any new local row/dialog component); no API change;
      i18next `ru` + `en`; the deferred filters/dialog are flagged, not faked.

# Verification commands

```sh
cd superapp-tasks/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```
