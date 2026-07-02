# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
The suite is broad and behavior-focused, but two acceptance-critical recurrence paths are not actually proven. Both gaps would let realistic regressions pass while still reporting green.

## Must Fix
- `superapp/apps/focal/server/tests/test_calendar_recurrence_db.py:607` claims to cover date-reset for a moved occurrence, but it never seeds a moved override; it only uses an unoverridden generated occurrence. This would not catch a regression that compares `payload.date` to `target_date` instead of the resolved occurrence date.
- `superapp/apps/focal/server/tests/test_calendar_recurrence_db.py:507` covers following-split title/group/truncation, but never sends/asserts recurrence-rule payload on the new master. A regression dropping `recurrence` or `recurrenceEndDate` during `_new_master_from_occurrence` would pass.

## Should Consider
- Add DELETE-side coverage for master-id default `all`, `occurrenceDate` param precedence, and bad `recurrenceScope`/`occurrenceDate`; current scope/default tests are mostly PATCH-only.
- Add explicit delete-single 404 coverage for excepted/soft-deleted targets.
- Strengthen delete-following override pruning with a DB or post-extension assertion; current list assertions can pass even if future overrides remain stored.
- PATCH validation mostly checks statuses; assert `validation_error` for bad `occurrenceDate` and explicit-null recurrence fields too.

## Tests Reviewed
Inspected `test_calendar_recurrence_db.py`, `test_recurrence_unit.py`, `test_contracts.py`, the task, approved plan, and relevant implementation files. Reviewed the reported `make verify` green result with 393 passed; did not rerun in the read-only sandbox.

## Release Risk
Medium
