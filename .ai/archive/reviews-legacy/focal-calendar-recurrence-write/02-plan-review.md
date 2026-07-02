# Codex Review Verdict

Score: 8.2 / 10
Status: BLOCKED

## Reason
The plan is well aligned with the task and legacy behavior overall, but it has a few concrete planning defects that can lead to failed intermediate gates or wrong recurring-group behavior after splits. The highest-risk issues are narrow and fixable.

## Must Fix
- `.ai/plans/focal-calendar-recurrence-write-plan.md:87` says slice 1 adds recurrence fields to `EventUpdate` while keeping existing behavior/tests green, but current update logic blindly applies every update field at `superapp/apps/focal/server/app/services/calendar.py:223`, and the current test expects recurrence PATCH fields to be ignored at `superapp/apps/focal/server/tests/test_calendar_recurrence_db.py:363`. Move that schema change into the UPDATE scope slice or explicitly strip recurrence fields until the scoped all/following branch is implemented.
- `.ai/plans/focal-calendar-recurrence-write-plan.md:20` defines `recurrence_group_id(recurrence, recurring_event_id, event_id)` but also requires returning the stored group id. The actual field is `superapp/apps/focal/server/app/models/calendar.py:56`; without accepting the event or stored `recurrence_group_id`, a second split from an already-split master will incorrectly create a new group.
- `.ai/plans/focal-calendar-recurrence-write-plan.md:46` uses `recurrence_end_date = data ?? master's`, which conflicts with explicit-null clearing called out at `.ai/plans/focal-calendar-recurrence-write-plan.md:31`. The plan must specify key-presence semantics: omitted means inherit, explicit `null` means clear/open-ended.

## Should Consider
- Make the DELETE-all predicate explicitly tenant-scoped. `.ai/plans/focal-calendar-recurrence-write-plan.md:55` names only `recurrence_group_id == gid OR id == gid`; line 68 says all paths are tenant-scoped, but destructive group deletes should spell out `user_id == user_id` and include a cross-tenant same-group-id regression test.
- `.ai/plans/focal-calendar-recurrence-write-plan.md:132` promises a typed 500 for arbitrary mid-write exceptions, but the app currently only registers handlers for `AppError` and `RequestValidationError` in `superapp/apps/focal/server/app/main.py:27`. Either remove that promise or explicitly plan the wrapper behavior.

## Tests Reviewed
Inspected `.ai/tasks/focal-calendar-recurrence-write.md`, `.ai/plans/focal-calendar-recurrence-write-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, target calendar service/schema/domain/routes/models, recurrence DB/unit/contract tests, and legacy `focal/server/storage.ts` + `focal/server/utils/recurrence.ts`. Did not run tests; this was a read-only plan review.

## Release Risk
Medium
