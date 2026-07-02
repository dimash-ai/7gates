# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly well-scoped, but the read/write boundary is not clean enough for implementation. There is also a contract conflict between “legacy source is binding” and the specified `GET` behavior for synthetic occurrence ids.

## Must Fix
- `.ai/tasks/focal-calendar-recurrence-read.md:15-16` makes the cited legacy source authoritative, but `.ai/tasks/focal-calendar-recurrence-read.md:113-116` requires `GET` on an out-of-series synthetic occurrence to return `not_found`; legacy `focal/server/storage.ts:3807-3819` builds a parsed occurrence without checking cadence/start/end. Clarify whether this is an intentional hardening or the legacy behavior must be preserved.
- `.ai/tasks/focal-calendar-recurrence-read.md:85-89` references `recurringEventId` during create, while `.ai/tasks/focal-calendar-recurrence-read.md:159-160` says child-row writing is out of scope and the port creates only masters. Specify whether `POST` must reject, ignore, or persist `recurringEventId`, `recurrenceGroupId`, and `old_logic`.
- `.ai/tasks/focal-calendar-recurrence-read.md:125-130` says `PATCH`/`DELETE` continue on stored rows, but the slice is “schema + create + read” and recurrence mutations are deferred. Specify whether `PATCH` may update recurrence fields on a master, or require those fields to remain absent/ignored/rejected in `EventUpdate`, with a test.

## Should Consider
- `.ai/tasks/focal-calendar-recurrence-read.md:26-30` and `.ai/tasks/focal-calendar-recurrence-read.md:50-56` should spell out migration safety for existing `calendar_events` rows when adding defaulted/non-null columns, especially `old_logic`.
- Pin legacy occurrence-id normalization/tolerant parsing from `focal/server/utils/recurrence.ts:96-126`, or explicitly reject the legacy double-wrapper tolerance.
- Add acceptance coverage for override-on-excepted-date precedence and yearly Feb-29 recurrence.

## Tests Reviewed
No tests run; task-only review. Inspected `.ai/tasks/focal-calendar-recurrence-read.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and cited legacy schema/storage/recurrence snippets.

## Release Risk
Medium
