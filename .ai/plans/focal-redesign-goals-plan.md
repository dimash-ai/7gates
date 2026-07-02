# Summary

Re-skin the existing Goals mind-map to match old-focal's goal-map presentation while leaving the current graph, CRUD, drag persistence, undo/redo, dialogs, and API flow intact. The implementation should first carry the visual metadata already present in `/api/mindmap/init` into node data, then port the old `PyramidNode`/`FloatingEdge` visual rules onto the new @xyflow graph, and finally wrap the canvas in the shared page header so the page chrome matches the old Goals page. No server, generated OpenAPI, schema, or behavior change is planned.

Design source inspected in this checkout: `/Users/allosta/Desktop/allosta/superapp/apps/old-focal/client/src/pages/Goals.tsx` and `/Users/allosta/Desktop/allosta/superapp/apps/old-focal/client/src/components/MindMap/{PyramidNode.tsx,GoalNode.tsx,FloatingEdge.tsx,MindMap.tsx}`. Implementation target: `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/features/goals/*`.

# Files to change

| path | change | why |
|------|--------|-----|
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/features/goals/goalNodeVisuals.ts` | Add a small pure visual helper/constants module for node tiering, priority-strip colours, node kind flags, and legacy card class/style decisions. | Keeps old-focal visual rules testable without mixing all logic into the React component. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/features/goals/goalNodeVisuals.test.ts` | Add unit tests for priority colour mapping, invalid/missing priority fallback, base/project/product/activity tier classification, and product square-corner vs rounded card decisions. | Proves the core visual rules that are easy to regress and hard to verify through full DOM screenshots alone. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/features/goals/graph.ts` | Extend `FocalNodeData` and `buildGraph` to pass visual-only metadata: base level/tier, project `priority`, `isWorkTime`, `sphere`, `parentProjectId`/`isProduct`, activity flag, and activity dates. Keep existing node/edge IDs, positions, parent logic, branch colours, and CRUD routing unchanged. | `FocalNode` needs old-focal visual inputs that already exist in the API payload; this is data propagation, not a behavior/API change. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/features/goals/graph.test.ts` | Add assertions that project/activity nodes carry the new visual metadata and that existing dashed product-edge and inherited-colour tests still pass. | Proves the re-skin receives real data and does not disturb graph semantics. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/features/goals/FocalNode.tsx` | Port old-focal card visuals: `border-2`, branch wash, dark wash, `shadow-lg`, top/mid/leaf padding and min-widths, product square corners, activity rounded corners, priority left strip, selected ring/elevation, invisible four-side handles, icon sizing, dashed on-card add buttons, work/sphere pill, activity dates, and footer notes where metadata is present. | This is the main node visual parity surface. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/features/goals/FocalNode.test.tsx` | Add component tests around selected styling, priority strip, product/activity styling, button callbacks through `GoalsContext`, and localized optional labels. | Proves visible node affordances while preserving existing add-child behavior. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/features/goals/FloatingEdge.tsx` | Align edge rendering with old-focal: use the geometric border intersection algorithm, old fallback sizes for unmeasured nodes, preserve straight/step/smoothstep/bezier modes, and apply legacy fallback stroke/arrow values only when the edge style/marker did not already supply them. | Edges should visually meet card boundaries like old-focal without changing graph creation. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/components/PageHeader.tsx` | Add an optional `subtitle` prop rendered under the title on desktop/mobile without changing existing callers. | Old-focal Goals has a title and subtitle; `PageHeader` already owns the shared header and toolbar but currently cannot render the subtitle. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/components/PageHeader.test.tsx` | Add coverage that a subtitle renders when provided and existing header/toolbar behavior remains unchanged. | Contains the only shared primitive change. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/features/goals/GoalsPage.tsx` | Wrap the canvas in `PageHeader` with localized title/subtitle/help, restyle the in-canvas controls to old-focal-style buttons, remove forced `colorMode="light"` in favor of app theme, set old-focal background/controls styling, and pass explicit selected state to nodes for the ring while keeping modal-opening click behavior. | Brings page chrome and canvas controls to parity without changing data flow. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/features/goals/GoalsPage.test.tsx` | Add focused render tests with mocked API/ReactFlow as needed for header, loading/error states, toolbar controls, disabled states, and selected-node propagation. | Gives page-level confidence without brittle full xyflow layout assertions. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/i18n/locales/en.json` | Add missing `focal.goals` keys for title, subtitle, help, node footer/meta labels, priority label, and any new accessible labels/tooltips. | No hardcoded visible or accessible strings. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client/src/i18n/locales/ru.json` | Add the same keys in Russian, reusing old-focal copy where it maps cleanly. | RU remains first-class and old-focal parity is primarily RU-visible. |

No change is planned for `api/mindmap.ts` endpoints, generated `api/openapi.d.ts`, backend code, layout/history algorithms, create/edit modal behavior, route registration, package dependencies, or lockfiles.

# Implementation slices

1. Add testable visual metadata without changing rendered appearance.
   - Create `goalNodeVisuals.ts` with legacy constants traced to `PyramidNode.tsx`: priority strip colours (`high #ef4444`, `medium #eab308`, `low #9ca3af`), base tier sizing (`top 180`, `mid 160`, leaf `140` min-width), branch wash defaults, selected shadow/ring recipe, and product/activity shape rules.
   - Extend `FocalNodeData` with visual-only fields: `level`, `priority`, `isProduct`, `isActivity`, `isWorkTime`, `sphere`, `startDate`, `endDate`, and optional `description`.
   - In `buildGraph`, set base levels for the seven pyramid nodes, set project `priority`/`isWorkTime`/`sphere`/`isProduct`, and set activity `isActivity` plus dates. Do not alter IDs, edge parent selection, position handling, or mutations.
   - Update `graph.test.ts` and add `goalNodeVisuals.test.ts`; build stays green because UI output is not yet restyled.

