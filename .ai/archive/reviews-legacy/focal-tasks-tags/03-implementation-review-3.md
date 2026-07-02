# Codex Review Verdict

Score: 8.2 / 10
Status: BLOCKED

## Reason
The implementation is mostly scoped to the planned tasks/tags backend slice and the core CRUD/enrichment/priority structure is sound. Approval is blocked because strict `YYYY-MM-DD` validation is incomplete, allowing malformed task dates and malformed list query windows to be accepted instead of rejected/falling back per contract.

## Must Fix
- `apps/focal/server/app/schemas/tasks.py:23`: `_validate_date` only rejects malformed strings, so non-string JSON values can fall through to Pydantic date coercion. Verified with `.venv/bin/python -c ...`: `TaskCreate.model_validate({"title":"T","dueDate":0})` produces `1970-01-01` instead of `validation_error`, violating the `dueDate` must be `YYYY-MM-DD` contract.
- `apps/focal/server/app/domain/daterange.py:5`: `parse_iso_date()` uses `date.fromisoformat()` directly, which accepts non-contract formats like `20260115` and `2026-W03-1`; malformed `startDate`/`endDate` should fall back to the current month, not silently use those dates.

## Should Consider
- Add DB tests for product/activity link ownership, PATCH attempts to set `id`/`userId`/`eventId`/`priorityScore`/`priorityLevel`, and the sphere priority/energy branch. The implementation appears aligned, but these are acceptance-criteria edges not currently pinned.

## Tests Reviewed
Ran `git -C superapp --no-pager diff` and `git -C superapp status`. Inspected the plan, task, scoring rubric, legacy `focal/server/{routes,storage}.ts`, `focal/server/utils/functions.ts`, legacy schema, and the FastAPI scaffold. Ran `.venv/bin/ruff check app tests/test_daterange.py tests/test_priority.py tests/test_completion.py tests/test_tags.py` (pass), `MYPY_CACHE_DIR=/dev/null .venv/bin/mypy --no-incremental app` (pass), and `PYTHONDONTWRITEBYTECODE=1 .venv/bin/python -m pytest -s -p no:cacheprovider tests/test_daterange.py tests/test_priority.py tests/test_completion.py tests/test_tags.py` (36 passed). Did not run DB-backed tests, `make verify`, or Alembic checks in this read-only environment.

## Release Risk
Medium
