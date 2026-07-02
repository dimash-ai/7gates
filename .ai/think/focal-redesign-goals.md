# Problem

The new Focal **Goals page** ("Карта целей") must reach **exact visual parity with `apps/old-focal`**
— the binding contract set by the `focal-redesign-pages` epic (think APPROVED 9.4). The decisive,
de-risking fact: the new app's Goals feature is **already a functional @xyflow/react (12.11)
mind-map** that mirrors old-focal's structure — same 7-base-node pyramid (life-goal → mission →
life-standard → 4 pillars), projects / products / activities from `/api/mindmap/init`, `FocalNode`
cards, `FloatingEdge`, tidy auto-layout, undo/redo of moves, drag-to-move persisted via
`moveProject`/`moveActivity`/`moveNode`, and the create/edit modal set (`GoalsPage.tsx:52-518`). So
despite old-focal's `MindMap.tsx` being ~230 KB, the **heavy logic is already ported** — this slice
is a **bounded visual re-skin of working UI**, not a rebuild. The job is to make the nodes, edges,
and page chrome *look* exactly like old-focal, on the existing graph + APIs, with behaviour and data
flow unchanged.

The risk to manage is the usual re-skin trap (and the epic reviewer's Should-Consider): "exact" must
be pinned to concrete specs — old-focal's per-node-type sizing, wash colours, the priority strip, the
selected state, and edge styling — read from `PyramidNode.tsx`/`GoalNode.tsx` and checked against the
live screenshot to a stated tolerance, not hand-waved. And the line between **visual** (in scope) and
**behavioural** (out of scope) must be explicit, because old-focal's goal-map carries interactions
the new app deliberately omits (manual edges, resize, drag-to-reparent, full undo).

# Assumptions

- **[confirmed — user/epic]** Binding contract = exact old-focal visual parity; this slice inherits
  the epic's rules — re-skin not rebuild, reproduce not copy (React 19 / Tailwind 4 / shadcn over the
  shell tokens already merged at `afaaeba`), presentation parity with behaviour preserved.
- **[confirmed — inspection, `GoalsPage.tsx`]** The new Goals feature is functional on real APIs:
  `getMindmapInit` (`/api/mindmap/init`), `moveProject`/`moveActivity`/`moveNode` (PATCH),
  `createProject`/`createProduct`/`createActivity`, and `ProjectEditModal`/`ActivityEditModal`/
  `NodeEditModal`; @xyflow/react 12.11; custom `pyramid` node (`FocalNode`) + `floating` edge
  (`FloatingEdge`); `layoutTree` auto-layout (TB/LR); move undo/redo (`history.ts`). Drag persists
  with optimistic cache update + snap-back-on-error.
- **[confirmed — inspection]** Design source = old-focal `pages/Goals.tsx` (thin header: SidebarToggle
  + title/subtitle + AI button + PageToolbar) + `components/MindMap/*` — `PyramidNode.tsx` (~30 KB:
  base + project/activity node visuals incl. priority strip, selected ring, size tiers, on-card add
  buttons), `GoalNode.tsx`, `TaskNode.tsx`, `FloatingEdge.tsx`, `MindMap.tsx` (orchestrator). The
  "Карта целей" screenshot is this app.
- **[confirmed — Explore comparison]** The visual delta is **bounded** to: (1) `FocalNode` card
  styling — border weight, per-level padding/size tiers, exact wash colours, **priority strip**,
  **selected** ring/elevation, shadow; (2) `FloatingEdge` — **dashed** product edges, edge colours,
  arrowhead size; (3) page chrome — header + in-canvas controls. Node hierarchy, layout, edges-from-
  hierarchy, dialogs, and CRUD already match.
- **[confirmed — Explore]** **No backend blocker.** `parentProjectId` is PATCH-able (`api/mindmap.ts`),
  and every node/colour/position field the visuals need is already in the `/api/mindmap/init` payload
  (projects carry `priority`, `color`, `isWorkTime`, `sphere`, `icon`). Nothing is faked.
- **[confirmed — both package.json]** Stack-compatible: @xyflow 12.10→12.11 (patch), React 18→19,
  Tailwind 3→4, lucide 0.453→1.17 — all class/API-compatible for this page; no Tailwind-3 config is
  carried over (epic rule).
