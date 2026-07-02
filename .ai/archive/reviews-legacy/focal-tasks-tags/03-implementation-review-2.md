# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The implementation is scoped to the planned tasks/tags slice and most of the domain, schema, tenant, and parity work looks clean. It is blocked by a concrete PATCH correctness bug where `completed: null` is written to the row instead of being treated as no completion change.

## Must Fix
- `superapp/apps/focal/server/app/services/tasks.py:94` and `superapp/apps/focal/server/app/services/tasks.py:113`: `TaskUpdate(completed=None).model_dump(exclude_unset=True)` produces `{"completed": None}`, and `update_task` applies every field in `data`, so `PATCH /api/tasks/:id` with `{"completed": null}` writes `completed = NULL`. This violates `.ai/tasks/focal-tasks-tags.md:123` (`completed: null/omitted -> no completion change`) and can leave a completed task with stale `completed_at`; the test at `superapp/apps/focal/server/tests/test_tasks_db.py:359` only asserts `completedAt`, not that `completed` stayed unchanged.

## Should Consider
None

## Tests Reviewed
`git -C superapp --no-pager diff`; `git -C superapp status`; reviewed `.ai/plans/focal-tasks-tags-plan.md`, `.ai/tasks/focal-tasks-tags.md`, legacy `focal/server/routes.ts`, `focal/server/storage.ts`, and FastAPI scaffold/models/services. Ran `.venv/bin/ruff check .`, `.venv/bin/ruff format --check .`, `.venv/bin/mypy --cache-dir=/dev/null app`, and `PYTHONDONTWRITEBYTECODE=1 .venv/bin/pytest -s -p no:cacheprovider` (`97 passed, 135 skipped`; DB-backed tests skipped without `DATABASE_URL`). Also confirmed `TaskUpdate(completed=None).model_dump(exclude_unset=True)` returns `{'completed': None}`.

## Release Risk
Medium
