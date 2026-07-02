# Codex Review Verdict

Score: 7.6 / 10
Status: BLOCKED

## Reason
The plan is mostly aligned with the task and actual paths, and it calls out the migration and destructive cascade risks. It still misses concrete changes required for the existing test suite and underspecifies the typed validation/error-envelope implementation against the current FastAPI app.

## Must Fix
- `.ai/plans/focal-spheres-projects-plan.md:40` and `.ai/plans/focal-spheres-projects-plan.md:72-80` remove the work-time/sphere CHECK, but the plan does not include updating the existing `superapp/apps/focal/server/tests/test_models_db.py:245-250`, which currently expects that exact invariant to raise `IntegrityError`. `make verify` runs pytest with DB URLs exported from `superapp/apps/focal/server/Makefile:14-18`, so this is a planned test break.
- `.ai/tasks/focal-spheres-projects.md:25-32` requires typed error envelopes, including `error.details.similar_names` and `invalid_project_type`; the current handler only returns `code` and `message` at `superapp/apps/focal/server/app/errors.py:49-53`, and the app only registers `AppError` at `superapp/apps/focal/server/app/main.py:25-29`. The plan promises request validation mapping at `.ai/plans/focal-spheres-projects-plan.md:115-116` but does not explicitly add `RequestValidationError` handling or detail serialization, and `.ai/plans/focal-spheres-projects-plan.md:44` relying on a Pydantic `Literal` would normally produce generic request validation before a service can raise `invalid_project_type`.

## Should Consider
- Clarify FastAPI route declaration order for static routes like `/api/projects/root` before dynamic `/{id}`; the plan introduces get-by-id before reads at `.ai/plans/focal-spheres-projects-plan.md:72-82`, which is easy to implement in an order that shadows `/root`.
- Add `superapp/apps/focal/server/tests/test_models_db.py` to the file list explicitly, including its stale docstring/import expectations around the removed invariant.

## Tests Reviewed
Read `.ai/tasks/focal-spheres-projects.md`, `.ai/plans/focal-spheres-projects-plan.md`, `.ai/checklists/scoring-rubric.md`, root `CLAUDE.md`, `app/models/projects.py`, `app/models/life_spheres.py`, `app/errors.py`, `app/main.py`, `app/api/tags.py`, `app/services/tags.py`, `tests/test_models_db.py`, and `Makefile`. No tests were run; this was a read-only plan review.

## Release Risk
Medium
