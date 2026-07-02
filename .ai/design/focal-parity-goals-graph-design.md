# Design: focal-parity-goals-graph (Goals graph — interaction follow-up)

3-gate flow. The **deferred-interaction follow-up** to `focal-parity-goals` (slice 8). The first
goals slice (merged, #99 + the goal-map PRs #83–#91) closed the safe set — modal fields,
create-project options, `fullDescription`, help tooltip, inline rename, node resize, edge styling
editor, undo/redo history. That slice explicitly deferred the **heavier interactions** to "a focused
follow-up slice" (`focal-parity-goals-design.md` → Out of scope). This is that slice. Branch
`feat/focal-parity-goals-graph` → base `feature/focal-migration`. **Frontend-only.**

## Problem & decision

The last old-focal Goals behaviors still missing from the new graph are the **structural
interactions**: dragging a project onto another pillar/parent to **reparent** it (with a confirm
dialog showing from→to + the affected sub-entities), and **scheduling a node to the calendar**
(turning a goal node into a calendar event/task). Today nodes drag for *position only*
(`moveProject` PATCHes x/y); there is no reparent gesture, no move-preview, no schedule action.

**Decision — reuse existing contracts; no backend work** (this supersedes the prior doc's assumption
that move-preview needs a new endpoint):
- **Reparent** rides the existing `PATCH /api/projects/{id}` — it already accepts `parentProjectId`
  (nest under a project) and `parentType` (file under a pillar), and the service already guards cycles
  (`services/projects.py:_guard_reparent` — not self, not a descendant). `buildGraph`'s branch-colour
  cascade recolours the moved subtree on the next `init`, so no extra recolour work.
  - **Must clear the opposite parent field.** `update_project` does `model_dump(exclude_unset=True)`
    and `setattr`s only the sent fields (`services/projects.py:135-143`), and the schema accepts
    explicit nulls (`schemas/projects.py:50-51`). So a reparent **always sends both** parent fields,
    nulling the one that doesn't apply — otherwise a product moved to a pillar would keep its old
    `parentProjectId` and stay nested. Pillar → `{ parentType: <pillar>, parentProjectId: null }`;
    under a project → `{ parentType: null, parentProjectId: <target> }`; to root → both null.
- **Move-preview affected counts are computed client-side** from the already-loaded
  `/api/mindmap/init` payload (it carries every project + activity). The prior doc flagged a missing
  `move-preview` endpoint as a backend handoff; reading the data layer shows the counts are derivable
  in the client, so **no endpoint, no handoff** — the reuse-first choice.
- **Schedule-to-calendar** reuses the calendar's existing create flow: the node action stows a draft
  in `sessionStorage` and navigates to `/calendar`, which reads it once on mount and opens the create
  popover prefilled — the same handoff shape old-focal used (`MindMap.tsx:2656/2666`). The **goals side
  resolves the node's owning `projectId`/`productId` from the loaded graph** and writes those into the
  draft — events file by `project_id`/`product_id` only and a project-less event is treated as orphaned
  (`services/calendar.py:823`), so a scheduled product/activity must carry its parent project (and
  product) ids, never a raw activity id.

**Rejected:** new backend `/move` + `/move-preview` endpoints (old-focal had them). Rejected by the
reuse-first ladder — the PATCH reparent + cycle guard already exist and the counts are client-derivable.

## Assumptions & scope

- **[confirmed — code]** `PATCH /api/projects/{id}` accepts `parentType`/`parentProjectId` and guards
  reparent cycles server-side (`schemas/projects.py:39-57`, `services/projects.py` `_guard_reparent`,
  `update_project`). The client `updateProject` already sends `parentProjectId`; only a thin
  `reparentProject` wrapper (parentType **or** parentProjectId **or** both-null→root) is added.
- **[confirmed — code]** `/api/mindmap/init` returns all projects + activities → affected-entity counts
  (products under a project; activities under it/its products) are computed client-side from the graph.
- **[confirmed — code]** Branch colour cascades from pillar/parent in `buildGraph` → a reparent
  recolours the subtree on refetch with no extra work.
- **[confirmed — code]** Goals already consumes `canEdit` (66 refs) → reparent + schedule actions gate
  on it; a read-only shared-calendar viewer cannot restructure.
- **[confirmed — greps]** Edge styling editor, budget/finance node fields, and undo/redo are already
  present (merged) → **out of scope, do not re-touch**.
- **[unverified — verify at build]** Whether multi-select/group-move, drag-off-a-node to create a
  child, and the "activity cannot be added to a product-less project" regression are already handled.
  **Inspect first; implement only what's still missing** (do not re-do merged work).
- **Out of scope:** anything already merged (modal fields, create-project options, fullDescription,
  help tooltip, rename, resize, edge editor, finance fields, undo/redo, auto-layout); any backend
  change (none needed); calendar interaction parity (slice 6); AI-assistant header button.
- **Open questions:** None blocking.

## Success criteria

- [ ] Dragging a root-project node onto a different pillar (or onto/off another project) opens a
      **confirm dialog** with from→to and the count of affected products/activities; confirm PATCHes the
      new parent and the subtree reparents + recolours; cancel restores the node to its origin.
- [ ] A drop onto the project's own descendant is **rejected client-side** (no PATCH), with the server
      cycle-guard as the second line.
- [ ] A node exposes a **"schedule to calendar"** action that navigates to `/calendar` with the node's
      data prefilled into a create draft (via sessionStorage), opening the create surface; the draft is
      consumed exactly once.
- [ ] Reparent + schedule are disabled with a read-only affordance when `!canEdit`; a reparent pushes
      a structural `history` entry whose **undo restores the prior parent** and **redo re-applies** the
      move, and a failed undo/redo PATCH leaves the stack unchanged (tested).
- [ ] Multi-select/group-move, drag-to-create-child, and product-less-activity creation are confirmed
      present (or implemented if missing), each with a test.
- [ ] A scheduled node's draft always carries a non-null `projectId`; specifically a **product-owned
      activity** draft carries both the resolved parent `projectId` and its `productId` (so the created
      event is filed, never orphaned) — tested.
- [ ] `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green; ru+en; surgical diff confined
      to `features/goals/*`, a small `features/calendar/CalendarPage.tsx` read-on-mount, `api/mindmap.ts`,
      and the two locale files; **no backend change**.

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| 1 | **Drag-to-reparent + move-preview** — drop-target detection (pillar/project), `MoveProjectDialog` (from→to + client-computed affected counts + optional sphere/work-time reassignment), confirm → `reparentProject`; client cycle guard; `canEdit`-gated; undo entry | `features/goals/GoalsPage.tsx`, new `features/goals/MoveProjectDialog.tsx`, `features/goals/graph.ts` (pure `affectedCounts`/`isDescendant`/`dropTarget` helpers), `api/mindmap.ts` (`reparentProject`), `i18n/locales/*` | drop on a descendant → rejected, no PATCH; valid drop → PATCH with the right parent; counts match the subtree; `!canEdit` → no PATCH |
| 2 | **Schedule-to-calendar from a node** — node action builds a draft → sessionStorage → navigate `/calendar`; calendar reads the draft once on mount and opens create prefilled | `features/goals/*` (node action via `goalsContext` handler), `features/calendar/CalendarPage.tsx` (read-once + open create), `lib/` handoff key, `i18n/locales/*` | action writes the expected draft + navigates; calendar consumes once + opens create prefilled; `!canEdit` → action hidden |
| 3 | **Verify/fill** — multi-select group-move, drag-to-create-child, product-less-activity creation; implement ONLY those still missing after inspection (may be a near-no-op) | `features/goals/*` as needed | each confirmed behavior has a test; a product-less project can gain an activity |

## Architecture & contracts

| entity / interface | change | notes |
|--------------------|--------|-------|
| `api/mindmap.ts` `reparentProject(id, target, calendarId)` | add | thin wrapper over `PATCH /api/projects/{id}` that **always sends both parent fields** (the server's `exclude_unset` applies only sent fields): pillar → `{ parentType: <pillarId>, parentProjectId: null }`; under a project → `{ parentType: null, parentProjectId: <id> }`; to root → `{ parentType: null, parentProjectId: null }`. Reuses the existing endpoint + server cycle guard |
| `features/goals/history.ts` structural entry | extend | today the undo stack is position-only; add a tagged entry `{ kind: 'reparent', projectId, before: {parentType, parentProjectId}, after: {…} }` alongside the existing move entry (discriminated union). **Undo** = `reparentProject(projectId, before)`, **redo** = `reparentProject(projectId, after)`. On a PATCH failure during undo/redo, surface a localized error and **leave the stack unchanged** (don't pop) so it stays consistent. `before` is captured from the dragged project's current `parentType`/`parentProjectId` at drop time |
| schedule draft (sessionStorage) | add | key `focal:schedule-draft`; shape `{ source: 'goals'; title: string; projectId: string; productId?: string; ts: number }`. **The goals side resolves the hierarchy from the loaded `/api/mindmap/init` graph and ALWAYS writes a non-null `projectId`** (the node's root project, found by walking `parentProjectId` up `init.projects`), plus `productId` when the node is — or hangs under — a product. A raw `activityId` is never used: events link by `project_id`/`product_id` only and a project-less event is orphaned (`services/calendar.py:204,800,823`). Cases: **project node** → `{ projectId: self }`; **product node** (a project nested under a root) → `{ projectId: rootProjectOf(self), productId: self }`; **activity under a project** → `{ projectId: activity.projectId }`; **activity under a product** (has only `productId`) → `{ projectId: rootProjectOf(product), productId: activity.productId }`. Calendar maps the draft into a new `EventDraft` (title ← title; projectId/productId ← draft; date/time ← the default new-event slot; `calendarId` ← active `currentCalendarId`). Consumed once (removed on read); ignored if absent, malformed, or older than a short TTL |
| `features/goals/graph.ts` move helpers (pure) | add | `affectedCounts(init, projectId) → { products, activities }`; `isDescendant(init, projectId, candidateParentId)` (client cycle guard); `dropTarget(nodeId) → {kind:'pillar'\|'project'} \| null` |
| `features/goals/MoveProjectDialog.tsx` | add | from→to labels, affected counts, optional sphere/work-time picker, confirm/cancel — mirrors old-focal `MoveProjectDialog` |
| `features/calendar/CalendarPage.tsx` | modify (small) | on mount, consume a one-shot sessionStorage schedule-draft and open the create popover prefilled |
| backend | **none** | reparent PATCH + cycle guard exist; counts client-side |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — reparent | drag project onto pillar/project, confirm | GoalsPage drop handler → `reparentProject` | subtree reparents + recolours on refetch; undo entry pushed |
| happy — schedule | node "to calendar" action | GoalsPage handler → sessionStorage + navigate | calendar opens create popover prefilled |
| cycle attempt | drop onto own descendant | client `isDescendant` guard (pre-PATCH) | rejected with a notice; no request; server guard is 2nd line |
| read-only | `!canEdit` | action guards | reparent/schedule disabled with a localized read-only affordance; no PATCH |
| reparent PATCH fails | `ApiError` | mutation `onError` | node snaps back to old parent; localized error; undo stack consistent |
| stale/foreign draft | leftover sessionStorage draft | calendar read-once (cleared after consume) | consumed exactly once; stale draft ignored |

## Test strategy, security & rollback

- **Test strategy:** unit (pure) for `affectedCounts` / `isDescendant` / `dropTarget` (the risky
  logic); component for the dialog (counts render, confirm/cancel, `!canEdit` disables), the GoalsPage
  drop handler (valid / cycle / read-only → correct/zero PATCH), and the schedule handoff (writes draft
  + navigates; calendar consumes once + opens create). "Verified" = `pnpm lint/typecheck/test:run/build`
  green + a test per success criterion.
- **Security:** client scoping is not security — reparent goes through the tenant/role-checked,
  ownership-guarded PATCH (`_require` + `_guard_reparent`); the blocked viewer UI is UX only. No new
  endpoint/auth surface. sessionStorage holds only a non-sensitive create draft, consumed once.
- **Rollback:** frontend-only — revert the slice commits; no migration, no data/format change.
