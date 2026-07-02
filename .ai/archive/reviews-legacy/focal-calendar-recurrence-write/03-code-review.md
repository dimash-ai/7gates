# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
The recurrence write implementation matches most of the legacy contract and the scoped update/delete behavior is well covered. One correctness gap remains: the `following` split path can create an invalid new master with `endTime <= startTime`, violating the task’s validation requirement.

## Must Fix
- `superapp/apps/focal/server/app/services/calendar.py:350` calls `_new_master_from_occurrence` for a following split, and `superapp/apps/focal/server/app/services/calendar.py:447`-`448` writes the picked `start_time`/`end_time` into the new master without the effective-time validation used by `_apply_event_update` (`:290`-`:297`) and `_update_single` (`:375`-`:380`). A PATCH such as `recurrenceScope=following&occurrenceDate=2026-01-18` with `startTime` after the existing `endTime` can persist an invalid event instead of returning `validation_error`.

## Should Consider
- Add a focused DB test for following-split effective time validation, since current validation tests cover scope/date/nulls but not this split-specific path.

## Tests Reviewed
Inspected `tests/test_calendar_recurrence_db.py`, `tests/test_recurrence_unit.py`, and `tests/test_contracts.py`; reviewed developer-reported `make verify` green with 390 passed and clean `uv run alembic check`. Did not rerun tests in the read-only sandbox.

## Release Risk
Medium
