# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.3 / 10
Status: BLOCKED

## Reason
MAP layout and localization are scoped and covered, but the slice’s measured-pass ordering fix is still vulnerable on payload refetches after the previous graph has already measured. That breaks the design’s one-shot post-measurement layout criterion for subsequent loads.

## Must Fix
- `apps/focal/client/src/features/goals/GoalsPage.tsx:725` mounts `NodesMeasured` before `ReactFlow`, while `NodesMeasured` fires on every `epoch` change at `apps/focal/client/src/features/goals/GoalsPage.tsx:83-85` and disarms `pendingMeasure` at `apps/focal/client/src/features/goals/GoalsPage.tsx:321-324`. React Flow applies controlled `nodes` in its own passive `StoreUpdater` effect (`apps/focal/client/node_modules/@xyflow/react/dist/esm/index.js:282-292`, mounted inside `ReactFlow` at `.../index.js:3670`), so after a refetch where the old store is still `nodesInitialized=true`, the epoch effect can run before React Flow resets/remeasures the new nodes. I confirmed sibling passive effect order with `node --input-type=module -e ...` returning `A,BChild`; this means the “measured” pass can be burned on unmeasured fresh graph nodes and skipped when real measurement completes.

## Should Consider
- Add a refetch/regression test for the measured pass with a previously measured graph, not only the initial load mock path.

## Tests Reviewed
`git diff`, `git status`, `git diff --check`; inspected `.ai/runs/focal-goals-mindmap-v2-build.txt` Slice 2 (`pnpm lint`, `pnpm typecheck`, goals Vitest, `pnpm test:run`, `pnpm build` reported); ran a small React passive-effect order probe.

## Release Risk
Medium
