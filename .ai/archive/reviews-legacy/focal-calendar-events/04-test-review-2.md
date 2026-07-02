# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The round-2 tests are substantially stronger and the verify artifact is clean, but two edge cases explicitly claimed as folded in are still not actually pinned. These are narrow test gaps, not evidence of broken implementation, so release risk stays low.

## Must Fix
- `apps/focal/server/tests/test_calendar_db.py:411-417` still does not test a non-owned `productId`; it covers `projectId=foreign_project`, `productId="missing"`, and `activityId=foreign_activity`, but the product ownership negative remains unpinned.
- `apps/focal/server/tests/test_calendar_db.py:371-379` still does not test `contactIds` with a non-string element; it covers `tags=[123]` and `contactIds="notalist"`, but not `contactIds=[123]`.

## Should Consider
- `apps/focal/server/tests/test_calendar_db.py:285-290` proves priority recomputes when a link changes, but not the stricter “recomputed on every update” contract. A non-link PATCH after changing the linked project/product/activity priority would pin that behavior more directly.

## Tests Reviewed
Inspected `.ai/runs/focal-calendar-events-verify.txt`: `ruff`, format check, `mypy`, `pytest` 322 passed, `alembic upgrade head`, and `alembic check` clean. Reviewed `git -C superapp --no-pager diff --cached`, plus `tests/test_calendar_db.py`, `tests/test_contracts.py`, `tests/test_migration.py`, task, plan, and scoring rubric.

## Release Risk
Low
