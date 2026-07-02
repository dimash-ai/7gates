# Review Verdict

Reviewer: Opus
Step: test
Score: 8.7 / 10
Status: BLOCKED

## Reason
The new route-level seed-gate test is a correct, deterministic end-to-end proof and every risky path from the design (delete blast-radius, override/following ranges, FK-injection, meeting-request scoping, closed-partition guard, IDOR) is genuinely asserted; the 13 full-suite failures are proven pre-existing (identical with the new test stashed; suite reproduces 1704/13). But the new test commits `("owner", 2031)` rows that collide with `test_calendar_scope_db.py::test_delegated_time_budget_read_does_not_seed_owner_rows` (which asserts those rows start empty and does not truncate the time-budget tables), making the suite order-fragile — a test-isolation Must Fix.

## Must Fix
- `apps/focal/server/tests/test_time_budgets_db.py` (`test_route_get_seeds_only_for_own_data_not_delegated_read`): its own-data leg seeds and commits `("owner", 2031)` time-budget settings/categories, the exact `(user="owner", year=2031)` coordinates that the committed `apps/focal/server/tests/test_calendar_scope_db.py:671` (`test_delegated_time_budget_read_does_not_seed_owner_rows`) asserts begin empty (`assert seeded == []`). `test_calendar_scope_db.py`'s truncate fixture (`:144-152`) does not clear `focal.time_budget_settings/categories`, so when the time-budgets file runs first the committed rows poison the calendar_scope assertion. Deterministically reproduced: running the new test before the calendar_scope seed-gate test yields `1 failed, 1 passed`. The natural alphabetical order masks it. Fix by giving the new test a year unique to its file or extending a truncate to cover the shared tables.

## Should Consider
- None.

## Tests Reviewed
- Read in full: the new `test_route_get_seeds_only_for_own_data_not_delegated_read` (uncommitted diff) and its `_override_scope_session`/`_persisted_year_counts` helpers; `test_calendar_scope_db.py` (delete/following/override/FK-injection/seed-gate cases); `test_route_scope_partition.py`; `test_data_scope_db.py` test list; `app/data_scope.py` + `app/api/time_budgets.py`.
- Ran (DATABASE_URL/REDIS_URL test env): new test 3x → 3 passed (deterministic); slice bundle in natural order 4x → 49 passed; `pytest -q` full suite → 1704 passed / 13 failed (matches log); the 13 with the new test stashed → still 13 failed (pre-existing); forced ordering `new-test → calendar_scope seed-gate` → 1 failed, 1 passed (reproduced the collision).

## Release Risk
Low
