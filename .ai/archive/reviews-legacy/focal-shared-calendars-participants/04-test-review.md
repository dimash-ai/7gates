# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The tests cover nearly all participant and join acceptance criteria, and the reported `make verify` is green. One core RBAC acceptance case is not pinned: a non-owner accepted viewer listing participants.

## Must Fix
- `GET /{id}/participants` success is only exercised as `"owner"`; `test_list_requires_viewer` only checks stranger 403 + missing 404. Add a DB-backed assertion that an accepted non-owner viewer can list participants; otherwise changing the endpoint from viewer+ to owner-only would still pass.

## Should Consider
- The join contract pins top-level keys + participant shape, but not the returned `calendar` shape; assert the join calendar uses the `SharedCalendarRead` camelCase key set.

## Tests Reviewed
Inspected `test_shared_calendar_participants_db.py`, `test_invite_code.py`, `test_contracts.py`, the task, plan, rubric, and participant/join implementation. Ran `pytest tests/test_invite_code.py` (2 passed); reviewed the reported `make verify` green (503 passed); did not rerun the DB suite in the read-only sandbox.

## Release Risk
Medium
