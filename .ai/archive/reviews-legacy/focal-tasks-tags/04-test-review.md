# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
`make verify` is green, but the added tests do not yet meet the task’s own test-oracle requirements for the highest-risk behavior: priority calculation and PATCH semantics. The current tests cover happy paths well, but several complex branches could regress without a failing test.

## Must Fix
- `apps/focal/server/tests/test_tasks_db.py:310` and `apps/focal/server/tests/test_tasks_db.py:320` are the only DB-backed priority-model tests. They do not cover provision vs mission, `givesEnergy` on/off, sphere lookup/priority, hierarchy max across product/project/sphere, or PATCH-triggered priority recomputation; the helper tests at `apps/focal/server/tests/test_priority.py:23` and `apps/focal/server/tests/test_priority.py:46` do not exercise the DB/service resolution path required by the task.
- `apps/focal/server/tests/test_tasks_db.py:243` only verifies `description: null` clears while omitted `dueDate` is preserved. The task requires explicit-null PATCH coverage for nullable scalars broadly, including `dueDate`, `dueTime`, `contactId`, `goalId`, `projectId`, `productId`, and `activityId`, plus preservation when omitted.

## Should Consider
- `apps/focal/server/tests/test_tasks_db.py:277` checks non-string tag elements but not a non-array `tags` value, even though the task explicitly calls out both.
- `apps/focal/server/tests/test_tags_db.py:160` through `apps/focal/server/tests/test_tags_db.py:180` cover some tag validation, but missing/blank/over-long `name`, blank `color`, and PATCH over-limit cases remain unpinned.
- `.ai/runs/focal-tasks-tags-verify.txt` shows `make verify` only; the task’s separate `uv run alembic check` acceptance criterion is not represented in that output.

## Tests Reviewed
Read `.ai/runs/focal-tasks-tags-verify.txt` showing `ruff`, format check, mypy, and `pytest` all passed: `236 passed`. Inspected `git -C superapp --no-pager diff`, status/untracked output, `.ai/tasks/focal-tasks-tags.md`, `.ai/checklists/scoring-rubric.md`, and the requested test files.

## Release Risk
Medium
