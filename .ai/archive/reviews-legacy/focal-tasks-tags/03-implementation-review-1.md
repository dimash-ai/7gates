# Codex Review Verdict

Score: 8.1 / 10
Status: BLOCKED

## Reason
Scope is mostly correct and the implementation is clean, but two priority/input-contract edge cases violate the task’s binding behavior. Static checks and non-DB tests pass, but DB-backed contract tests could not be run in this read-only sandbox.

## Must Fix
- `superapp/apps/focal/server/app/schemas/tasks.py:27` and `superapp/apps/focal/server/app/schemas/tasks.py:52`: `due_date: date | None` accepts datetime strings like `2026-01-15T00:00:00Z` and coerces them to `2026-01-15`, but the task requires `dueDate` to be exactly `YYYY-MM-DD`. Targeted probe showed both `TaskCreate` and `TaskUpdate` accept that invalid shape.
- `superapp/apps/focal/server/app/services/tasks.py:231`: priority energy uses `bool(project.gives_energy)` whenever a project exists, so `project.gives_energy is None` scores as false instead of falling back to `sphere.gives_energy` per legacy `project?.givesEnergy ?? sphere?.givesEnergy ?? false`. Targeted probe returned `0.17` where the nullish-fallback model returns `0.27`.

## Should Consider
- Add DB/contract tests for invalid `dueDate` datetime strings, `startDate > endDate`, update-time non-owned `projectId`/`productId`/`activityId`, `completed: null`, and the nullable `givesEnergy` sphere fallback. Current `test_tasks_db.py` does not cover those required edge cases.
- `tests/test_contracts.py` was not extended for tasks/tags despite the plan calling that out; much of the shape coverage exists elsewhere, but the contract pin is weaker than planned.

## Tests Reviewed
`git -C superapp --no-pager diff`; `git -C superapp status`; `PYTHONDONTWRITEBYTECODE=1 .venv/bin/pytest -q -s -p no:cacheprovider` → 97 passed, 128 skipped; `ruff check .` passed; `ruff format --check .` passed; `mypy app --no-incremental --cache-dir=/dev/null` passed. DB-backed tests, `make verify`, and `alembic check` were not run because this sandbox is read-only/no Docker DB.

## Release Risk
Medium
