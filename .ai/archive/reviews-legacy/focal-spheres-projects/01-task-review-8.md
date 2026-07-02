# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly bounded, with strong acceptance criteria for tenant isolation, typed errors, and work-time behavior. It is still blocked by a concrete project-delete contract mismatch that can make the implementation/tests encode the wrong data-lifecycle behavior.

## Must Fix
- `.ai/tasks/focal-spheres-projects.md:86`-`.ai/tasks/focal-spheres-projects.md:88` says other `project_id`/`product_id` references are `ON DELETE SET NULL`, but legacy/current Activity FKs are `ON DELETE CASCADE` (`focal/shared/schema.ts:1287`-`focal/shared/schema.ts:1288`, `superapp/apps/focal/server/app/models/activities.py:20`-`superapp/apps/focal/server/app/models/activities.py:24`). Correct the statement or explicitly scope those tables out so project delete expectations cannot be implemented/tested against a false FK contract.

## Should Consider
- `.ai/tasks/focal-spheres-projects.md:69`-`.ai/tasks/focal-spheres-projects.md:75` pins project create inheritance/coercion, but the cited legacy handler also auto-computes `positionX/positionY` for non-work-time `parentType === "budget"` creates (`focal/server/routes.ts:3666`-`focal/server/routes.ts:3679`). Add an acceptance criterion or explicitly defer this behavior.
- `.ai/tasks/focal-spheres-projects.md:5`-`.ai/tasks/focal-spheres-projects.md:6` promises the existing client can call unchanged, while `.ai/tasks/focal-spheres-projects.md:93`-`.ai/tasks/focal-spheres-projects.md:94` switches tenancy to authenticated `sub`. Clarify whether legacy `userId` body/query inputs are accepted and ignored, rejected, or must match `sub`.

## Tests Reviewed
Read `.ai/tasks/focal-spheres-projects.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, `superapp/apps/focal/CLAUDE.md`, cited legacy routes/storage/fuzzy code, contract-freeze route inventory, and current project/activity models. No runtime tests were run; this was a read-only task-definition review.

## Release Risk
Medium
