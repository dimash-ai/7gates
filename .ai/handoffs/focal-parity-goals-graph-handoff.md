# Stage
3-Gate · C (verify) — APPROVED, ready to ship. Slice 8 follow-up: the Goals-map structural interactions that the re-skin deferred.

# What changed
The deferred heavier interactions of the Goals (MindMap) page, closing the last old-Focal parity gaps:
- **Slice 1 — drag-to-reparent + move preview.** Dragging a project node onto a different pillar (or onto/off another project) opens a confirm dialog showing from→to and the client-derived count of products/activities that move with it; confirm rides the existing `PATCH /api/projects/{id}` (both parent fields sent, the opposite nulled) and the subtree recolours on refetch. A drop onto the project's own descendant is rejected client-side with a notice and fires no request (server cycle-guard is the second line). The structural move pushes an undo-history entry; undo/redo restore/re-apply the parent and leave the stack unchanged if a PATCH fails.
- **Slice 2 — schedule-to-calendar from a node.** A calendar-icon action on a project/product/activity node stows a one-shot draft in `sessionStorage` (resolving the node's owning project + product so the event is filed, never orphaned) and navigates to the calendar, which consumes the draft once on mount and opens the create dialog pre-filled.
- **Slice 3 — product-less project parity.** A project with no products now also offers a direct "+ Activity" affordance, creating an activity by `projectId` (old-focal's `hasProducts === false` rule); once it gains a product, activities file under products as before.

Frontend-only; no backend change (reparent reuses the existing PATCH + server cycle guard; affected counts are client-derived). Multi-select group-move and drag-to-create-child were inspected and intentionally not ported — the new single-select + button-based child-creation model supersedes those gestures.

# Files touched
- `apps/focal/client/src/api/mindmap.ts` — `reparentProject` wrapper + `ReparentTarget`.
- `apps/focal/client/src/features/goals/graph.ts` — pure helpers `affectedCounts`, `isDescendant`, `rootProjectOf`, `dropTargetAt`, `dropResult`, `scheduleDraftFor`; `addActivityDirect` node field.
- `apps/focal/client/src/features/goals/history.ts` — tagged move/reparent undo-history union.
- `apps/focal/client/src/features/goals/GoalsPage.tsx` — drop dispatch, reparent confirm/cancel/undo/redo, schedule handler, direct-activity wiring.
- `apps/focal/client/src/features/goals/MoveProjectDialog.tsx` (new) — move-confirm dialog.
- `apps/focal/client/src/features/goals/FocalNode.tsx`, `goalsContext.ts` — node schedule button + direct-activity button + context handlers.
- `apps/focal/client/src/features/calendar/CalendarPage.tsx` — read-once schedule-draft mount effect.
- `apps/focal/client/src/lib/scheduleDraft.ts` (new) — the sessionStorage handoff (write/read-once/TTL).
- `apps/focal/client/src/i18n/locales/{en,ru}.json` — `focal.goals.move.*`, `focal.goals.node.schedule`.
- Tests: `graph.reparent.test.ts`, `graph.scheduleDraft.test.ts`, `MoveProjectDialog.test.tsx`, `lib/scheduleDraft.test.ts`, `GoalsPage.reparent.test.tsx` (new); `graph.test.ts`, `history.test.ts`, `FocalNode.test.tsx`, `CalendarPage.test.tsx`, `GoalsPage.createProject.test.tsx` (extended).

# Tests run
```sh
pnpm typecheck   # clean
pnpm lint        # biome, 307 files, clean
pnpm test:run    # 98 files, 1129 tests passed
pnpm build       # OK (pre-existing chunk-size advisory only)
```

# Verification output
```sh
 Test Files  98 passed (98)
      Tests  1129 passed (1129)
✓ built in 309ms
```

# Still needs review
- The new move dialog omits old-focal's **optional** sphere/work-time picker (shown when moving into a provision pillar). Deferred by design (the dialog field was marked optional; the plain-PATCH reparent leaves the project's existing sphere intact, so the work-time rule is never violated). Both gate reviewers accepted this as a non-blocking UX follow-up, not a correctness gap.
- `pnpm lint:i18n` has pre-existing hardcoded-string failures in unrelated files (IntegrationsPage, HeatmapPage, HabitJournal, dashboard/overview, analytics) — none in this diff.

# PR / release notes (for users)
On the Goals map you can now:
- **Move a project by dragging it** onto a different pillar (or onto/off another project). A dialog confirms where it's moving from and to and how many products and activities come along; dropping a project into its own sub-tree is prevented.
- **Undo and redo** a move from the toolbar or with Cmd/Ctrl+Z and Cmd/Ctrl+Shift+Z.
- **Schedule a goal to the calendar** — a calendar button on any project, product, or activity opens the calendar with a new event pre-filled and linked to that goal.
- **Add an activity straight to a project that has no products yet**, instead of having to create a product first.

# Status
GATE B (build): GPT Codex APPROVED (9.0). GATE C (verify): Opus APPROVED (9.5). Ready to open the PR into `feature/focal-migration`.
