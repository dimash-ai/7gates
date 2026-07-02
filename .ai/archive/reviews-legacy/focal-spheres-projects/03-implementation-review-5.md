# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The staged slice is narrowly scoped and mostly matches the legacy create/update/delete/get contract, including tenant scoping and the CHECK-drop direction. It is blocked by one create-path validation hole and a concrete migration downgrade naming bug.

## Must Fix
- `apps/focal/server/app/services/projects.py:41` uses truthiness for `project_type` resolution, so `projectType: ""` is accepted by `ProjectCreate` and silently falls back to inherited/default `"provision"` instead of raising `invalid_project_type`. This violates the `project_type ∈ {"mission","provision"}` invariant and the legacy/task nullish `body ?? parent ?? default` behavior; resolve with `is not None` before `_validate_project_type`.
- `apps/focal/server/alembic/versions/2026_06_03_1000-d4f1a2b3c4e5_drop_work_time_sphere_check.py:29` recreates an already conventioned CHECK name without `op.f(...)`. With the app naming convention, Alembic emits `ck_projects_ck_projects_work_time_sphere`, so downgrade does not restore the constraint name that `upgrade()` drops at line 24.

## Should Consider
- Apply the same nullish-vs-truthy care to create-time inherited fields such as `color` for exact legacy fidelity, though only `project_type` currently breaks a stated invariant.

## Tests Reviewed
`git -C superapp --no-pager diff --cached`; `git -C superapp status`; inspected `.ai` task/plan/rubric and legacy `routes.ts:3621-3794`; ran pytest on unit tests (8 passed); verified Alembic naming output with an offline `Operations.create_check_constraint` command.

## Release Risk
Medium
