# Codex Review Verdict

Score: 7.6 / 10
Status: BLOCKED

## Reason
The plan is mostly aligned with the Focal scaffold and includes the right auth, health, `/me`, and test slices. It is blocked on Alembic safety: the planned migration setup can fail on a truly empty DB and can autogenerate destructive operations outside `focal.*`.

## Must Fix
- `.ai/plans/focal-foundation-plan.md:64-69` plans `include_schemas=True` without a schema filter. Alembic documents that this scans all schemas, and the repo's canonical DB contains shared/app schemas (`superapp/CLAUDE.md:13-15`); Alembic then treats reflected tables absent from metadata as drops (`superapp/apps/focal/server/.venv/lib/python3.14/site-packages/alembic/autogenerate/compare/tables.py:145-175`). Add an `include_name`/equivalent filter so autogenerate/check only sees `focal`.
- `.ai/plans/focal-foundation-plan.md:64-69` says the developer-generated baseline creates the `focal.*` tables, but the task requires `alembic upgrade head` to work on an empty DB (`.ai/tasks/focal-foundation.md:106-109`). The existing local setup creates the schema separately (`superapp/apps/focal/db/init.sql:1-3`), so the plan needs an explicit schema-creation handoff for the baseline or env path.

## Should Consider
- `.ai/plans/focal-foundation-plan.md:59-63` assumes `uv.lock` is stale, but the current lock already has Python `>=3.14` and PyJWT. Verify first and only regenerate if needed to avoid lockfile churn.
- Clarify how DB-backed auth/heal tests run under plain `make verify`; current DB tests skip unless `DATABASE_URL` is in the process environment.

## Tests Reviewed
Read `.ai/tasks/focal-foundation.md`, `.ai/plans/focal-foundation-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, Focal server app/tests, Prima Alembic config, and installed Alembic autogenerate code. No tests run; read-only review.

## Release Risk
High
