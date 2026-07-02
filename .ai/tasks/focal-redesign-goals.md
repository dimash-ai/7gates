# Goal

Bring the new Focal **Goals page** ("Карта целей" — the goal-map) to **exact visual parity with
`apps/old-focal`**, reproduced on the new stack over the new app's **existing** mind-map APIs. This
is the `focal-redesign-goals` slice of the `focal-redesign-pages` epic (see
[`.ai/think/focal-redesign-pages.md`](../think/focal-redesign-pages.md)) — it inherits the epic's
binding rules: **exact old-focal look**, **re-skin not rebuild**, **reproduce not copy**
(React 19 / Tailwind 4 / shadcn), **presentation parity, behaviour preserved**.

> **Binding visual contract** = old-focal's goal-map: `apps/old-focal/client/src/pages/Goals.tsx`
> (the page header wrapper) + `apps/old-focal/client/src/components/MindMap/*` — `MindMap.tsx`
> (orchestrator), `PyramidNode.tsx` (base + project/activity node visuals), `GoalNode.tsx`,
> `TaskNode.tsx`, `FloatingEdge.tsx`. The live `focal.allosta.com` "Карта целей" screenshot is this.
> **The thing being re-skinned** = `apps/focal/client/src/features/goals/*` (`GoalsPage.tsx`,
> `FocalNode.tsx`, `FloatingEdge.tsx`) on the **new stack** + the shell tokens already merged.

> **Already functional — re-skin only.** The new Goals feature is a working @xyflow/react (12.11)
> mind-map: same 7-base-node pyramid (life-goal → mission → standard → 4 pillars), projects /
> products / activities loaded from `/api/mindmap/init`, `FocalNode` cards, `FloatingEdge`, tidy
> auto-layout (`layout.ts`), undo/redo of moves (`history.ts`), drag-to-move persisted
> (`moveProject`/`moveActivity`/`moveNode`), and create/edit modals (`CreateProject/Activity/Child`,
> `ProjectEditModal`/`ActivityEditModal`/`NodeEditModal`). **Behaviour and data flow stay; only
> appearance changes.**

# Scope

Restyle the goal-map's **appearance** to old-focal, on the existing graph + APIs:

- **`FocalNode` (node cards)** → old-focal `PyramidNode`/`GoalNode` look: border weight, the
  per-level **size/padding hierarchy** (base nodes larger than projects larger than activities), the
  exact branch/pillar **wash colours**, the **priority strip** (left colour bar: high/med/low) on
  project/activity nodes, the **selected** ring/elevation, shadow, and the on-card "+ child" buttons
  (already present — match styling). Icon + label already render.
- **`FloatingEdge`** → old-focal edge look: **dashed** style for product edges, branch/pillar edge
  colours, arrowhead size.
- **Page chrome** → old-focal goal-map header + in-canvas controls, consistent with the merged shell
  (title/subtitle/AI button via the shell's `PageHeader`; the Add/Undo/Redo/Auto-arrange controls
  restyled to old-focal).
- Light **and** dark parity; i18next `ru` + `en` (reuse existing keys / old-focal copy).

Exact pixel specs (colours, paddings, strip colours, ring, edge dims) are **pinned at the design
gate (gate 3)** by reading `PyramidNode.tsx`/`GoalNode.tsx` and comparing against the live old-focal
screenshot to a stated tolerance.

# Out of scope

- **Behaviour / interaction changes** — manual edge drawing, node **resize** handles, drag-to-
  **reparent** UI, and full create/delete/edit **undo** are old-focal behaviours the new app omits by
  design; they are not visual and are **not** added here (presentation parity only). If wanted, each
  is separate behaviour work (some need no backend; flag at design gate).
- **Goals *Kanban*** — old-focal's Goals page is the mind-map; there is no old-focal kanban (that was
  a mockup-only concept). Not in scope.
- **Any server / API / schema / contract change.** Frontend-only over existing endpoints; a genuinely
  missing backend field is a separate flagged handoff, never faked.
- Other left-nav pages (their own slices).

# Acceptance criteria

- [ ] The goal-map (nodes, edges, chrome) matches `apps/old-focal` by screenshot in **light and
      dark** — node size-hierarchy, wash colours, priority strip, selected state, dashed product
      edges, header/controls.
- [ ] Behaviour unchanged: create/edit/move/undo-redo/auto-arrange still work on the real
      `/api/mindmap/init` + project/activity endpoints; existing goals tests
      (`graph.test.ts`, `layout.test.ts`, `history.test.ts`, dialog tests) stay green; new visual
      logic (e.g. priority→strip colour) has its own unit test.
- [ ] Surgical diff confined to `features/goals/*` (+ any shared primitive it must add); **no**
      server/API change; no hardcoded strings (i18next `ru` + `en`).

# Verification commands

```sh
# from the pipeline root (the goals worktree is the build target)
cd .worktrees/focal-redesign-goals/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```
