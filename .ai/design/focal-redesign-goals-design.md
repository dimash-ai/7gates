# Design — focal-redesign-goals

Visual re-skin of the existing Goals mind-map to **exact old-focal parity**, on the new stack, over
the existing graph + APIs. Behaviour, data flow, layout, history, dialogs, and CRUD are unchanged
(see [`../think/focal-redesign-goals.md`](../think/focal-redesign-goals.md),
[`../plans/focal-redesign-goals-plan.md`](../plans/focal-redesign-goals-plan.md)). Every spec below
is traced to old-focal source so the build/review gates have an objective bar.

Binding source: `apps/old-focal/client/src/components/MindMap/{PyramidNode.tsx,FloatingEdge.tsx}` +
`pages/Goals.tsx`. Re-skinned files: `apps/focal/client/src/features/goals/{FocalNode.tsx,FloatingEdge.tsx,graph.ts,GoalsPage.tsx}` + `components/PageHeader.tsx` (one optional prop).

## 1. Node card — exact spec (`FocalNode.tsx`)

Current card (`FocalNode.tsx:20-29`): `rounded-[14px] bg-card px-3 py-2 shadow-sm`, `border:1.5px`,
`linear-gradient(0deg,${color}26,${color}26)`, `minWidth150 maxWidth280`. Target (PyramidNode.tsx):

| Property | old-focal (source) | Target for FocalNode |
|---|---|---|
| Border | `border-2` (PyramidNode.tsx:355) | `border-2` (2px), `borderColor: nodeColor` inline |
| Shadow | `shadow-lg` (:355) | `shadow-lg` |
| Container | `relative transition-[box-shadow,border-color] duration-150 overflow-hidden flex flex-col` (:355) | same (`relative overflow-hidden` is required so the priority strip clips) |
| Tier padding | top `px-5 py-4` · mid `px-4 py-3` · leaf `px-3 py-2` (:356) | same, by tier (below) |
| Tier min-width | top `180` · mid `160` · leaf `140` (:363); `minHeight 50` | same (inline `minWidth`/`minHeight`) |
| Icon size | top `h-6 w-6` · mid `h-5 w-5` · leaf `h-4 w-4` (:485) | same, by tier |
| Label size | top `text-base` · else `text-sm`, `font-medium` (:554) | same |
| Shape | products (non-activity) `rounded-none`; else `rounded-xl` (:349) | same (`rounded-xl` = 12px; replaces the current `rounded-[14px]`) |

**Tier mapping** (old-focal levels → new base-node ids in `graph.ts:48-88`):
- **top** = `life-goal`, `mission` (old `isTopLevel`, PyramidNode.tsx:305).
- **mid** = `life-standard`, `budget`, `economic-safety`, `society`, `life-spheres` (old `isMidLevel`
  was `life_standard|budget`; the 4 pillars are all the old "budget" tier — confirmed by the
  shared-level note PyramidNode.tsx:574 "«Сферы жизни»/«Общество» … тот же level").
- **leaf** = projects, products, activities.

Tier + shape are pure functions of node metadata → live in a new testable
`goalNodeVisuals.ts` (`tier(node) → 'top'|'mid'|'leaf'`, `cardShape(node) → 'rounded-none'|'rounded-xl'`).

## 2. Wash colour — light + dark (resolves Gate-2 Should-Consider #2)

old-focal (PyramidNode.tsx:333-343) mixes the node colour over the card background — light
`color-mix(in srgb, ${color} 15%, white 85%)`, dark `color-mix(in srgb, ${color} 20%, ${darkCardBg} 80%)`
— and detects dark via a `MutationObserver` (:201-210). We **drop the observer** (the plan's decision)
and reproduce the same result with CSS, generalised to the new 4-colour pillars:

- FocalNode sets `style={{ '--node-color': nodeColor }}` and class `goal-node`.
- In `apps/focal/client/src/index.css` add (scoped, the only shared-CSS addition):
  ```css
  .goal-node { background-color: color-mix(in srgb, var(--node-color) 15%, #fff); }
  .dark .goal-node { background-color: color-mix(in srgb, var(--node-color) 20%, hsl(var(--card))); }
  ```
  `--card` is an **HSL triplet** (`index.css:162` light `0 0% 98%`, `:243` dark `220 13% 11%`), so it
  must be wrapped as `hsl(var(--card))` to be a valid colour — a bare `var(--card)` would not resolve.
  This reproduces old-focal exactly: light mixes the node colour **15% over white** (PyramidNode.tsx:340
  `color-mix(... 15%, white 85%)`); dark mixes **20% over the dark card** (PyramidNode.tsx:339 `darkCardBg`
  = `hsl(220 13% 11%)` = `hsl(var(--card))` in dark). Base nodes use the same formula — a faithful
  generalisation of old-focal's fixed per-branch `bgColor` tints (PyramidNode.tsx:79,105 `#dcfce7`/
  `#dbeafe`, themselves ~15% mixes of the branch colour over white) to the new 4-colour pillars
  (documented as intentional, §8).
