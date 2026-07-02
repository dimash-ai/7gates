# Findings: focal-goals-mindmap

> Output of the **explore gate** (`/gate-explore focal-goals-mindmap`). Two independent takes —
> Opus and GPT — synthesized. Small and findings-first; raw per-model answers live in
> `.ai/scratch/` (gitignored). Not scored. Date: 2026-07-02.

Topic: the Goals map (mindmap) in `superapp/apps/focal/client/src/features/goals` reads poorly —
соединения блоков и распределение элементов. Which patterns from Miro / MindMeister / XMind /
MindMup (and which open-source solutions) should we adopt?

## Questions

1. What in the current implementation causes the bad connections + distribution?
2. What layout/connection patterns do Miro, MindMeister, XMind, MindMup use that we should adopt?
3. Which open-source libraries/algorithms fit our stack (React 19 + @xyflow/react 12 + strict TS)?
4. Improve in place, adopt a library, or replace the engine?

## Consensus

> Both models agree. State once, mark confidence, cite evidence.

**Q1 — root causes (confidence: High, both read the same code):**

- **Edges are geometry-driven, not hierarchy-driven.** Every edge attaches at the *centre* of one
  of the node's four sides, side chosen by the centre→target direction — so all N children fan out
  of one pixel, and the side *flips* while dragging. Generic flowchart beziers
  (`getBezierPath`/`getSmoothStepPath`) instead of mindmap connectors. Evidence:
  `features/goals/FloatingEdge.tsx:37-57,85-91`.
- **Layout is a one-sided rooted tidy tree, not a mindmap.** BFS from `life-goal`, TB or LR only —
  no balanced two-sided "map" mode around the root. Subtrees are packed as whole bounding
  intervals (no Reingold–Tilford contour interleaving), with fixed `SIBLING_GAP`/`ROW_PITCH`, so
  sparse branches spread arbitrarily wide. Evidence: `features/goals/layout.ts:5,53-77,117-148`.
- **First layout runs before React Flow measures nodes.** The `useEffect` lays out on payload
  change; `node.measured` is empty on first paint so widths fall back to label-length estimates →
  uneven spacing with variable-height cards. Evidence: `features/goals/GoalsPage.tsx:275-289`,
  `features/goals/layout.ts:88-102`.
- **Pinned free positions fight auto-layout.** User-dragged nodes pin (PATCH x/y), unpinned
  subtrees shift by inherited delta — after a few drags the map is a mix of manual + computed
  placement that only an explicit auto-arrange resets. Evidence: `features/goals/layout.ts:179-196`,
  `GoalsPage.tsx:278-286`. (Old-focal was 100% manual x/y persisted to `mindmap_nodes` — no layout
  algorithm at all, no collapse: `apps/old-focal/.../MindMap/MindMap.tsx` (5152 lines, zero
  `collaps*`/`dagre`/`d3` hits).)
- **Persisted edge styles aren't rehydrated.** `buildGraph`'s docstring: payload node overrides and
  edge styles "are not applied yet — a faithful read-only skeleton, hardened in a follow-up";
  `FloatingEdge` honours a runtime `data.edgeType` but the payload styles don't flow in on reload.
  Evidence: `features/goals/graph.ts:179-184`. *(GPT-found; Opus verified.)*

**Q2 — what the reference tools converge on (confidence: High — vendor docs fetched by Opus; GPT
independently derived the same list offline):**