2. Re-skin `FocalNode` over the same callbacks.
   - Use `goalNodeVisuals` for tier classes and inline CSS variables. Prefer CSS variables plus Tailwind dark classes for colour mixing instead of the old MutationObserver approach.
   - Match old-focal card structure: `relative overflow-hidden flex flex-col`, `border-2`, `shadow-lg`, tier padding, min-height `50`, selected `ring-2 ring-offset-2 ring-offset-background scale-[1.02]` and colour-tinted shadow.
   - Add the priority strip only for project/product/activity nodes with a normalized `high|medium|low` priority. Invalid or missing priority shows no strip.
   - Keep handles hidden and noninteractive, adding left/right handles for parity while `nodesConnectable={false}` remains unchanged.
   - Restyle on-card add buttons as dashed, muted, old-focal buttons and keep the existing `GoalsContext` callbacks exactly as they are.
   - Render optional work/sphere pill, activity date row, and footer notes from localized keys only when corresponding metadata is present.
   - Add `FocalNode.test.tsx` assertions for visual states and callbacks; do not add inline edit, resize, or drag-to-reparent.

3. Align edge presentation without changing graph semantics.
   - Update `FloatingEdge` to use old-focal's geometric node-boundary intersection so arrows meet the card border near the true target direction, not always side midpoints.
   - Keep the existing `edgeType` support and typed structural node shape.
   - Preserve `graph.ts` edge styles as source of truth: product edges stay dashed with `strokeDasharray: '5 5'`, branch/pillar colours stay inherited, and marker dimensions stay large enough to read. Only add defensive fallback stroke/marker values in `FloatingEdge` when the edge has none.
   - Add or extend tests at the graph/helper level for dashed vs solid styles and marker dimensions; avoid brittle SVG path snapshots unless the implementation exposes a small pure border-point helper worth testing.

4. Restore old-focal page chrome through the shared header and canvas controls.
   - Add optional `subtitle` support to `PageHeader` and tests; existing pages should render identically when the prop is absent.
   - Wrap `GoalsPage` in `flex h-full flex-col overflow-hidden bg-background text-foreground`, render `PageHeader` with `focal.goals.title`, `focal.goals.subtitle`, and help text, and rely on shared `PageToolbar` for the AI/theme/language actions.
   - Keep the ReactFlow area as the remaining flex child with a minimum usable height.
   - Replace the current large text-heavy `Panel` with old-focal-style compact controls: Add Project/Product/Activity commands, icon undo/redo buttons with disabled states and optional history-count badges, and the auto-arrange dropdown. Preserve existing handlers and disabled logic.
   - Change the canvas background to old-focal dots (`gap 20`, `size 0.5`, muted foreground at low alpha) and controls styling (`!bg-card !border-border !shadow-lg`, hidden on very small screens if parity requires it).
   - Remove the hard-coded `colorMode="light"` and derive React Flow colour mode from the app theme so light and dark screenshots can both match.
   - Pass selected node state into the rendered nodes for the visual ring while preserving `onNodeClick` opening the same edit modals.
   - Add `GoalsPage.test.tsx` for header, loading/error states, controls, disabled add-product/add-activity states, and selected-node propagation.

