# Codex Review Verdict

Score: 9.3 / 10
Status: APPROVED

## Reason
The round-1 blocker is fixed: `_new_master_from_occurrence` now validates the merged effective `start_time`/`end_time` before constructing the split master. The implementation matches the task and approved plan across scope resolution, single overrides, following splits, delete semantics, typed errors, and tenant-scoped group deletion.

## Must Fix
None

## Should Consider
Add explicit regression coverage for update-following on an excepted/soft-deleted target and delete-following on a soft-deleted target; the code paths appear correct, but the current tests mostly pin the excepted delete-following variant.

## Tests Reviewed
Inspected `tests/test_calendar_recurrence_db.py`, including `test_following_split_rejects_invalid_effective_times`; inspected `tests/test_recurrence_unit.py`, `tests/test_contracts.py`, and existing `tests/test_calendar_db.py`. Reviewed the reported `make verify` green result and clean `uv run alembic check`; not rerun in this read-only sandbox.

## Release Risk
Medium
