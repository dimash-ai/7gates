# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The suite covers the main CRUD, tenant isolation, destructive cascades, error envelope, and `make verify` is green, but several acceptance-critical paths remain unverified. The biggest gap is that the supplied verification does not exercise the hand-authored Alembic CHECK-drop migration.

## Must Fix
- `superapp/apps/focal/server/Makefile:14-18` runs ruff, format, mypy, and pytest, but no `alembic upgrade head` or `alembic check`; meanwhile DB tests build from `Base.metadata.create_all` (`tests/test_models_db.py:86-92`). A broken committed migration could pass this test run.
- `superapp/apps/focal/server/tests/test_projects_db.py:133-147` only proves product create inherits parent fields when body values are omitted. Add coverage that explicit child `projectType`/`sphere`/`isWorkTime`/`color` override different parent values.
- `superapp/apps/focal/server/tests/test_spheres_db.py:158-174` covers update self-exclusion and exact duplicate rejection, but not fuzzy-similar rejection on update. Add a PATCH near-name case asserting `similar_sphere_name` and `error.details.similar_names`.

## Should Consider
- `tests/test_projects_db.py:212-219` only tests updating to a valid `projectType`; add an invalid PATCH case to pin `invalid_project_type`.
- `tests/test_errors.py:71-78` is mostly tautological class-constant coverage; endpoint-level assertions carry more value.
- Read tests at `tests/test_projects_db.py:227-245` often call `.json()` without asserting status first.

## Tests Reviewed
Inspected the focal-spheres-projects test files, services/schemas, Makefile, and the supplied `make verify` result: 160 passed, 2 pre-existing warnings. Did not rerun tests in the read-only sandbox.

## Release Risk
Medium
