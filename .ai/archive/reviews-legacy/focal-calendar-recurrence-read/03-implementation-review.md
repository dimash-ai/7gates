# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The slice is mostly faithful and well covered, but the override merge misses a user-visible legacy field. That makes overridden occurrences return stale `updatedAt`, which is part of the API response and the legacy merge contract.

## Must Fix
- `apps/focal/server/app/services/calendar.py:274`-`282`: `_build_occurrence` starts from the master event and copies only `_OVERRIDE_FIELDS`, so an overridden occurrence keeps the master's `updated_at`. Legacy `buildRecurringEventInstance` uses the master `createdAt` but the override `updatedAt` for overridden occurrences (`focal/server/storage.ts:3296`-`3297`). Add the override timestamp merge and a test that an overridden occurrence returns the override's `updatedAt`.

## Should Consider
- `apps/focal/server/app/services/calendar.py:107` and `249`-`258`: list expansion loads all overrides for every matching master instead of bounding overrides to the requested occurrence window as the plan and legacy path do. This does not change current output because lookups are by generated in-window occurrence dates, but it can become unnecessarily expensive for long-running series with many overrides.

## Tests Reviewed
Inspected `git -C superapp --no-pager diff --cached`, `git -C superapp status`, `.ai/plans/focal-calendar-recurrence-read-plan.md`, `.ai/tasks/focal-calendar-recurrence-read.md`, `.ai/checklists/scoring-rubric.md`, legacy recurrence/storage/schema files, and `.ai/runs/focal-calendar-recurrence-read-verify.txt` showing `make verify` green: ruff, format, mypy, pytest 354 passed, plus alembic upgrade head and check clean.

## Release Risk
Medium
