# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The plan is scoped correctly and fixes the prior `columns[].focal` selftest gap, but it still leaves one required model mapping field unenforced for the 13 pending ported tables. Because this is part of the binding legacy→`focal.*` mapping contract, it should be explicit in `validate()` and selftest before approval.

## Must Fix
- `.ai/tasks/focal-data-mapping.md:47` defines `model` as `{status, focal_table, phase}` for the 31 ported tables, but `.ai/plans/focal-data-mapping-plan.md:68` only requires `focal_table` for the 18 `modeled` tables and `phase` for the 13 `pending` tables. Add validation and a selftest tamper for missing/empty `model.focal_table` on pending ported tables as well.

## Should Consider
None

## Tests Reviewed
Read-only inspection of `.ai/plans/focal-data-mapping-plan.md`, `.ai/tasks/focal-data-mapping.md`, `.ai/checklists/scoring-rubric.md`, `CONVENTIONS.md`, `_check_routes.py`, `_routes_discovery.py`, `check_routes.sh`, `README.md`, `MIGRATION_PLAN.md`, `focal/shared/schema.ts`, and `superapp/apps/focal/server/app/models/`; verified 39 `pgTable`s and 18 SQLAlchemy `__tablename__` models by read-only commands.

## Release Risk
Low
