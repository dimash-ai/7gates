# Design: focal-goals-mindmap-v2 (Goals map — layout & connections redesign)

3-gate flow. Seeded by the explore-gate findings `.ai/notes/focal-goals-mindmap.md` (Opus+GPT
consensus + the user's interaction decision). Branch `feature/focal-goals-mindmap-v2` (worktree
`superapp/.worktrees/focal-goals-mindmap-v2`) → base `feature/focal-migration`. **Frontend-only.**

## Problem & decision

The Goals map reads poorly — соединения блоков и распределение элементов. Root causes (all
verified in code): every edge attaches at the *centre* of one of a node's four sides, side chosen
by live pointer geometry, so a parent's N edges fan out of one pixel and flip sides mid-drag
(`features/goals/FloatingEdge.tsx:37-57`); the layout packs subtrees as whole bounding intervals
(no contour interleaving) in one direction only (`layout.ts:117-148`); the first layout runs
before React Flow measures nodes, so widths are label-length guesses (`GoalsPage.tsx:275-289`,
`layout.ts:88-102`); and persisted per-edge styles/handles (`focal.mindmap_edges`, ETL'd from
legacy where old-focal applied them via `applyEdgeStylesFromDb`, old `MindMap.tsx:1049`) are never
applied — **the init payload already returns them** (`InitRead.edges`,
`server/app/schemas/mindmap.py:97-101`) **and `buildGraph` ignores the field**, as its docstring
admits (`graph.ts:179-184`).

**Decision — keep @xyflow/react, replace the two weak layers in place** (explore-gate consensus of
both models): (1) swap the hand-rolled packing for **d3-flextree** (van der Ploeg non-layered tidy
tree, O(n), variable node sizes — the algorithm behind markmap) driven by a domain-derived parent
map, re-run once after real measurement; add a balanced two-sided **MAP mode** beside TB/LR;
(2) make edges **hierarchy-aware and deterministic** — sides derived from the layout (with a
geometric fallback + hysteresis for hand-placed nodes), source anchors *distributed* along the
parent's side, and persisted `mindmap_edges` overrides finally applied. Interaction model is the
user's decision from the explore gate: **default structure on open, free repositioning persists
across sessions (keep the pin/PATCH model), and a newly created node appears locally next to its
parent — never a global re-arrange.**

**Rejected:** replacing the canvas with a mindmap engine (mind-elixir / simple-mind-map) — forfeits
the merged React node cards, undo/redo, reparent DnD, dialogs and tests for a look achievable in
two files; elkjs/dagre — layered flowchart layouts, heavy (elkjs ~1.4 MB) and not mindmap-shaped;
strict auto-layout-only defaults (Miro/XMind model) — explicitly rejected by the user in favour of
persistent manual positions; any backend change — the position PATCHes and the `mindmap_edges`
CRUD already exist.

## Assumptions & scope

- **[confirmed — code]** Pin model: saved positions win, unpinned subtrees anchor to the nearest
  pinned ancestor by delta (`layout.ts:179-196`); auto-arrange persists every laid position
  (`GoalsPage.tsx:477-486`). Both behaviours are kept (user decision).