- Replaces the current `backgroundImage` gradient (FocalNode.tsx:27, which ignored dark mode).

## 3. Priority strip (`goalNodeVisuals.ts` + `FocalNode.tsx`)

old-focal (PyramidNode.tsx:322-373): a 1.5-wide left bar shown when `priority` is set **and** the node
is a project / product / activity.
- Colours (exact): `high #ef4444`, `medium #eab308`, `low #9ca3af` (:322-325).
- `priorityStripColor(priority) → hex | null` — `null` for missing/unknown (no strip; resolves
  failure mode `goals.visual.missingPriority`).
- Markup: `<div class="absolute left-0 top-0 bottom-0 w-1.5 pointer-events-none" style={{backgroundColor}}/>`
  (:368-373). Requires the card's `relative overflow-hidden`.
- Data: `buildGraph` propagates `priority` onto project + activity node data (already in the payload —
  `ProjectRead.priority`, `ActivityRead.priority`; verified at gate 2). Base nodes never show a strip.

## 4. Selected ring (resolves Gate-2 Should-Consider #3)

old-focal (PyramidNode.tsx:357,365): `ring-2 ring-offset-2 ring-offset-background scale-[1.02]` **plus**
an inline `boxShadow: 0 0 0 2px ${color}40, 0 4px 12px ${color}30`. On Tailwind 4 the `ringColor` style
key is unreliable, so **the inline `boxShadow` is the ring** (it already fully draws the 2px colour
ring + glow); we keep `scale-[1.02]` and drop reliance on the `ring-*` utilities + `ringColor`.
- The new graph is `elementsSelectable={false}` (GoalsPage.tsx:363), so xyflow never sets `selected`.
  `GoalsPage` already tracks the selected node in state (`selected`, :73) for the modal → pass
  `selected: selected?.id === node.id` into each node's `data` when building the render list, and
  `FocalNode` applies the boxShadow + scale when `data.selected`. No behaviour change (click still
  opens the same modal).

## 5. On-card add buttons + optional meta

- **Add buttons** already exist and fire the correct `GoalsContext` callbacks (FocalNode.tsx:39-66) —
  restyle only to old-focal's dashed muted button: `text-xs px-2 py-0.5 rounded-md border border-dashed
  border-current/30 text-muted-foreground hover:text-foreground hover:bg-white/50 dark:hover:bg-white/10`
  (PyramidNode.tsx:615). Callbacks/args unchanged.
- **Work/sphere pill** (PyramidNode.tsx:642-644) and **activity dates** (:649-655): render only when the
  metadata is present (`isWorkTime`/`sphere`; `startDate`/`endDate`), from i18n keys. `buildGraph` adds
  these visual-only fields (all in the payload). Absent → omitted (failure mode
  `goals.visual.missingOptionalMeta`). **Not** ported: inline label edit, resize handles, the
  details/help buttons, budget value rows — behavioural / out of scope (think §Out of scope).

## 6. Edge parity (`FloatingEdge.tsx` + `graph.ts`)

Two deltas — attachment geometry **and** per-kind stroke/marker styles (the current edges do NOT match
old-focal).

- **Geometry:** the new `FloatingEdge` attaches at **side-midpoints** (borderPoint, FloatingEdge.tsx:34-56,
  by its own comment); old-focal attaches at the **true geometric border intersection**
  (`getNodeIntersection`, old FloatingEdge.tsx:5-47) so diagonal edges meet the card corner-ward, not at
  the side centre. Replace `borderPoint` with old-focal's intersection math, keeping our typed
  `IntersectableNode` shape (no `any`), the `edgeType` straight/step/smoothstep/bezier support, and
  `useInternalNode`. Also render **`markerStart`** alongside `markerEnd` (FloatingEdge.tsx:84-86 passes
  only `markerEnd`) so base edges can be double-ended like old-focal.
- **Fallback size** for unmeasured nodes: source `280×100`, centre `150×50` (old FloatingEdge.tsx:8-9,52-53).
- **Per-kind styles in `graph.ts` (CHANGED — these did not match old-focal):** split the `floatingEdge`
  helper by edge kind to reproduce old-focal exactly:

  | kind | stroke | width | dash | markers | source |
  |---|---|---|---|---|---|
  | **base** (fixed spine: life-goal/mission/standard ↔ the pillars) | branch colour | `2` | none (solid) | `markerStart` **+** `markerEnd` ArrowClosed, colour-matched, **default size** | MindMap.tsx:209-212 |
  | **root-project** (pillar → a root project) | inherited | `2` | none (solid) | **none** | MindMap.tsx:1402-1411 |
  | **product** (root project → product) | inherited | `1.5` | `'5,5'` | **none** | MindMap.tsx:1423-1427 |
  | **activity** (project/product → activity) | inherited | `1.5` | `'2, 4'` | **none** | MindMap.tsx:1474-1478 |

  This **reverts** the current uniform `strokeWidth: 2` + `markerEnd ArrowClosed 22×22` on **every** edge
  (graph.ts:117-132 helper, applied at :168-170 base, :221-229 project, :243-250 activity): **only the
  base spine** carries markers (start **+** end, **default** size, not 22×22); **root-project, product,
  and activity** edges carry **no** arrowhead. Root-project edges stay solid `2`; product/activity become
  `1.5` dashed (`'5,5'` / `'2, 4'`). Branch-colour inheritance (`branchColor`) is unchanged. The
  `floatingEdge` helper must take the edge kind and emit markers for base edges only.

## 7. Page chrome (`GoalsPage.tsx` + `PageHeader.tsx`)

- Wrap the canvas in the shared **`PageHeader`** (shell-slice primitive) with `focal.goals.title` +
  subtitle + help, matching old-focal `Goals.tsx` (title + subtitle + AI button + toolbar). `PageHeader`
  gains one **optional** `subtitle?: string` prop rendered under the title **on desktop only** —
  old-focal's mobile Goals header omits the subtitle (Goals.tsx:37-50). Existing callers without the
  prop render identically (covered by `PageHeader.test.tsx`).
- In-canvas controls: keep the existing `Panel` + handlers (Add/Product/Activity/Undo/Redo/Auto-arrange,
  GoalsPage.tsx:368-428) — restyle undo/redo to compact icon buttons with the existing disabled logic;
  no handler change.
- `Background` dots + `Controls` styling to old-focal (`!bg-card !border-border !shadow-lg`); **remove
  the hard-coded `colorMode="light"`** (GoalsPage.tsx:365) and derive it from the app theme so dark
  mode matches (failure mode `goals.reactFlow.darkModeMismatch`).

## 8. Fidelity tolerance (resolves Gate-2 Should-Consider #1)

The objective bar for gate-4/5 review + visual QA:
- **Colours exact:** the hexes above (`#ef4444/#eab308/#9ca3af`, branch colours from `graph.ts`) and
  token-derived `--card`/`--border` — no eyeballed substitutes.
