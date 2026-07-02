# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The suite covers the core RBAC matrix, participant lookup, non-participant/unknown-role denial, DB cascade, table creation, and downgrade paths. Two acceptance-specific assertions are still too weak and would let concrete regressions through.

## Must Fix
- `tests/test_rbac_db.py` only asserts `SHARED_CALENDAR_ROLES` and `ROLE_RANK` agree with each other; adding a seventh role to both would still pass, so the test does not actually lock "exactly the 6 roles."
- `tests/test_migration.py` only checks two participant indexes; dropping the required shared-calendar `user_id`/`filter_type`/`google_calendar_id` indexes or participant `user_id`/`email` indexes would still pass.

## Should Consider
- `tests/test_migration.py` could assert the cascade belongs specifically to `shared_calendar_participants.shared_calendar_id -> focal.shared_calendars.id`, rather than matching any `ON DELETE CASCADE` in the emitted SQL.

## Tests Reviewed
Inspected `tests/test_rbac_db.py`, `tests/test_migration.py`, the task/plan, `app/rbac.py`, `app/models/shared_calendar.py`, and the shared-calendar migration. Reviewed the reported `make verify` 458 passed; did not rerun in the read-only sandbox.

## Release Risk
Medium