- **[confirmed — code]** `buildGraph` knows every node's parent as it links edges (`graph.ts:291,
  308`) → it can export a parent map; the layout no longer needs the BFS-over-rendered-edges hack.
- **[confirmed — code]** The init payload **already carries the edge overrides** —
  `InitRead.edges` (`server/app/schemas/mindmap.py:97-101`) with `source_handle`/`target_handle`/
  `edge_type`/`stroke_*`/`has_arrow` (`server/app/models/mindmap.py:30-47`) — and the client
  ignores the field. Applying it is a pure client-side merge onto the built edges, keyed by edge
  id: **no new request, no new endpoint**. Null override fields keep the built value — the legacy
  semantics (`applyEdgeStylesFromDb`, old `MindMap.tsx:1058-1070`, explicitly preserves the built
  dash when the row's dasharray is unset, so product/activity edges keep their identity dash under
  colour-only overrides; the legacy data model has no "reset to solid" state). (The standalone
  CRUD lives at `/api/mindmap-edges`; its write path / editor UI stays out of scope.)
- **[confirmed — repo]** Old-focal has no collapse/expand and no layout algorithm — both out of
  scope here (collapse = separate follow-up slice; the layout must simply take a node subset so it
  lands cheaply later).
- **[unverified — verify at build]** `d3-flextree` ships no TS types → add a ~10-line ambient
  declaration (strict TS). If its API surprises under TS 6, `entitree-flex` (MIT) is the drop-in
  fallback — same algorithm family.
- **[unverified — verify at build]** POST `/api/projects` / `/api/activities` return the created
  row (REST convention; the client currently discards the body). Slice 4 prefers the returned id
  (slot computed and persisted *before* the refetch — no flash). **When the body carries no id,
  the flow still places locally via an id-diff:** snapshot the parent's child ids before the POST,
  refetch, and the created id is the one new entity under that parent; then compute the slot,
  apply it locally and persist it (one-frame flash at the computed slot accepted). Only when the
  diff is ambiguous (>1 new id under that parent — e.g. a concurrent editor on a shared calendar)
  does the node keep the computed layout slot (degraded, no data loss) — so the local-placement
  criterion holds on both response shapes.
- **[unverified — verify at build]** `useNodesInitialized()` (xyflow v12) fires once per mount
  after measurement; guard the re-layout to run once per payload.
- **Out of scope:** collapse/expand; an edge-style *editor* UI (write path — the read path proves
  the pipe; editing is its own parity slice); rendering legacy *user-drawn* custom edges
  (`mindmap_edges` rows matching no built structural edge are ignored by the merge); tapered
  XMind-style branches (pure cosmetics); backend changes; touching reparent/schedule/undo flows
  beyond what the edge/layout swap forces.
- **Open questions:** None blocking.

## Success criteria

- [ ] With no saved positions, TB auto-layout produces **zero overlapping node rects** (≥ the
      sibling gap apart) for a fixture tree with strongly varying card sizes — pure test.
- [ ] A parent's sibling edges leave from **distinct, monotonically ordered anchor points** along
      its side (no shared-pixel fan), and no two sibling edge paths cross — pure test over anchors.
- [ ] Edge sides are **stable under drag**: the stamped side holds for a child moved anywhere on
      the stamped side's half-plane (extended 24 px past the parent's opposite face); only beyond
      that fixed boundary does the geometric side take over, and the boundary itself never moves
      during a drag (no oscillation) — pure test of the side-resolution function.
- [ ] Persisted edge overrides render from the existing payload: `edge_type`→path kind, stroke
      fields→style, `has_arrow`→marker, saved handles→anchor sides; an override matching no built
      edge is ignored (component test with `init.edges` mocked in the payload).
- [ ] MAP mode splits the pillars across both sides of the centred spine, each arm laid out
      per-side with no cross-arm overlap; TB/LR remain available; the dropdown gains a third,
      localized (ru+en) option — pure layout test + i18n keys present.
- [ ] Measurement pass: after nodes report measured sizes, unpinned nodes re-layout once (no
      persist, no loop); pinned nodes never move — component-level test.
- [ ] Creating a **project (under its pillar), a product (under its project) or an activity
      (under its product)** places the new node **adjacent to its parent node** (within one slot
      gap on the parent's open side), never overlapping an existing rect, and persists that
      position so it survives reload; other nodes do not move — pure slot test + create-flow
      tests covering all three paths.
- [ ] All prior behaviours hold: saved positions honoured exactly, drag-to-reparent, refile,
      undo/redo, `!canEdit` gating (existing tests stay green).
- [ ] `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green; diff confined to
      `features/goals/*`, `api/mindmap.ts`, the two locale files, `package.json`(+lock), and a
      type declaration.

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| 1 | **Layout core** — `buildGraph` exports `parents: Map<childId,parentId>`; rewrite `layoutTree` on d3-flextree (nodeSize from measured/estimate, spacing fn), signature **extended with the `parents` map** (both call sites updated in-slice) + pin/delta pass kept; one-shot re-layout after `useNodesInitialized` | `graph.ts`, `layout.ts`, `GoalsPage.tsx`, `package.json`+lock, `d3-flextree.d.ts`, `layout.test.ts` | subtree interleaving regressing to overlap; re-layout loop after measurement | variable-size fixture → disjoint rects with gaps; pinned map honoured exactly; measurement pass runs once and moves only unpinned nodes |
| 2 | **MAP mode** — two-sided balanced arm split (pillars alternate sides by subtree extent, greedy-balanced), per-arm flextree with mirrored x, spine centred; third dropdown item + ru/en keys | `layout.ts`, `GoalsPage.tsx`, `i18n/locales/*`, `layout.test.ts` | arms colliding through the centre; unbalanced sides | fixture → left/right arms disjoint from spine and each other; balance within one pillar-subtree extent; keys exist in both locales |
| 3 | **Edges v2** — layout stamps `data.side` per node (see the stamping rule in Architecture); `FloatingEdge` resolves sides by the three-step precedence (persisted handle → stamped side within its biased boundary → geometric beyond it), distributes source anchors along the side toward each child, keeps bezier/straight/step kinds; `applyEdgeOverrides(edges, init.edges)` merges the overrides **already in the init payload** (no new request) in the `buildGraph` path, ignoring rows matching no built edge; update the stale docstring | `FloatingEdge.tsx`, `layout.ts`, `graph.ts`, `FloatingEdge.test.ts` | side flip mid-drag; anchors escaping the side; overrides misapplied to base spine | side-resolution: stamped side inside the band, geometric beyond, boundary fixed during drag; anchor distribution monotone + clamped; override mapping (type/stroke/arrow/handles) applied; unmatched override ignored; base spine unchanged without overrides |
| 4 | **Local create placement — all three create paths**: project-under-pillar (`submitCreateProject`), product-under-project and activity-under-product (`createProductMut`/`createActivityMut`). Create fns return the created id (read the POST body); pure `newNodeSlot(nodes, parentNodeId, direction)` (next free slot on the parent's open side, collision-swept against all rects); each flow slots + persists via the existing move PATCH before invalidate, **or, on an id-less body, via the id-diff fallback after refetch** (see Assumptions) | `api/mindmap.ts`, `graph.ts` (slot helper), `GoalsPage.tsx`, `graph.test.ts` / page test | slot overlapping a pinned neighbour; failed PATCH leaving a phantom; ambiguous id-diff; the pillar path silently skipped | childless / N-children / crowded-neighbour fixtures → adjacent, non-overlapping slot; **each of the three creates** places next to its parent (pillar / project / product card); id-diff path slots the one new child (ambiguous → computed slot); PATCH failure falls back to computed layout without data loss |

Slices ship **sequentially** — each leaves the tree green and is shippable once its predecessors
have landed: 2, 3 and 4 all build on 1 (3 needs its `data.side` stamping, 4 its geometry
accessors); none are parallel-independent of 1.

## Architecture & contracts

| entity / interface | change | notes |
|--------------------|--------|-------|
| `graph.ts` `buildGraph` | modify | additionally returns `parents: Map<string,string>` (child → parent, incl. base spine); applies `applyEdgeOverrides(init.edges)` (slice 3) — the overrides already arrive in the init payload, keyed by edge id; unmatched rows ignored |
| `layout.ts` `layoutTree(nodes, edges, direction, pinned, parents)` | rewrite internals | flextree replaces `place()`; `direction: 'TB'\|'LR'\|'MAP'`; keeps: measured-size accessors, pin/delta anchoring, top-left conversion. **Side stamping:** sets `data.side: 'top'\|'bottom'\|'left'\|'right'` — for an *unpinned* node the tree side (its arm/direction); for a *pinned* node the side derived from its final position relative to its parent, so a persisted stray stamps correctly on every load. Stamps happen on every layout run (load, measurement pass, auto-arrange) and never during a drag. Takes the node *subset* to lay out (collapse-ready) |
| `d3-flextree` dep | add | ~4 kB, WTFPL, stable (markmap's layout engine); ambient `.d.ts` for strict TS; fallback `entitree-flex` (MIT) if types fight |
| `api/mindmap.ts` create fns | modify return | `createProject/createProduct/createActivity` return the created entity id (read the response body instead of discarding); no other API change — edge overrides ride the existing init call |
| `FloatingEdge.tsx` | rewrite anchor logic | **three-step side precedence, stateless:** (1) a persisted `mindmap_edges` handle always wins; (2) else the stamped `data.side` holds **while the child's centre stays on that side's half-plane, extended 24 px past the parent's opposite face** — the stamp doesn't change mid-drag, so this boundary is a fixed line and cannot oscillate; (3) only beyond that boundary (a child genuinely dragged to the other side, before the next layout run re-stamps it) does the geometric side (the one facing the child) apply. This is what makes step 3 reachable: stamps update only on layout runs, drags happen between them. Source anchor slides along the chosen side toward the child's cross position, clamped inside `[pad, len-pad]`; path kinds unchanged (bezier default) |
| `GoalsPage.tsx` | modify (small) | measurement one-shot re-layout; MAP dropdown item; the three create flows (project / product / activity): slot → persist → invalidate. Drag/reparent/undo handlers untouched |
| backend | **none** | endpoints + table already exist |

Data model: no new persistent state — positions keep using project/activity columns +
`mindmap_nodes`; edge styles keep `mindmap_edges` (read-only here).

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — first open, no saved positions | `/goals` load | layout effect + measurement pass | flextree TB structure, sides stamped, edges fan cleanly |
| happy — mixed pinned/unpinned | load with saved x/y | pin/delta pass (unchanged) | saved spots exact; unpinned relatives follow |
| happy — create (project / product / activity) | pillar “+ Project” or on-card “+” confirm | create → `newNodeSlot` → move PATCH → invalidate | node appears beside its parent (pillar / project / product card), persisted; nothing else moves |
| happy — MAP arrange | dropdown | `reArrange('MAP')` | two-sided arms, positions persisted (existing reArrange path) |
| override matches no built edge | legacy user-drawn link / stale row in `init.edges` | `applyEdgeOverrides` merge | row ignored; structural edges keep their defaults |
| create returns no id | empty POST body | id-diff fallback (create flow) | snapshot parent's child ids pre-POST → refetch → the one new id under that parent gets the slot, applied locally + persisted (one-frame flash accepted); >1 new id (concurrent editor) → keep computed slot, no persist |
| slot PATCH fails | move PATCH error | existing `onError: invalidate` | refetch truth; node shows at computed slot; no phantom position |
| measurement loop risk | nodes re-measure after re-layout | one-shot guard keyed by payload | second pass never fires for the same payload |
| dragged stray child | child dragged across its parent | side-resolution boundary (FloatingEdge) | stamped side holds within its half-plane + 24 px; one flip past the fixed boundary; next layout run re-stamps from the pinned position so stamp and geometry re-converge |

## Test strategy, security & rollback

- **Test strategy:** the risky logic is pure and unit-tested — flextree adapter (disjoint rects,
  variable sizes, pinned honoured, subset/collapse-ready), arm balancing (MAP), anchor
  distribution + hysteresis, `newNodeSlot` collisions. Component tests: FloatingEdge override
  mapping; GoalsPage measurement one-shot + create-places-locally (mocked queries, as existing
  page tests do). Existing goals tests (drag, reparent, refile, undo, rename, resize) must stay
  green untouched — they are the regression net. "Verified" = all suites + lint + typecheck +
  build green in the worktree.
- **Security:** no new endpoints, requests or auth surface — edge overrides arrive in the
  already-tenant-scoped init payload; `canEdit` gating unchanged. Persisted stroke values flow
  only into React style-object properties (no `dangerouslySetInnerHTML`, no CSS string concat) —
  no injection surface. No secrets, no rate-limit change.
- **Rollback:** frontend-only — revert the slice commits; no migration, no data-shape change
  (reading `mindmap_edges` is side-effect-free; positions written by the create flow are ordinary
  moves, same as a user drag).
