# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The suite covers the aggregate shape, bookings placeholder, recurrence expansion, null-due task inclusion, event window filtering, malformed-date 200 fallback, tenant isolation, and the init event’s full enriched key set. One acceptance-critical assertion is too weak: the project test does not actually prove the full `ProjectRead` contract.

## Must Fix
- `superapp/apps/focal/server/tests/test_calendar_init_db.py:158`-`167` only asserts an eight-field subset with `<=`, while `ProjectRead` contains the full required response shape at `superapp/apps/focal/server/app/schemas/projects.py:68`-`93`. A light projection containing those eight fields would pass this test, so the “projects carry FULL ProjectRead shape” acceptance criterion is not pinned.

## Should Consider
- `superapp/apps/focal/server/tests/test_calendar_init_db.py:146`-`150` covers an in-window dated task plus a null-due-date task, but not an out-of-window dated task; adding that negative assertion would pin task date-window threading, matching the plan’s events/tasks window coverage.
- `superapp/apps/focal/server/tests/test_calendar_init_db.py:139`-`143` proves basic daily recurrence expansion, but comparing init events to `GET /api/events` for the same window would more directly prove endpoint parity with `list_events`.

## Tests Reviewed
Inspected `.ai/tasks/focal-calendar-init.md`, `.ai/plans/focal-calendar-init-plan.md`, `.ai/checklists/scoring-rubric.md`, `test_calendar_init_db.py`, `test_contracts.py`, `calendar_init` service/API/schema, and `ProjectRead`. Reviewed the reported `make verify` result: 409 passed; did not rerun DB-backed tests in this read-only review.

## Release Risk
Medium
