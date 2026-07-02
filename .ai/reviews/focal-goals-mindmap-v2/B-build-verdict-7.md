# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.2 / 10
Status: BLOCKED

## Reason
The `newNodeSlot` placement in `layout.ts` is a reasonable deviation from the design table because it reuses layout constants without creating an import cycle. The create-id, id-diff, ambiguous-diff, and PATCH-failure paths are mostly wired, but the slice still violates the design’s “nothing else moves / never global re-arrange” requirement for unpinned maps.

## Must Fix
- `apps/focal/client/src/features/goals/GoalsPage.tsx:699` and `apps/focal/client/src/features/goals/GoalsPage.tsx:730` persist only the new entity’s slot and then invalidate; the reload path at `apps/focal/client/src/features/goals/GoalsPage.tsx:296` rebuilds and relayouts the whole graph using only persisted positions from `apps/focal/client/src/features/goals/graph.ts:458`. Because `storedPositions` skips unpositioned existing nodes, adding a child can still move existing unpinned siblings/base nodes, which contradicts `.ai/design/focal-goals-mindmap-v2-design.md:97` and `.ai/design/focal-goals-mindmap-v2-design.md:142`.

## Should Consider
- `apps/focal/client/src/features/goals/GoalsPage.createPlacement.test.tsx` is untracked in `git status`; make sure it is added with the slice.
- The page tests assert finite move coordinates, but do not assert the persisted coordinates are actually adjacent to the intended parent or non-overlapping; the pure `newNodeSlot` tests cover this only at helper level.

## Tests Reviewed
Inspected `git diff`, `git status`, `.ai/runs/focal-goals-mindmap-v2-build.txt` Slice 4, design doc, `layout.test.ts`, and `GoalsPage.createPlacement.test.tsx`. Build log reports `pnpm vitest run src/features/goals`, `pnpm lint`, `pnpm typecheck`, and `pnpm build` passing; full `pnpm test:run` has the documented pre-existing TasksPage failures.

## Release Risk
Medium
