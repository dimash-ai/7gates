# Codex Review Verdict

Score: 8.7 / 10
Status: BLOCKED

## Reason
Verification is green and the tests cover most task/tag contract risk, but two acceptance-critical assertions are weaker than claimed. One priority test is tautological, and the system-field immutability test only covers part of the required whitelist/blacklist.

## Must Fix
- `superapp/apps/focal/server/tests/test_tasks_db.py:534-540` does not actually test the required “sphere only when isWorkTime is false” rule from `.ai/tasks/focal-tasks-tags.md:139-141`: it creates a work-time project without any `sphere`, so the test would pass even if task priority incorrectly used a sphere on work-time projects. Add a case that seeds or updates a work-time project with a non-null sphere and proves the sphere priority is ignored.
- `superapp/apps/focal/server/tests/test_tasks_db.py:407-414` only checks `userId`, `priorityLevel`, and `eventId`, but `.ai/tasks/focal-tasks-tags.md:128-130` and `.ai/tasks/focal-tasks-tags.md:240-243` require `id`, `priorityScore`, `createdAt`, and `updatedAt` to be never client-settable too. Add direct assertions for those fields.

## Should Consider
- Add PATCH-specific coverage for non-owned/missing `productId` and `activityId`; create coverage exists at `superapp/apps/focal/server/tests/test_tasks_db.py:400-404`, but update uses the same risky ownership surface.
- Add a direct test that mismatched but user-owned `projectId` + `productId` is accepted, since legacy parity explicitly allows independent link validation.

## Tests Reviewed
Inspected `.ai/runs/focal-tasks-tags-verify.txt`: `ruff`, `ruff format --check`, `mypy`, `pytest` 258 passed, `alembic upgrade head`, and `alembic check` no new operations. Reviewed `test_tasks_db.py`, `test_priority.py`, `test_daterange.py`, `test_completion.py`, `test_contracts.py`, `test_tags.py`, `test_tags_db.py`, plus the task and relevant implementation diff.

## Release Risk
Medium
