# Review Verdict

Reviewer: Opus
Step: verify
Score: 9.5 / 10
Status: APPROVED

## Reason
Independently confirmed green (typecheck/lint clean, 98 files/1129 tests pass, build OK — the GPT report's sandbox `localStorage` failures were a verified runner artifact, not a regression). The cumulative diff is correct, surgical, and faithful to the approved reuse-first design: the reparent rides the existing tenant/role-checked PATCH with both parent fields nulled correctly (cross-verified against the backend schema + `update_project` `exclude_unset`/`setattr` and the `_guard_reparent` cycle guard), and every high-risk path the design called out — cycle-drop-fires-no-request, undo/redo-stack-stable-on-failed-PATCH, schedule draft always non-null `projectId` with product+root resolution, base-node non-schedulability, consume-once/TTL/malformed draft rejection, product-less `{projectId}` activity, and `canEdit` gating — has a direct test assertion. No secrets/PII/attribution; no backend change, no migration.

## Must Fix
None

## Should Consider
- The new `MoveProjectDialog` (`features/goals/MoveProjectDialog.tsx`) omits the optional sphere/work-time reassignment that old-focal's dialog offered when moving into a provision pillar (`old-focal/.../MindMap/MoveProjectDialog.tsx:94-99,143-150`). The design listed this as *optional* and the reparent rides the plain PATCH (which leaves the project's existing sphere intact, never violating the work-time rule), so this is a deferred UX convenience, not a correctness or data-integrity gap. Acceptable to ship; worth a follow-up note if sphere-on-move parity is later wanted.
- `CalendarPage.test.tsx` exercises the schedule-draft consume on the happy mount but doesn't re-assert TTL/stale rejection at the integration layer (delegated to the thorough `lib/scheduleDraft.test.ts` unit). Layering is fine; non-blocking.

## Tests Reviewed
Ran in-session (no sandbox), `apps/focal/client`: `pnpm typecheck` (clean), `pnpm lint` (Biome, 307 files, clean), `pnpm test:run` (98 files, 1129 tests passed), `pnpm build` (OK, pre-existing chunk-size advisory only). Read the reparent/createProject/graph/scheduleDraft/MoveProjectDialog/FocalNode/history tests; cross-checked backend `services/projects.py` + `schemas/projects.py`.

## Release Risk
Low
