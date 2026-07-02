# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
Verification is green and the added DB tests cover most of the risky calendar slice, but several explicit acceptance criteria are not actually pinned by tests. The gaps are test-coverage issues rather than proven implementation defects, but they leave important contract and PATCH behavior under-verified.

## Must Fix
- `superapp/apps/focal/server/tests/test_contracts.py:287-290` adds only the event 404 check, and does not assert the full `{code,message}` envelope; `.ai/plans/focal-calendar-events-plan.md:172` and `.ai/tasks/focal-calendar-events.md:279` require event contract coverage for 404/422/400. Add calendar `validation_error` and `related_record_not_found` contract tests with the full envelope shape.
- `superapp/apps/focal/server/tests/test_calendar_db.py:151-160` creates an event and immediately reads `.json()` without asserting the required HTTP 200; `.ai/tasks/focal-calendar-events.md:305-306` says create returns 200 and is tested. Add a status assertion so an accidental 201 or other success code cannot pass.
- `superapp/apps/focal/server/tests/test_calendar_db.py:370-380` only verifies `startTime` normalization, while `.ai/tasks/focal-calendar-events.md:326-327` requires `startTime` and `endTime` zero-padding on create and PATCH. Add `endTime` normalization assertions for both create and patch.
- `superapp/apps/focal/server/tests/test_calendar_db.py:408-428` covers nullable clearing with `location=None` only, but `.ai/tasks/focal-calendar-events.md:185-190` and `.ai/tasks/focal-calendar-events.md:320-322` require nullable link clearing for `projectId`/`productId`/`activityId`. Add at least one link-clear PATCH test that verifies recomputed priority and orphaned enrichment.

## Should Consider
- Add `noProduct` orphan coverage for an event on a parent project with products but no `productId`; `.ai/tasks/focal-calendar-events.md:216-218` calls this out, while current enrichment tests cover product-present and `noProject` only.
- Add product-specific negative cases: non-owned `productId`, non-owned product enrichment, and activity-only fallback through `activity.product_id`.
- Add validation cases for `contactIds` and non-string list elements, not just `tags="notalist"` at `superapp/apps/focal/server/tests/test_calendar_db.py:359-361`.

## Tests Reviewed
Captured `.ai/runs/focal-calendar-events-verify.txt`: `make verify` passed ruff, ruff format check, mypy, and pytest with 318 passed; separate `alembic upgrade head` and `alembic check` showed no drift. Also inspected `git -C superapp --no-pager diff --cached` plus `test_calendar_db.py`, `test_contracts.py`, `test_migration.py`, the task, and the plan.

## Release Risk
Medium
