# Codex Review Verdict

Score: 9.2 / 10
Status: APPROVED

## Reason
The server diff stays scoped to the spheres/projects backend slice, matches the reconciled legacy contract, and has broad DB-backed coverage for tenant isolation, cascades, error envelopes, camelCase contracts, and the CHECK-drop SQL. No release-blocking correctness, security-text, or test-breaking issue was found.

## Must Fix
None

## Should Consider
- Tenant hardening: `ProjectsService._require/_owned` and `SpheresService._require` load by primary key before checking `user_id` (`apps/focal/server/app/services/projects.py:149`, `apps/focal/server/app/services/spheres.py:72`); behavior is externally protected and tested, but tenant-filtered SELECTs would align more tightly with the root tenant-query policy.
- Record an online `uv run alembic upgrade head` / `uv run alembic check` transcript before deploy; `tests/test_migration.py` covers the hand-authored migration SQL offline.

## Tests Reviewed
Inspected `git -C superapp --no-pager diff e63da0e..HEAD -- apps/focal/server`, `git status`, `--check`. Inspected the test files, the service/schema/API/migration code, legacy route/storage references, and the handoff-reported `make verify` output: ruff/format/mypy green, `167 passed, 2 warnings`.

## Release Risk
Medium
