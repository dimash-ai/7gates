# Stage

3-gate · slice 8 of the `focal-parity` epic: **Goals / MindMap modal & node-affordance parity**.
Branch `feat/focal-parity-goals` → base `feature/focal-migration` (one commit `ec8a1cf`).
Frontend-only; no server/API/schema/migration (every field maps to an already-exposed endpoint).

# What changed

The new Goals graph was already at/above old-focal parity on hierarchy, visuals, layout, drag/resize,
move-undo, create-child, and shared-calendar gating. This slice closes the safe field/affordance gaps:
- **Activity edit modal** gains `description` + `priority` + `fullDescription` (switched to patch-based
  `updateActivity`).
- **Create-project dialog** gains `priority` + a `work-time` toggle + a sphere control with
  **create-new-sphere**. Work-time ON clears+disables sphere (domain rule). New-sphere is a two-write
  transaction with **rollback**: create sphere → create project; on project-create failure the
  just-created sphere is deleted, and a rollback-failure is **logged** (not swallowed), the user error
  stays the project-create failure, dialog stays open — faithful to old-focal.
- **`fullDescription`** added to all three edit modals + plumbed through `graph.ts` into the node data,
  surfaced on the card via a `FileText` read button (only when non-empty).
- **Per-level help tooltip** on each card (read-only).
- **Inline label rename** (pencil, canEdit-only) — `FocalNode` stays presentational; the commit routes
  through a `GoalsPage` handler that owns calendar scoping + the name mutation + optimistic cache +
  snap-back-on-error.

# Files touched

All under `apps/focal/client/src/features/goals/*` (GoalsPage, FocalNode, the 3 edit modals,
CreateProjectDialog, graph.ts, goalsContext.ts, goalNodeVisuals.ts + tests) + a **one-line client-only**
type widening in the mindmap api wrapper (`updateNode` patch accepts `fullDescription`, which the server
`NodeUpsert` already supports) + the two locale files.

# Tests run

```sh
cd apps/focal/client
pnpm typecheck   # 0 errors
pnpm lint        # biome: 0 errors (284 files)
pnpm test:run    # 83 files, 957 tests passed
pnpm build       # ✓
```

# Still needs review

- **Frontend-only** — no schema/migration; client scoping is not security (slice-2 RBAC/RLS is the
  boundary). Every editing affordance is `canEdit`-gated; read affordances (help, full-desc view) are
  read-only.
- **Deferred (tracked, NOT in this slice):** edge edit dialog, drag-to-reparent + MoveProjectDialog,
  multi-select group move, schedule-to-calendar handoff, fuller undo/redo, AI-assistant button. Backend
  handoffs: budget-finance node fields + a `move-preview` counts endpoint.

# PR / release notes (for users)

The Goals map editor now lets you set an activity's **description** and **priority**, give projects a
**priority / work-time / sphere** when creating them (including **creating a new sphere** inline), add
a **long description** to any node (shown via a doc icon on the card), see a **help tooltip** on each
card, and **rename a node inline** with the pencil. Deleting/creating a project with a brand-new sphere
cleanly rolls back if the project can't be created.

(No secrets, tokens, keys, or PII — client components, locale strings, and tests.)

# Status

OPUS VERIFY/RELEASE-GATE APPROVED (9.5). Gate-A design APPROVED 9.2 (2 passes) · Gate-B build APPROVED
9.4 (2 passes — hardened the new-sphere rollback cleanup-failure logging). Cleared for release; open
the PR.
