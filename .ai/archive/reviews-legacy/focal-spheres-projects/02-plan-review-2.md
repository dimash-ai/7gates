# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
The plan is largely aligned with the task and actual FastAPI scaffold, and the listed paths mostly exist or are correct additions. It is blocked because the test matrix omits explicit acceptance criteria from the task.

## Must Fix
- Add explicit planned tests for sphere rename no-cascade. The task requires this behavior to be tested at `.ai/tasks/focal-spheres-projects.md:143`, but the plan's test list at `.ai/plans/focal-spheres-projects-plan.md:101`-`118` covers duplicate/fuzzy/cascade only and never verifies existing projects keep their stored `sphere` after a sphere rename.
- Add an explicit planned test for budget position auto-compute. The task requires this at `.ai/tasks/focal-spheres-projects.md:149`, but the plan's `test_projects_db` scope at `.ai/plans/focal-spheres-projects-plan.md:60` and test matrix at `.ai/plans/focal-spheres-projects-plan.md:109`-`116` do not name that case.

## Should Consider
- Clarify the stale schema-table wording at `.ai/plans/focal-spheres-projects-plan.md:50`: it says `project_type` is constrained in the schema, while `.ai/plans/focal-spheres-projects-plan.md:27`-`29` and `:73`-`74` correctly say the schema must accept `str` so the service can raise `invalid_project_type`.

## Tests Reviewed
Read-only review only; no tests run. Inspected the task, plan, rubric, `CLAUDE.md`, FastAPI scaffold, models, Alembic env/baseline, existing tests, legacy `routes.ts`/`storage.ts`/`fuzzy.ts`, and contract-freeze route/table inventories.

## Release Risk
Medium
