# Codex Review Verdict

Score: 8.7 / 10
Status: BLOCKED

## Reason
Verification is green and the implementation is broadly scoped to the requested tasks/tags slice, but the added tests miss security/data-loss tenant cases that the task explicitly requires. Current coverage would not catch regressions that leak task lists/enrichment across tenants or allow cross-tenant tag deletion.

## Must Fix
- `.ai/tasks/focal-tasks-tags.md:63` requires every query to be tenant-filtered and tested, but `superapp/apps/focal/server/tests/test_tasks_db.py:119` only checks by-id `GET` isolation and `superapp/apps/focal/server/tests/test_tasks_db.py:132` only checks cross-tenant patch/delete. Add a `GET /api/tasks` list isolation test where user B cannot see user A’s tasks.
- `.ai/tasks/focal-tasks-tags.md:226`-`.ai/tasks/focal-tasks-tags.md:229` requires the enrichment join to never return another user’s project data, but no test creates an existing/legacy task row whose `project_id` points at another user’s project. Add a DB-seeded test proving enriched `GET`/list do not expose `projectName`/`sphere`/`projectType` from the other tenant.
- `.ai/tasks/focal-tasks-tags.md:254`-`.ai/tasks/focal-tasks-tags.md:257` requires `/api/tags` to be tenant-scoped, but `superapp/apps/focal/server/tests/test_tags_db.py:112` only checks list and cross-tenant patch, while `superapp/apps/focal/server/tests/test_tags_db.py:142` only deletes the owner’s tag. Add a cross-tenant delete test proving user B cannot delete user A’s tag.

## Should Consider
- Add a positive owned-`activityId` test via direct DB seed, plus update/clear coverage; current tests only cover missing/non-owned activity links.
- Make priority integration assertions less relative: tests like `test_priority_mission_outranks_provision` and sphere priority currently assert ordering, not exact oracle scores.
- Add small parity pins for `userId` ignored on tags, duplicate tag names allowed, and non-string `contactId`/`goalId` rejected.

## Tests Reviewed
Read `.ai/runs/focal-tasks-tags-verify.txt`: `make verify` green with ruff, format, mypy, pytest `252 passed`, plus `alembic upgrade head` and `alembic check` reporting no new upgrade operations. Inspected `git -C superapp --no-pager diff`, untracked output, task spec, and the requested test files.

## Release Risk
Medium