5. Final parity polish and verification.
   - Compare light and dark screenshots against old-focal for node tiers, branch washes, priority strips, selected ring, dashed product edges, header, panel controls, ReactFlow controls, and background dots.
   - Keep strings localized in `en.json` and `ru.json`; no hardcoded Russian fallback text in components.
   - Run focused goals tests first, then the required client checks:
     `cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.
   - If a pre-existing check fails, prove it on the base branch before calling it pre-existing; otherwise fix only failures caused by this slice.

# Tests

- `goalNodeVisuals maps priority to legacy strip colours`: proves `high`, `medium`, and `low` map to the exact old-focal colours and unknown/null values do not invent a strip.
- `goalNodeVisuals classifies node tiers and shapes`: proves top base nodes, mid base nodes, regular projects, products, and activities receive the expected min-width/padding/rounded rules.
- `buildGraph carries project visual metadata`: with a project fixture containing `priority`, `isWorkTime`, `sphere`, `parentProjectId`, and `icon`, proves node data receives those fields while existing parent edge IDs and colours remain unchanged.
- `buildGraph carries activity visual metadata`: proves activity nodes get `isActivity`, dates, inherited/picked colour, and no product add-child affordance.
- Existing `graph.test.ts` dashed-product and solid-root edge tests remain green, proving edge semantics are preserved.
- `FocalNode renders the old-focal priority strip and selected ring`: proves the DOM contains the strip and selected classes/styles only when the node data/selection requires them.
- `FocalNode preserves add callbacks`: clicking pillar/project/product add buttons calls the same `GoalsContext` handlers with the same arguments as before.
- `FocalNode renders optional meta without hardcoded strings`: proves work/sphere pill, activity dates, and footer notes use i18n text and are omitted when metadata is absent.
- `GoalsPage renders shared header and toolbar`: proves title, subtitle, help affordance, and shared toolbar are present without duplicating a local AI button.
- `GoalsPage keeps loading and load-error states`: proves existing React Query loading/error branches still render localized messages.
- `GoalsPage renders old-focal canvas controls with correct disabled states`: proves Add Product is disabled without root projects, Add Activity is disabled without projects, undo/redo follow history state, and auto-arrange options call `reArrange`.
- `GoalsPage propagates selected node state without changing modal behavior`: clicking a project still opens `ProjectEditModal`, and the corresponding node is marked selected for `FocalNode`.
- `PageHeader subtitle is optional`: proves existing callers without `subtitle` are unaffected and a provided subtitle renders in the header.
- Final command set: `cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-goals/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.
- Manual/browser verification: open `/goals` in light and dark, compare against old-focal screenshots for node size hierarchy, wash colours, priority strip, selected state, dashed product edges, header/toolbar, controls, and background. This visual check is required because DOM tests cannot prove pixel parity.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `goals.init.loadFailed` | `getMindmapInit()` rejects through React Query | Existing `init.isError` branch in `GoalsPage` | Existing localized `focal.goals.error` message; no partial graph. |
| `goals.init.loading` | No exception; query pending | Existing `init.isLoading` branch in `GoalsPage` | Existing localized loading message. |
| `goals.visual.missingPriority` | No exception; `priority` is null/unknown | `priorityStripColor()` in `goalNodeVisuals` returns `null` | Node renders without a priority strip instead of showing a wrong colour. |
| `goals.visual.missingOptionalMeta` | No exception; `sphere`, `isWorkTime`, or activity dates are null | Conditional rendering in `FocalNode` | Card omits the optional pill/date row; label and add controls still render. |
| `goals.visual.unknownNodeKind` | No exception; node lacks explicit `level`/kind metadata | `goalNodeVisuals` falls back from node ID/data shape to leaf defaults | Node renders as a regular rounded leaf card rather than crashing. |
| `goals.move.persistFailed` | `moveProject`, `moveActivity`, or `moveNode` rejects | Existing `move.onError -> invalidate` in `GoalsPage` | Existing snap-back/refetch behavior; this slice changes only styling around it. |
| `goals.create.failed` | `createProject`, `createProduct`, or `createActivity` rejects | Existing mutation error path remains unchanged | Dialog remains under existing mutation state; no new visual error path is introduced. |
| `goals.header.subtitleRegression` | No runtime exception; shared header layout could wrap poorly | `PageHeader.test.tsx` plus light/dark screenshot verification | If caught before ship, adjust only the optional subtitle markup/classes; existing pages without subtitles remain unchanged. |
| `goals.reactFlow.darkModeMismatch` | No exception; React Flow colour mode could diverge from app theme | Theme-derived `colorMode` in `GoalsPage` and light/dark screenshot check | Canvas controls/background follow the app theme instead of staying forced light. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** — This is the minimum viable old-focal visual parity slice: node cards, edges, page header, and in-canvas controls over the already-working Goals graph. Existing APIs, `buildGraph` parent semantics, `layoutTree`, `history`, move/create/edit modals, and route loading remain the behavior base. The only shared change is an optional `PageHeader.subtitle` prop required by old-focal header parity.
- **Architecture** — Data flow stays one-way: `/api/mindmap/init` -> `buildGraph` -> node data -> `FocalNode` visuals. Visual-only helpers are pure and local to `features/goals`; they do not own state or make requests. Unhappy paths remain the existing React Query loading/error branches and mutation invalidation paths. Optional visual metadata is guarded and never blocks graph rendering.
- **Design** — The implementation explicitly covers light and dark mode, loading, load-error, empty payload, selected node, project/product/activity, missing optional metadata, disabled controls, and mobile header wrapping. It ports visible old-focal details that are in scope: tiered card sizes, branch washes, priority strip, selected elevation, dashed product edges, compact controls, background dots, and shared header/toolbar.
- **DevEx** — No dependency, lockfile, generated API, route, backend, or schema churn. Tests target pure visual decisions and accessible component behavior instead of snapshotting the whole canvas. Constants are named after the old-focal source they mirror so future reviewers can trace changes back to `PyramidNode.tsx` and `MindMap.tsx`.

