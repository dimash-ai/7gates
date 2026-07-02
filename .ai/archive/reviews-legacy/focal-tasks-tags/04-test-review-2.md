# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
The implementation appears scoped to the requested tasks/tags slice and the recorded verification is green, but several explicit acceptance criteria are still not pinned by tests. These are mainly coverage gaps around writable task fields, PATCH validation, malformed-id behavior, and deterministic tag ordering.

## Must Fix
- `.ai/tasks/focal-tasks-tags.md:249` requires `priority` and PATCH-only `status` to be stored as free-form strings, but `apps/focal/server/tests/test_tasks_db.py:407` only checks ignored system fields. Add DB-backed tests proving arbitrary `priority` and `status` values persist on create/PATCH.
- `.ai/tasks/focal-tasks-tags.md:130` requires PATCH link ownership plus date validation as on create, but invalid `dueDate`/`dueTime` tests only cover create at `apps/focal/server/tests/test_tasks_db.py:285` and `apps/focal/server/tests/test_tasks_db.py:347`. Add PATCH invalid `dueDate` and `dueTime` assertions.
- `.ai/tasks/focal-tasks-tags.md:252` requires unknown/malformed IDs on GET/PATCH/DELETE to return typed `not_found`, but `apps/focal/server/tests/test_tasks_db.py:158` covers only task GET. Add task PATCH/DELETE malformed-id envelope tests, plus DB-backed tag PATCH/DELETE malformed-id envelope tests.
- `.ai/tasks/focal-tasks-tags.md:254` requires `/api/tags` list ordering by `created_at` ASC, while `apps/focal/server/tests/test_tags_db.py:97` creates only one tag and cannot catch ordering regressions in `apps/focal/server/app/services/tags.py:77`. Add a multi-tag DB ordering test.

## Should Consider
- `apps/focal/server/tests/test_priority.py:46` mostly mirrors the formula directly; service-level priority cases for activity ignored, work-time sphere ignored, and sphere energy fallback would make the oracle less tautological.
- `apps/focal/server/tests/test_contracts.py:117` samples a few camelCase fields rather than pinning the full task/enriched response shape.

## Tests Reviewed
Inspected `.ai/runs/focal-tasks-tags-verify.txt`: ruff, format check, mypy, pytest `245 passed`, alembic upgrade head, and alembic check all green. Also inspected the requested test files, task spec, scoring rubric, `CLAUDE.md`, `git -C superapp --no-pager diff`, status, and untracked-file output. I did not rerun the suite.

## Release Risk
Medium
