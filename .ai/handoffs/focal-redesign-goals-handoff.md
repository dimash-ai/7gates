# Stage

Stage 7: ship — the `focal-redesign-goals` slice of the `focal-redesign-pages` epic (visual re-skin
of the Goals page / "Карта целей" to exact old-focal parity). One commit `3c5cba5` on branch
`feat/focal-redesign-goals`, off the shell foundation `afaaeba`.

# What changed

A frontend **visual re-skin** of the Goals mind-map to old-focal's goal-map look, on the new stack
(React 19 / Tailwind 4 / shadcn) over the **existing** `/api/mindmap/init` graph + CRUD. Behaviour,
data flow, layout, history (undo/redo), drag-persist, and the create/edit modals are unchanged — only
appearance changed.

- **Node cards** (`FocalNode.tsx`) → old-focal `PyramidNode` look: `border-2` + `shadow-lg`; the
  per-tier size hierarchy (top `px-5 py-4`/180px, mid `px-4 py-3`/160px, leaf `px-3 py-2`/140px);
  product cards `rounded-none`; the branch/pillar **wash** via a new scoped `.goal-node` rule
  (`color-mix` 15% over `#fff` light / 20% over `hsl(var(--card))` dark — theme-correct, no JS
  observer for the wash); the **priority strip** (left bar: high `#ef4444` / medium `#eab308` / low
  `#9ca3af`, on project/product/activity only); the **selected** state (colour ring via inline
  `boxShadow` + `scale-[1.02]`); dashed on-card add buttons; optional work/sphere pill + activity
  dates from i18n.
- **Edges** (`graph.ts` + `FloatingEdge.tsx`) → four exact old-focal kinds: base spine solid `2` with
  double-ended arrowheads; root-project solid `2` no arrowhead; product `1.5` dashed `'5,5'` no
  arrowhead; activity `1.5` dashed `'2, 4'` no arrowhead. `FloatingEdge` now anchors at the true
  geometric node-border intersection (was the side-midpoint).
- **Page chrome** (`GoalsPage.tsx` + `PageHeader.tsx`) → shared `PageHeader` with title + subtitle
  (subtitle desktop-only) + help; ReactFlow `colorMode` derived from the live theme; old-focal
  background dots + control styling; the selected node threaded into node data.
- Pure visual helpers extracted to `goalNodeVisuals.ts`; i18n keys added in `en.json` + `ru.json`.

# Files touched

15 files, all under `apps/focal/client/` (+1036 / −114):
- `src/features/goals/goalNodeVisuals.ts` (new) + `goalNodeVisuals.test.ts` (new)
- `src/features/goals/FocalNode.tsx` + `FocalNode.test.tsx` (new)
- `src/features/goals/FloatingEdge.tsx` + `FloatingEdge.test.ts` (new)
- `src/features/goals/graph.ts` + `graph.test.ts`
- `src/features/goals/GoalsPage.tsx` + `GoalsPage.test.tsx` (new)
- `src/components/PageHeader.tsx` + `PageHeader.test.tsx`
- `src/index.css` (the scoped `.goal-node` wash rules)
- `src/i18n/locales/en.json` + `ru.json`

No change to `api/*`, generated `openapi.d.ts`, `layout.ts`, `history.ts`, the modals, routes,
`package.json`, or `pnpm-lock.yaml`.

# Tests run

```sh
cd .worktrees/focal-redesign-goals/apps/focal/client
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

# Verification output

```sh
lint:      Checked 222 files. No fixes applied.   (clean)
typecheck: tsc -b → 0 errors
test:run:  Test Files 53 passed (53) | Tests 403 passed (403)   (+6 adversarial vs baseline)
build:     ✓ built — 2969 modules transformed, 0 failures
```

# Still needs review

- **Visual QA is the one unmet pre-merge gate.** Automated tests prove behaviour, structure, the exact
  colour/stroke/marker constants, and the intersection geometry — but they **cannot prove pixel
  parity**. Before merge, run the app in **light and dark** and compare `/goals` against old-focal's
  goal-map (node tiers, wash, priority strip, selected ring, dashed product/activity edges,
  header/controls). Local run: `cd superapp/apps/focal/client && pnpm dev`, sign in with a
  superapp-dev account.
- **Intentional deviation from the binding source (blessed):** `FloatingEdge.nodeIntersection`
  **corrects** a latent left/top sign error in old-focal's `getNodeIntersection` (old-focal mirrors
  down-left / up-right edges to the wrong corner; old-focal mostly masks it by using handle-anchored
  edges, but the new app routes all edges through the floating helper, so the math must be correct).
  Documented in-code and covered by `FloatingEdge.test.ts` across all four quadrants. (The design §6
  text "use old-focal's intersection math" is reconciled to "corrected intersection math.")
- **Optional follow-ups (non-blocking, from the gate-6 review):** a guard test that a base node never
  shows a priority strip; a `FloatingEdge` component-body test (path-mode branch + missing-node early
  return); tightening the selected-state assertion to the exact `boxShadow` value.

# PR / release notes (for users)

**Goals "Карта целей" has been re-skinned to the original Focal design.** The goal-map's cards,
connections, and header now follow the proven Focal look in both light and dark themes:

- Cards are sized by level (life-goal/mission largest, projects/activities smallest), tinted with
  their branch colour, and show a coloured **priority bar** for projects and activities.
- The selected card is highlighted with a coloured ring.
- Connections read like the original: solid double-arrow lines for the core pyramid, plain solid lines
  to projects, and dashed lines to products and activities — meeting each card cleanly at its border.
- The page gains the standard title + subtitle header.

Everything you could do before still works exactly the same — creating and editing goals, projects,
products and activities; dragging to rearrange; undo/redo; auto-arrange. This change is appearance
only; no data or behaviour changed.

_Pre-merge step (not yet done): a light/dark visual sign-off of `/goals` against old-focal. Automated
tests prove the exact colours, strokes, edge geometry and behaviour, but cannot prove pixel-level
parity — so the final visual confirmation is a manual check before this is merged._ (Contains no
secrets, tokens, keys, or PII.)

# Status

CODEX APPROVED (9.1) — all 7 gates passed. Cleared for release pending the user's light/dark visual
sign-off (the one acceptance check automated tests cannot prove).

---
Gate scores: think 9.1 · plan 9.4 · design 9.6 · build 9.3 · review 9.3 · test 9.4 · ship 9.1.
