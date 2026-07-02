# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The suite is broad and the recorded verification is green, but one tenant-isolation acceptance path is not actually tested. The activity-link tests say they cover non-owned activity links, but they only pass a missing ID, so a cross-tenant `activityId` regression would not be caught.

## Must Fix
- `apps/focal/server/tests/test_tasks_db.py:400` and `apps/focal/server/tests/test_tasks_db.py:608` only test `activityId="no-such-activity"`, not an activity row owned by another user, despite `.ai/tasks/focal-tasks-tags.md:226`-`229` requiring another user's `activityId` to return `related_record_not_found` with no leak. Seed a `focal.activities` row for `user-b` and assert create/update by `user-a` reject it.

## Should Consider
- Add a positive seeded owned-activity case if owned `activityId` is intended to be storable before the activities CRUD vertical lands.
- Strengthen `test_date_window_explicit_range_and_malformed_fallback` to assert out-of-range dated tasks are excluded for the explicit range, not only that the in-range task is included.
- Add tag PATCH validation cases for blank `name`/`color` and over-long `name`; current tests cover create and some patch validation but not the full PATCH rules.

## Tests Reviewed
Read `.ai/runs/focal-tasks-tags-verify.txt`: `ruff check`, `ruff format --check`, `mypy app`, `pytest` with 260 passed, plus `alembic upgrade head` and `alembic check` with no new operations. Inspected `test_tasks_db.py`, `test_priority.py`, `test_daterange.py`, `test_completion.py`, `test_contracts.py`, `test_tags.py`, `test_tags_db.py`, the task file, and the relevant implementation diff.

## Release Risk
Medium
