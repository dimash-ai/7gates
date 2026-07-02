# Verify Report — focal-parity-goals-graph (GPT Codex, doer)

Doer: GPT Codex (`codex exec --sandbox workspace-write`, gpt-5.5). Repo: `superapp-goals`; base `feature/focal-migration`. Frontend-only diff (19 production/test files; verify added 2 more test files).

> The verify run was executed in codex's workspace-write sandbox, whose network is restricted: the `pnpm` shim hangs on a package fetch (`fetch failed`) before running, and the sandbox Node's webstorage shim is missing `localStorage.clear/removeItem` in some suites. GPT worked around the former with the repo's locally-installed binaries (`node_modules/.bin/{tsc,biome,vitest,vite}`). The full-suite storage failures were isolated to the sandbox runner, not the diff. The **authoritative** lint/typecheck/test/build green run below was completed **in-session** (no sandbox) and supersedes the sandbox runner quirks.

## What was scrutinized (one adversarial pass, whole change)
- **Frontend-only confirmed**, working tree clean; no backend change. Risk concentrated in `GoalsPage.tsx`, the `graph.ts` helpers, `history.ts`, and the calendar schedule handoff — all read line-by-line against the design's success criteria + flow tables and the old-Focal MindMap reference.
- **No production defect found** that warrants a gate-B stop. The slice deliberately reuses the existing `PATCH /api/projects/{id}` + server cycle guard and computes affected counts client-side (vs old-focal's `/move` + `/move-preview` endpoints) — a sanctioned reuse-first choice, not a gap.
- **Reparent payload**: `reparentProject` sends both parent fields, nulling the opposite (pillar / project / root) — matches `update_project`'s `exclude_unset` semantics.
- **Cycle rejection**: the pure `dropResult` returns `{kind:'cycle'}` for a descendant drop; `onNodeDragStop` snaps the node home, shows the `focal.goals.move.cycle` notice, and fires **no** request (verified: no `reparentProject`/`moveProject`/`moveActivity`/`moveNode` call).
- **Undo/redo stack consistency**: a failed reparent undo/redo PATCH leaves the history stack unchanged (the popped state is committed only via `applyReparent`'s success callback) and surfaces `focal.goals.move.error`.
- **Schedule draft ownership**: `scheduleDraftFor` always yields a non-null `projectId`; a product-owned activity carries `projectId` (resolved root) + `productId`; base nodes are not schedulable; the sessionStorage draft is consumed exactly once with a freshness TTL.
- **Product-less direct activity**: a product-less root project sends `createActivity(..., { projectId }, ...)` — not `{ productId }` — matching old-focal's `hasProducts === false` rule.
- **`canEdit` gating** on reparent + schedule; **ru/en** goals move/schedule keys present symmetrically.
- **Deliberate (not defects)**: multi-select group-move and drag-to-create-child are intentionally absent (the new single-select + button-based child-creation model supersedes those old-focal gestures).

## Tests added (test-only; under `superapp-goals`)
- `features/goals/GoalsPage.reparent.test.tsx` (new) — page-level harness that drives the real `onNodeDragStop` via a mocked `ReactFlow` (each node a button firing drag-start→drag-stop) with constructed node geometry so `dropResult` resolves through GoalsPage. Proves: (1) a descendant drop is rejected client-side with the cycle notice and **no** move/reparent request; (2) a failed reparent **undo** PATCH leaves the undo stack intact (undo stays enabled, redo disabled) + shows the error; (3) a failed reparent **redo** PATCH leaves the redo stack intact + shows the error.
- `features/goals/GoalsPage.createProject.test.tsx` (extended) — proves adding an activity directly under a product-less project calls `createActivity('Kickoff', { projectId: 'root' }, null)` (projectId, not productId).

## Verification results
- **Sandbox (GPT, local binaries):** biome `Checked 307 files … No fixes applied`; focused goals proof set **4 files / 71 tests pass**; Vite production build completed (only the pre-existing large-chunk warning). Full-suite run hit a sandbox-only `localStorage`/webstorage runner incompatibility in 6 unrelated files (995 tests still passed); classified as a runner-environment issue, not a goals regression.
- **Authoritative (in-session, no sandbox):**
  - `pnpm typecheck` → clean
  - `pnpm lint` (biome, 307 files) → clean
  - `pnpm test:run` → **98 files, 1129 tests passed** (includes the 4 new verification tests)
  - `pnpm build` → built OK (pre-existing chunk-size advisory only)
- `pnpm lint:i18n` has pre-existing hardcoded-string failures in unrelated files (IntegrationsPage, HeatmapPage, HabitJournal, dashboard/overview, analytics sections) — none in this diff.

## Release risk
Low–Medium. Frontend-only; reuses an existing tenant/role-checked PATCH + server cycle guard; sessionStorage holds only a non-sensitive create draft consumed once. No new endpoint/auth surface, no migration. Rollback = revert the slice commit.
