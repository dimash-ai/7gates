# Design — focal-parity slice 8: Goals / MindMap modal & node-affordance parity

3-gate flow · slice 8 of the `focal-parity` epic. Branch `feat/focal-parity-goals` → base
`feature/focal-migration`. **Frontend-only** — every gap in this slice's scope consumes fields the
new backend already exposes (`full_description` on nodes/projects/activities; `priority`/`description`
on activities; `priority`/`is_work_time`/`sphere` on project-create). No server/API/schema/migration.

## Problem / intent

A full old-vs-new audit found the new Goals graph is already at or above old-focal parity on node
hierarchy, visuals, branch-color inheritance, layout (the new tidy-tree *exceeds* old-focal's manual
placement), drag/resize persistence, move-undo, create-child flows, and shared-calendar `canEdit`
gating. The remaining gaps split into:

- **Safe, frontend-only field/affordance gaps** (this slice) — the modals drop fields old-focal
  edited, and the node cards drop two affordances old-focal had.
- **Heavier interaction features** and **backend-touching features** — deferred (see Out of scope),
  because they carry real risk (edge graph mutation, cycle-guarded reparent, multi-select) or need a
  new endpoint / typed columns, which is a dev migration handoff, not an unattended overnight slice.

This slice closes the safe set for a clean parity increment:

1. **Activity edit modal** — add the missing `description` + `priority` fields.
2. **Create-project dialog** — add the missing `priority`, `work-time` toggle, and inline
   "create new sphere" that old-focal's create-project had.
3. **`fullDescription`** — add the long-description field to the three edit modals
   (Node/Project/Activity) and surface it on the node card via a `FileText` button that opens a
   read view (matching old-focal's per-card full-description affordance).
4. **On-card help tooltip** — the per-level `HelpCircle` explainer old-focal showed on each card.
5. **Inline label rename** — the on-card pencil that renames a node without opening the full modal.

## Assumptions

- The backend already persists every field this slice writes (audit-confirmed:
  `ActivityUpdate.{description,priority}`, `ProjectCreate.{priority,is_work_time,sphere}`,
  `full_description` on the node/project/activity read+update schemas). This slice adds **no** field
  to any schema and changes **no** query/mutation contract — it only fills in form inputs and
  card affordances that map to already-wired endpoints. If any field turns out NOT to round-trip
  through the existing mutation, **stop and flag** rather than touching the server.
- Editing stays behind the existing `canEdit` gate (shared-calendar read-only when not owner/editor)
  — every new input/affordance is disabled or hidden when `!canEdit`, exactly like the existing
  modal Save/Delete.
- `currentCalendarId` scoping is untouched — no new query keys, no new calendarId surface.
- Visual fidelity to old-focal need not be pixel-identical; field-and-affordance parity is the bar.

## Approach

All changes live under `apps/focal/client/src/features/goals/` + the two locale files. Reuse-first:
the modals, `FocalNode` card, the `useCalendarFilter` gate, the existing project/activity/node
mutations, and the shadcn primitives (`tooltip`/`popover`/`dialog`/`select`/`textarea`) all already
exist — nothing new is installed.

### 1. Activity modal — description + priority (`ActivityEditModal.tsx`)

Add a `description` `Textarea` and a `priority` `Select` (reuse the same priority options/labels the
Project modal already uses — `ProjectEditModal.tsx`). Wire both into the existing activity-update
mutation payload. Both disabled when `!canEdit`.

### 2. Create-project dialog — priority + work-time + new-sphere (`CreateProjectDialog.tsx`)

Add a `priority` Select, an `is_work_time` toggle, and a sphere control. Honor the domain rule
(root `apps/focal/CLAUDE.md`): when `is_work_time` is true, `sphere` must be null (disable/clear the
sphere control while work-time is on). All inputs map to the existing `ProjectCreate` payload.

**New-sphere create — two-write transaction with rollback (explicit contract).** Creating a project
with a brand-new sphere is two sequential writes, and old-focal treats them transactionally: it
creates the sphere, then the project with that sphere name, and **deletes the just-created sphere if
project creation fails** (`apps/old-focal/client/src/components/MindMap/MindMap.tsx:4821`). Both the
sphere create+delete endpoints already exist server-side (`apps/focal/server/app/api/spheres.py`), so
this stays frontend-only. The required state transition:
1. User picks "create new sphere" and enters a name → on submit, fire the **sphere-create** mutation
   first.
2. While either mutation is pending, the dialog's submit + sphere controls are **disabled** (no
   double-submit, no partial state).
3. On sphere-create success, fire **project-create** with the new sphere's name.
4. **On project-create failure, roll back** by deleting the just-created sphere (the existing
   spheres-delete endpoint), then surface the error and leave the dialog open for retry. On
   sphere-create failure, surface the error and create nothing.
This rollback reuses the existing sphere mutations/hooks — check `features/` for the established
sphere-create/-delete hooks and call those (reuse-first); do not add an endpoint. If, while building,
the existing hooks turn out not to expose delete, **stop and flag** rather than scope-creeping — and
in that case ship item 2 with priority + work-time + **select-from-existing-spheres only**, deferring
create-new with the gap noted.

### 3. `fullDescription` field + card button (`NodeEditModal.tsx`, `ProjectEditModal.tsx`, `ActivityEditModal.tsx`, `FocalNode.tsx`)

- Add a `fullDescription` `Textarea` (the longer free-text field, distinct from the short
  `description`) to each of the three modals, wired into the existing update payloads. Disabled when
  `!canEdit`.