- **Auto-layout is the default; manual placement is the exception.** Miro: auto-layout ON by
  default, per-branch toggle, "Layout nodes" action ([help.miro.com Mind map](https://help.miro.com/hc/en-us/articles/360017730753-Mind-map)).
  MindMeister: "auto-align" toggle; free positioning only when off ([support.mindmeister.com](https://support.mindmeister.com/hc/en-us/articles/360017549439-Customize-Your-Map-s-Layout)).
  XMind: structure owns positions, no free placement ([xmind.com/structure](https://xmind.com/structure)).
- **Balanced two-sided "map" structure** around the root (MindMeister: first ~5 branches right,
  rest left), plus org-chart (down) and list/logic (right) variants; XMind allows a **different
  structure per branch**.
- **Deterministic, side-aware connectors:** right-side branches connect parent-right → child-left,
  mirrored on the left; curved/rounded, colour-coded per branch, no arrowheads; siblings fan
  without crossing (XMind adds tapered organic lines as polish).
- **Drag = reorder/reparent with live preview**, not free positioning; **collapse/expand per
  branch** is table stakes in all four (absent in both our old and new Focal).

**Q3 — viable open-source options (confidence: High on facts — licenses/status web-verified by
Opus 2026-07-02; GPT flagged the same set from memory and asked for exactly this verification):**

| option | what it gives | license / status |
|---|---|---|
| **d3-flextree** | variable-node-size tidy tree (van der Ploeg 2013, O(n)) — drop-in replacement for our hand-rolled packing; the layout engine behind markmap | WTFPL; stable/finished since 2018 ([github.com/Klortho/d3-flextree](https://github.com/Klortho/d3-flextree)) |
| **entitree-flex** | same idea, MIT, used in React Flow's own variable-size tree example | MIT; small |
| **dagre / elkjs** | layered DAG layouts; org-chart-ish, not mindmap-y; elkjs heavy (~1.4 MB, worker) | MIT / EPL-2.0 |
| **mind-elixir** | full mindmap *engine* (balanced L/R, drag-reorder, collapse, undo, touch) | MIT; active (v5.13, Jun 2026, 3.1k★) |
| **simple-mind-map** | richest structures (mindmap/logic/org/fishbone/timeline) | MIT; core lib in **low-maintenance mode** |
| **jsMind** | simpler engine | BSD-3 |
| **markmap** | render-only markdown→mindmap; precedent that flextree ⇒ classic mindmap look | MIT |
| **mapjs (MindMup)** | MindMup's actual engine — reference reading only | MIT; **archived 2019** |

React Flow itself ships **no** mindmap layout (official mindmap tutorial is manual positioning;
the layouting guide points to d3-flextree/entitree-flex for variable-size trees:
[reactflow.dev/learn/layouting](https://reactflow.dev/learn/layouting/layouting)).

**Q4 — recommendation (confidence: High, both models independently identical):**

**Keep @xyflow/react; do NOT swap engines.** The goals feature has deep merged investment (React
node cards `FocalNode.tsx`, edge-style editor, undo/redo `history.ts`, reparent DnD + dialogs,
tests); mind-elixir/simple-mind-map would force rebuilding all of it inside a foreign renderer.
Fix the two weak layers in place:

1. **Layout:** replace the hand-rolled packing in `layout.ts` with a variable-node-size tidy tree
   — **d3-flextree** (or entitree-flex if MIT is preferred) — fed by real `node.measured` sizes
   (re-run after measurement, don't persist), and add a **balanced two-sided "map" mode**
   (split root's children right/left, flextree per side, mirror x) alongside TB/LR as a structure
   switcher. Derive the tree from the domain payload (`parentType`/`parentProjectId`), not BFS
   over rendered edges *(GPT-originated; Opus concurs)*.
2. **Edges:** side-aware deterministic anchors from the layout (parent side = child's layout side,
   never flips on drag), horizontal-tangent mindmap beziers that fan siblings without crossing,
   distributed along the parent side; keep the edge-style editor as per-edge override and start
   rehydrating persisted styles in `buildGraph`. Tapered XMind-style branches = optional polish.

## Divergence

> They disagreed or emphasized different things. Both views, then a decision flag for the user.

- **Default interaction mode: structured mindmap vs freeform whiteboard.** — **RESOLVED by the
  user, 2026-07-02.**
  - Opus: flip the default to the reference-tool model — auto-layout ON, drag = reorder/reparent,
    free positioning becomes an explicit per-map/branch toggle.
  - GPT: improve layout quality but keep re-layout non-destructive; if the product wants freeform
    whiteboard behaviour, auto-layout should stay opt-in.
  - **User decision (hybrid, closer to GPT's shape with Opus's default-quality bar):**
    1. the map opens in a **good default structure** (auto-layout for anything the user hasn't
       touched);
    2. the user may freely reposition nodes, and those positions are **persistent across
       sessions** (keep the PATCH x/y model);
    3. **adding a new element places it locally, next to its parent block** — never a global
       re-layout that would destroy the user's arrangement.
  - Consequences: the pin/delta machinery survives; the flextree layout becomes the *default
    placement* for unpinned nodes; a "new node" needs a local-slot algorithm (a free slot on the
    parent's side, collision-avoided) instead of relying on refetch+re-layout; auto-arrange stays
    as the explicit reset.

## Open

> Neither resolved it — name exactly what's missing to close it.

- **Visual confirmation on real data** — neither model saw the rendered map. To close: open the
  goals page with seeded data (dev.sh, demo user `a8601794`) and screenshot before/after any
  prototype.
- **Edge-style rehydration audit** — does the merged edge-style editor's output survive reload?
  `buildGraph` says payload styles aren't applied (`graph.ts:179-184`). To close: trace one styled
  edge through save→reload, then fix in the same slice.
- **Collapse/expand scope** — all four references have it; both Focals lack it. New capability
  (not parity). To close: user decides whether it enters this redesign slice or a follow-up.
- **New-node local placement** — the decided UX ("new element appears next to its parent") needs a
  concrete slot algorithm (which side, how collisions with pinned neighbours resolve, whether the
  computed slot is persisted immediately). To close: specify in the design gate.
- **Edge sides for hand-placed nodes** — deterministic tree-side anchors are trivial for laid-out
  nodes; for freely dragged ones the side needs a stable rule (tree side with geometric fallback +
  hysteresis, no mid-drag flips). To close: specify in the design gate.

## Next

Decision made (see Divergence) → seeds `/gate-design focal-goals-mindmap-v2` (3-gate): flextree
default layout + two-sided map mode, persistent manual positions kept, local placement of new
nodes near their parent, deterministic mindmap edges + edge-style rehydration fix. Collapse/expand
in-or-out is the remaining scope call.
