# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The plan is largely aligned with the actual FastAPI scaffold, uses correct existing paths, calls out the check-constraint migration risk, and maps most acceptance criteria to focused tests. It misses one explicit verification requirement from the task: the no-PII/no-raw-error-path review and grep are not included in the plan's tests or verification commands.

## Must Fix
- `.ai/tasks/focal-spheres-projects.md:161` requires verifying every business error path uses typed `AppError` and that no token/email/name is logged via code review plus grep, but `.ai/plans/focal-spheres-projects-plan.md:99`-`.ai/plans/focal-spheres-projects-plan.md:122` and `.ai/plans/focal-spheres-projects-plan.md:168`-`.ai/plans/focal-spheres-projects-plan.md:176` do not include that verification step. Add the explicit grep/code-review command or checklist item, especially because the legacy sphere delete path logs project names.

## Should Consider
- `.ai/plans/focal-spheres-projects-plan.md:162` mentions an Alembic `include_name` filter, but the actual code uses `_include_object` in `superapp/apps/focal/server/alembic/env.py:17`. Not blocking, but fix the wording so the plan matches the codebase.
- Consider explicitly stating whether the new spheres/projects service dependencies will support the existing no-`DATABASE_URL` in-memory dev mode, since `app/api/tags.py:15`-`app/api/tags.py:24` currently does.

## Tests Reviewed
Plan review only; no tests run. Inspected `.ai/tasks/focal-spheres-projects.md`, `.ai/plans/focal-spheres-projects-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, relevant FastAPI models/routers/services/errors/tests, Alembic baseline/env, contract-freeze route/table entries, and legacy `routes.ts`/`storage.ts`/`utils/fuzzy.ts`.

## Release Risk
Medium
