# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.2 / 10
Status: APPROVED

## Reason
The 4a (frontend-only over existing fields) / 4b (developer-owned recurrence + multi-participant migration, then wire) split is minimum-viable and correctly sequenced; verified the backend gap (single `contact_id`, no `recurrence`/`other_participants`), the old-focal binding behaviors (recurrence select, CRM/Other toggle, inline tag-create, schedule-as-event→delete, info-dialog actions), and the slice-2 reuse (`calendarId` threading, `canEdit` guards, `compareTasksForDisplay`, quick-add to demote) — all match. 4a correctly avoids faking backend fields and deliberately omits `contactId` from updates to preserve existing values, failure modes are named per-page, and each test states what it proves.

## Must Fix
None

## Should Consider
- Field-name slip: the plan's 4a.2 and `scheduleAsEvent` test say the event payload carries `displayTimezone`, but the actual `EventCreate` field is `timezone` — `displayTimezone` is the value returned by `useTimezone()`. Server `extra="ignore"` would silently drop a `displayTimezone` key. Map `timezone: <displayTimezone>` at build.
- Schedule-as-event time mapping is under-specified: `EventCreate` requires `date` + `startTime` (+ optional `endTime`), not `dueDate`/`dueTime`. Pin the `date`/`startTime`/`endTime` mapping (incl. any `endTime` default) against old-focal `Tasks.tsx`'s `onScheduleAsEvent` at build.
- The `tasksFilters.load` test asserts a stored `all` preset "softens to `thisMonth` only when no other filter is active" — not traced to an old-focal source line; cite the source (or drop it) at build.

## Tests Reviewed
N/A

## Release Risk
Low