# Risks & migrations

- No database migration, data backfill, server/API/schema change, generated OpenAPI change, environment variable, dependency, or lockfile change.
- Main risk: exact old-focal node visuals depend on inline colour mixing across light/dark themes. Rescue: keep colour logic in `goalNodeVisuals`/CSS variables, screenshot both themes, and adjust only the visual helper/classes.
- Secondary risk: adding `PageHeader.subtitle` touches a shared primitive. Rescue: make it optional, covered by `PageHeader.test.tsx`, and verify existing pages still render unchanged when the prop is absent.
- Tertiary risk: testing `ReactFlow` directly in jsdom can be brittle. Rescue: mock only the ReactFlow shell in `GoalsPage.test.tsx` for header/control/selected-state tests and leave graph geometry to existing unit tests plus manual screenshot verification.
- Rollback plan: revert the planned goals feature files, optional `PageHeader` subtitle change, tests, and locale additions. No persisted data or API behavior changes are introduced.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting if implemented in the ordered slices above.
- [x] Size smell checked: this touches several files because visual parity spans graph metadata, node rendering, edge rendering, page chrome, localization, and tests. It remains one frontend feature re-skin with one optional shared header prop, no server/API work, and no behavior rebuild.

# Out of scope

- Manual edge drawing, node resize handles, drag-to-reparent UI, drag-to-create, selection-mode toolbar, delete-edge toolbar, and full old-focal undo/redo for create/delete/edit.
- Rebuilding `MindMap.tsx`, localStorage persistence, old-focal edge CRUD, or old-focal node detail/inline-edit behavior.
- Goals Kanban, other left-nav pages, task/event/calendar behavior, and unrelated shell redesign cleanup.
- Backend/API/schema/generated OpenAPI changes, fake fallback data, new endpoints, package dependencies, and lockfile edits.