- **Data plumbing (explicit):** `graph.ts` must carry `fullDescription` into the node's
  `FocalNodeData` for base/project/activity nodes (it isn't today) **before** `FocalNode` can read it —
  thread it where `graph.ts` already maps `description`/color/icon onto the node data.
- On `FocalNode`, when a node has a non-empty `fullDescription`, render a small `FileText` icon
  button that opens a lightweight read-only dialog showing the text (old-focal opened a long-desc
  dialog from the card). The button is always visible for read (not gated by `canEdit` — viewing a
  description is a read action); editing happens in the modal.

### 4. On-card help tooltip (`FocalNode.tsx`, `goalNodeVisuals.ts` or a small helper)

Add a `HelpCircle` trigger on the card that shows a per-level explainer (base pillars vs project vs
product vs activity) via the existing `Tooltip`/`Popover` primitive. Text comes from i18n keyed by
the node's level. Read-only affordance (always available).

### 5. Inline label rename (`FocalNode.tsx`)

Add a pencil affordance on the card (shown only when `canEdit`) that turns the label into an inline
text input; committing (Enter/blur) fires the existing name-update mutation for that entity type;
Escape cancels. Guard against empty/whitespace names (no-op on empty, matching the modal's
validation). **Keep `FocalNode` presentational:** the rename commit routes through a
GoalsPage/`goalsContext` handler (e.g. `onRenameNode(node, newName)`) that owns the
`currentCalendarId` scoping, the existing name-update mutation, cache invalidation, and error
recovery — exactly as the existing modal-save path does. `FocalNode` only holds the local
editing/draft state and calls the handler; it does not own mutations or calendar scoping.

### i18n

New keys under `translation.focal.goals.*` (or the existing goals namespace — match the current
nesting) in BOTH `en.json` + `ru.json`: activity `description`/`priority` labels (reuse existing
priority option labels if already keyed), create-project `priority`/`workTime`/`sphere`/`newSphere`
labels, `fullDescription` label + the read-dialog title, the per-level help-tooltip texts
(`help.base`/`help.project`/`help.product`/`help.activity` or similar), and the inline-rename
aria/placeholder. Reuse existing keys wherever the Project modal already defines them (priority,
work-time, sphere) rather than duplicating. Every new EN key mirrored in RU with a real translation.

## Out of scope / deferred

**Deferred frontend interaction features (bigger/riskier — a focused follow-up slice, not overnight):**
- Edge edit dialog + clickable edge styling (graph-edge mutation; backend PUT/DELETE exists).
- Drag-to-reparent project onto a pillar + drop highlight + `MoveProjectDialog` (cycle-guarded
  reparent exists server-side, but the affected-counts **preview** needs a `move-preview` endpoint
  that does NOT exist in the new app — see backend handoff).
- Selection mode / box multi-select group move; drag-handle connect-to-create-child;
  schedule-to-calendar handoff; fuller undo/redo (create/delete/edit/reparent/edge — today only
  moves are undoable); AI-assistant header button; grid-snap on drag; on-canvas hint bar.

**Backend handoffs (NOT in any frontend slice — flag to the developer):**
- **Budget-finance node fields** (currency / total-to-earn / monthly-income on budget pillars). These
  can ride the existing `mindmap_nodes.node_data` JSONB with no migration, but the typed-column
  alternative is a migration decision — defer to a dev handoff.
- **`move-preview` affected-counts endpoint** — needed only for the reparent confirmation preview.

If, while building, the new-sphere create path (item 2) or any `fullDescription` round-trip turns out
to need a backend change, **stop and flag it** as a handoff rather than editing the server.

## Acceptance criteria

1. **Activity modal:** description + priority inputs render, persist through the existing activity
   update, and are disabled when `!canEdit`.
2. **Create-project:** priority + work-time + sphere inputs render and map to `ProjectCreate`;
   turning work-time on clears/disables sphere (domain rule); new-sphere either reuses an existing
   in-app create path or is honestly limited to existing spheres with the gap flagged.
3. **fullDescription:** present in all three modals (persists via existing updates); the `FileText`
   card button appears only when `fullDescription` is non-empty and opens a read view; editing gated
   by `canEdit`.
4. **Help tooltip:** each card exposes a per-level help tooltip with localized text; always available.
5. **Inline rename:** pencil appears only when `canEdit`; committing renames via the existing
   mutation; Escape cancels; empty/whitespace is a no-op.
6. **Gating:** every editing affordance respects `canEdit`; read affordances (help, full-desc view)
   work read-only. No new query keys / calendarId surface.
7. **i18n parity:** every new EN key has an RU counterpart; no hardcoded user-facing strings; reuse
   existing priority/work-time/sphere keys where present.
8. **Green bar:** `pnpm typecheck`, `pnpm lint`, `pnpm test:run` (new tests for the activity fields,
   create-project work-time→sphere rule, fullDescription persistence + card-button visibility, the
   help tooltip, and the inline-rename commit/cancel/empty paths), `pnpm build` all pass. Diff is
   surgical and confined to `features/goals/*` + the two locale files.

## Risk

Low. All frontend, no compute/data/schema; every field maps to an already-wired endpoint; editing
stays behind the proven `canEdit` gate. The only judgment call is the new-sphere create path
(mitigated by reuse-first + a stop-and-flag rule if it would need backend work). Rollback = revert the
client files.
