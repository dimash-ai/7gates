# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.6 / 10
Status: BLOCKED

## Reason
The implementation is surgical and matches most pinned visual specs, including node sizing, wash CSS, priority colours, selected boxShadow, edge-kind styles, i18n, and no API/dependency churn. It misses the exact FloatingEdge geometric-intersection requirement: diagonal edges in left/top quadrants are reflected to the wrong side of the node.

## Must Fix
- `apps/focal/client/src/features/goals/FloatingEdge.tsx:51` and `:56`: the left-side and top-side intersection branches subtract the signed delta, so a target down-left/up-left attaches toward the opposite corner instead of the true line-rectangle intersection. This violates the required "true geometric intersection" edge parity and will visibly mis-anchor diagonal edges.

## Should Consider
- Add a focused unit test for `nodeIntersection` covering all four diagonal quadrants; current tests cover edge styles but not the risky geometry.
- Full `vitest`/`build` could not run in this read-only review sandbox because Vite/TS attempted to write temp/build-info files.

## Tests Reviewed
Inspected `git show --stat`, `git diff afaaeba..dc1f1b5`, task/plan/design, old-focal `FloatingEdge.tsx`/`PyramidNode.tsx`; ran `biome check .` (passed), `tsc -p tsconfig.json --noEmit` (passed). `pnpm lint`, `tsc -b`, and `vitest` blocked by read-only EPERM.

## Release Risk
Medium

---
**Doer fix (commit a9a310c):** corrected `nodeIntersection` so the perpendicular offset follows the sign of the other axis' delta on all four sides (both branches use `+`), exported the helper, and added `FloatingEdge.test.ts` covering all quadrants incl. the two previously-mirrored cases. Re-verified green: lint + typecheck + 397/397 tests + build.