- **[unverified — pin at the design gate (gate 3)]** the EXACT specs: pyramid wash colours (e.g. the
  meaning-green / provision-blue tints), per-node-type padding + font sizes, priority-strip colours
  (high/med/low), selected ring spec, edge dash array + arrowhead dims, and whether old-focal's header
  + PageToolbar actions differ from the new in-canvas `Panel`. These are read from
  `PyramidNode.tsx`/`GoalNode.tsx` + screenshot-compared at gate 3, not guessed here.

# Options considered

**Fork 1 — scope shape:**

| # | Option | Pros | Cons |
|---|--------|------|------|
| **A — one re-skin slice (chosen)** | Restyle `FocalNode` + `FloatingEdge` + page chrome in one focused slice over the existing graph/APIs. | The delta is bounded and the files are tightly coupled (`FocalNode` ↔ wash colours ↔ edges ↔ layout); one coherent PR leaves the page whole; matches the user's request and the Explore assessment. | The node-visual work (priority strip, size tiers, selected ring, exact colours) is non-trivial — must be done carefully, not "a CSS tweak." |
| **B — decompose (node-visuals / edge / chrome sub-slices)** | Smaller PRs. | Sub-tasks are tiny and interdependent; a slice each = overhead > value and leaves the page half-skinned between merges. Rejected (mirrors why analytics *was* split — there each section was large + independently shippable; here they are not). |

**Fork 2 — page chrome:** keep the new in-canvas top-left `Panel` (Add/Undo/Redo/Auto-arrange) vs
reproduce old-focal's header + `PageToolbar`. **Lean:** adopt old-focal's page **header** (title /
subtitle / AI button) via the shell's `PageHeader` (already the slice-0 pattern) and keep the
in-canvas controls, restyled to old-focal; the exact control placement is settled at the design gate
against the screenshot.

# Recommendation

**Option A — one slice.** Re-skin `features/goals/FocalNode.tsx` and `FloatingEdge.tsx` (plus the
`GoalsPage` header/controls chrome) to old-focal's exact goal-map look, on the existing @xyflow graph
and mind-map APIs, behaviour unchanged. Pin the exact visual specs at the **design gate (gate 3)** by
reading `PyramidNode.tsx`/`GoalNode.tsx` and screenshot-comparing to old-focal in light + dark to a
stated tolerance (closing the epic reviewer's Should-Consider). Keep the diff surgical to
`features/goals/*` (+ any shared primitive that must be added), with a unit test for the new visual
logic (e.g. priority → strip colour) and the existing goals tests staying green.

# Out of scope

- **Behaviour / interaction parity** — manual edge drawing, node **resize**, drag-to-**reparent** UI,
  and full create/delete/edit **undo** are old-focal behaviours the new app omits by design; not
  visual, **not** added here. If the product wants them, each is separate behaviour work (flagged at
  the design gate; most need no backend — `parentProjectId` is already PATCH-able).
- **Goals *Kanban*** — no such page exists in old-focal (mockup-only concept). Not in scope.
- **Any server / API / schema / contract change.** Frontend-only over existing endpoints.
- Other left-nav pages.

# Open questions

- **Exact specs** (pyramid wash colours, node size tiers, priority-strip colours, selected ring, edge
  dash/arrow dims) — pinned at the design gate from `PyramidNode.tsx`/`GoalNode.tsx` + screenshot.
- **Chrome ownership** — is the page header already satisfied by the merged shell slice, so this slice
  only restyles the in-canvas controls? Confirm at the design gate.
- **Behaviour confirmation** — confirm the user wants visual-only here (the epic says so); if they
  also want drag-to-reparent / resize, that is a separate slice, not folded in silently.
- **Screenshot tolerance** — agree a fidelity bar (e.g. spacing within a few px, exact token colours)
  at the design gate so gate-4/5 reviewers have an objective standard.

# Success criteria

- [ ] One slice: `FocalNode` + `FloatingEdge` + chrome restyled to old-focal; the goal-map matches
      old-focal by screenshot in **light and dark** (node tiers, wash colours, priority strip,
      selected state, dashed product edges, header/controls).
- [ ] Behaviour preserved: create/edit/move/undo-redo/auto-arrange still work on real APIs; existing
      goals tests stay green; new visual logic has a unit test.
- [ ] `cd .worktrees/focal-redesign-goals/apps/focal/client && pnpm lint && pnpm typecheck &&
      pnpm test:run && pnpm build` all green.
- [ ] Surgical diff in `features/goals/*` (+ any added shared primitive); no server/API change; no
      hardcoded strings (i18next `ru` + `en`); exact specs traced to old-focal at the design gate.
