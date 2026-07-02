# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The suite covers most requested bookings behavior, including CRUD basics, strict containment, tenant status responses, owned-link rejection, calendar-init inclusion, and the direct `BookingRead` shape. One acceptance-critical tenant-safety test is too weak: it proves cross-tenant PATCH/DELETE return 404, but not that they leave the other tenant's booking untouched.

## Must Fix
- `tests/test_bookings_db.py` `test_by_id_ops_are_tenant_scoped` only asserts 404 for cross-tenant get/patch/delete. Add owner-side assertions after the rejected PATCH and DELETE proving the foreign booking still exists and its fields are unchanged; otherwise a regression could mutate/delete another tenant's booking and still pass by returning 404.

## Should Consider
- `test_create_and_get_booking` should assert denormalized `product` too, not just `project`/`projectType`/`tags`.
- The PATCH happy-path only proves `title`/`color`; add a richer mutable-field PATCH case (dates, tags, product/projectType, owned link).
- The malformed-date fallback tests conflate malformed input with a missing opposite bound; pass a valid opposite bound to prove malformed input itself falls back.
- The init bookings test should compare to `BookingRead`/direct `/api/bookings`, not just title.

## Tests Reviewed
Inspected the task, approved plan, rubric, bookings + calendar-init service/schema/API, and the three test files. Reviewed the reported `make verify` result of 431 passed; did not rerun Docker-backed verify in the read-only sandbox.

## Release Risk
Medium
