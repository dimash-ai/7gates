# Codex Review Verdict

Score: 7.9 / 10
Status: BLOCKED

## Reason
The plan is broadly aligned with the task and actual Focal scaffold, and the five-slice structure is reasonable. It is blocked by one Alembic baseline-generation gap and one missing verification criterion for the required JWKS cache behavior.

## Must Fix
- `.ai/plans/focal-foundation-plan.md:34` through `.ai/plans/focal-foundation-plan.md:36` plan Alembic without `alembic/script.py.mako`. Prima has that template at `superapp/apps/prima/server/alembic/script.py.mako:1`, and Alembic revision generation reads `<script_location>/script.py.mako` at `superapp/apps/focal/server/.venv/lib/python3.14/site-packages/alembic/script/base.py:727`; implementing the plan as written can break the developer-run `alembic revision --autogenerate` required by `.ai/tasks/focal-foundation.md:106`.
- `.ai/plans/focal-foundation-plan.md:84` through `.ai/plans/focal-foundation-plan.md:90` omit a test proving the steady-state JWKS cache makes no per-request network call, despite the acceptance criterion at `.ai/tasks/focal-foundation.md:96`. Add an explicit fetch-count/cache test for repeated valid requests after warm/lazy fetch.

## Should Consider
- `superapp/apps/focal/server/uv.lock:1` already exists, so `.ai/plans/focal-foundation-plan.md:32` and `.ai/plans/focal-foundation-plan.md:129` should say validate/update the lockfile, not add the first lockfile.
- `superapp/apps/focal/server/app/errors.py:39` already defines `AuthRequiredError`; narrow `.ai/plans/focal-foundation-plan.md:41` to reuse/update it rather than add it.
- `.ai/plans/focal-foundation-plan.md:131` claims Alembic drift is mitigated by `alembic check` in `make verify`/CI, but `.ai/plans/focal-foundation-plan.md:58` only puts ruff, mypy, and pytest in `make verify`.

## Tests Reviewed
Read `.ai/tasks/focal-foundation.md`, `.ai/plans/focal-foundation-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, Focal server app/tests, Prima Alembic config/template, and Alembic package code. Did not run tests; review was read-only.

## Release Risk
Medium
