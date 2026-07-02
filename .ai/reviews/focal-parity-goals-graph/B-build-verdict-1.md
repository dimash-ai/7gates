# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.2 / 10
Status: BLOCKED

## Reason
The main contracts are mostly implemented, including the dual parent-field PATCH, schedule draft ownership, canEdit gating, and product-less activity creation. Two reparent edge cases still violate the design's move-preview / unhappy-path requirements.

## Must Fix
- `apps/focal/client/src/features/goals/graph.ts:411` undercounts affected activities when the moved project is itself a product: the filter counts `activity.projectId === projectId` and activities under child products, but misses activities directly owned by the moved product via `activity.productId === projectId`.
- Descendant drops are not fully rejected. `planReparent` returns `null` for `isDescendant`, but `onNodeDragStop` then falls through to regular move persistence and calls `move.mutate`, causing a PATCH instead of "no request" plus reject/snapback.

## Should Consider
- Add GoalsPage-level tests for valid reparent, descendant drop, read-only drag, and undo/redo PATCH failure; current added coverage is mostly pure helper/dialog coverage.
- Disable or guard Cancel while a reparent PATCH is submitting; `MoveProjectDialog` leaves Cancel active while only Confirm is disabled.

## Release Risk
Medium

---

## Resolution (round 2 build pass)
- **Must Fix 1** fixed: `affectedCounts` now also counts `activity.productId === projectId` (graph.ts) + a test "counts a moved product's own activities plus those under its nested products".
- **Must Fix 2** fixed: the drop decision is now the pure, unit-tested `dropResult` (graph.ts) returning `{kind:'cycle'}` for a descendant; `onNodeDragStop` snaps the node home, shows the `focal.goals.move.cycle` notice, and fires NO request. New `dropResult` tests cover cycle/pillar/project/none.
- Should Consider (Cancel) fixed: `MoveProjectDialog` Cancel is disabled while submitting.
- Should Consider (GoalsPage drag tests): the risky decision logic is now covered by pure `dropResult` unit tests; the xyflow drag-gesture integration itself is not driven in jsdom (no geometry/measurement), consistent with the existing GoalsPage test idiom. undo/redo stack-consistency on PATCH failure is structurally guaranteed (history pop committed only via `applyReparent`'s success callback) and backed by the pure history-reducer tests.
