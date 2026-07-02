# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The staged tests cover the main recurrence expansion, override, validation, and migration paths, and the supplied verification is green. However, two load-bearing read-path requirements remain unpinned: endpoint responses do not assert synthetic occurrence identity, and `GET /api/events/:occurrenceId` is not tested with a non-deleted override applied.

## Must Fix
- `superapp/apps/focal/server/tests/test_calendar_recurrence_db.py:277` verifies a synthetic occurrence lookup but never asserts the returned `id` is `"{masterId}__occurrence__2026-01-17"`; `.ai/tasks/focal-calendar-recurrence-read.md:201` requires occurrences carry the synthetic id, `occurrenceDate`, and `isRecurringInstance=true`.
- `superapp/apps/focal/server/tests/test_calendar_recurrence_db.py:277` tests `GET` by occurrence id only without an override, while `.ai/tasks/focal-calendar-recurrence-read.md:164` requires the single occurrence be returned “with override applied.” Add a seeded non-deleted override and assert overridden fields on the `GET` response.

## Should Consider
- `superapp/apps/focal/server/tests/test_migration.py:81` says “six recurrence columns” but `superapp/apps/focal/server/tests/test_migration.py:82` only checks four; include `recurrence_exceptions` and `recurrence_group_id`.
- Add a list assertion for normal, non-overridden virtual occurrences that checks `id`, `recurringEventId`, `occurrenceDate`, and `isRecurringInstance`; current date-only checks would miss returning the master row shape for the first occurrence.
- Add edge tests for `GET` occurrence ids after `recurrenceEndDate` and before the master start date if the intended legacy contract is truly “any parseable date builds unless excepted/deleted.”
- Recurrence-specific 404/422 tests mostly assert status only; add at least one recurrence validation and one synthetic not-found error-envelope assertion for `error.code`.

## Tests Reviewed
Inspected `.ai/runs/focal-calendar-recurrence-read-verify.txt` showing `make verify` green: ruff, format, mypy, pytest `356 passed`; also inspected separately-run `alembic upgrade head` plus `alembic check` with no drift. Ran `git -C superapp --no-pager diff --cached` and reviewed `tests/test_recurrence_unit.py`, `tests/test_calendar_recurrence_db.py`, `tests/test_contracts.py`, and `tests/test_migration.py`.

## Release Risk
Medium