- **Spacing exact:** the old-focal Tailwind padding/min-width/icon classes per tier, verbatim.
- **Screenshot check:** `/goals` in **light and dark**, compared to the live old-focal goal-map, with
  no perceptible difference at 100% zoom on: node size tiers, wash, priority strip, selected ring,
  product square corners, dashed product edges, edge attachment angle, header/controls/background.
- **Known intentional deviation:** the 4 pillars keep their distinct colours (teal/orange/purple/blue
  from the established `graph.ts`), not old-focal's uniform green/blue — this predates the slice and is
  out of scope to change.

## 9. Interfaces / data (no API change)

- `FocalNodeData` (graph.ts:20-32) gains visual-only optional fields: `level?`/tier source,
  `priority?`, `isProduct?`, `isActivity?`, `isWorkTime?`, `sphere?`, `startDate?`, `endDate?`,
  `selected?`. All sourced from the existing `/api/mindmap/init` payload; IDs, positions, parent/edge
  selection, colours, and mutation routing unchanged.
- `goalNodeVisuals.ts` (new, pure): `tier`, `cardShape`, `priorityStripColor`, tier→padding/min-width/
  icon-size maps — the testable core.
- No change to `api/mindmap.ts`, generated `openapi.d.ts`, `layout.ts`, `history.ts`, the modals, routes,
  deps, or lockfiles.

## 10. Test strategy

- `goalNodeVisuals.test.ts`: priority→exact hex (+ null for missing/unknown); tier classification for
  each base id + project/product/activity; shape (product→`rounded-none`, else `rounded-xl`).
- `graph.test.ts` (extend): **project** nodes carry `priority`/`isWorkTime`/`sphere`; **activity** nodes
  carry `priority` + `startDate`/`endDate` (not the project-only fields); edge styles match §6 — base
  solid `2` with `markerStart`+`markerEnd`, product `1.5` `'5,5'` no marker, activity `1.5` `'2, 4'` no
  marker; **root-project solid `2` no marker**; inherited-colour assertions stay green.
- `FocalNode.test.tsx`: priority strip present only when required; selected boxShadow/scale only when
  `data.selected`; add-button callbacks fire with unchanged args; optional pill/dates render from i18n
  and are omitted when absent.
- `GoalsPage.test.tsx` (mock ReactFlow shell): header + subtitle render; loading/error branches; control
  disabled states (Add Product without roots, Add Activity without products, undo/redo by history);
  selecting a project still opens `ProjectEditModal` and marks the node selected.
- `PageHeader.test.tsx`: subtitle renders when given; absent → unchanged.
- Gate: `cd .worktrees/focal-redesign-goals/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`. DOM tests can't prove pixels → manual light/dark screenshot QA per §8.

## 11. Out of scope / rollback

- Out of scope (behaviour): inline label edit, resize, drag-to-reparent, manual edges, full
  create/delete undo, budget value rows, details/help node buttons, kanban. No server/API/schema change.
- Rollback: revert `features/goals/*`, the `.goal-node` CSS block, the optional `PageHeader.subtitle`,
  tests, and locale keys. No persisted-state or behaviour change to undo.
