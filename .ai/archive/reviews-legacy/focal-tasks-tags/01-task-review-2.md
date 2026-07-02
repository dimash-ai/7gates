# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly bounded, but it contains conflicting contract language that would let implementation and tests diverge. The biggest risks are incorrect query parameter support and contradictory handling of client-supplied fields.

## Must Fix
- `.ai/tasks/focal-tasks-tags.md:74` defines list query params as `startDate`/`endDate`, but `.ai/tasks/focal-tasks-tags.md:162` and `.ai/tasks/focal-tasks-tags.md:199` require tests/acceptance for `from`/`to`. Clarify the exact public query names before implementation.
- `.ai/tasks/focal-tasks-tags.md:24` and `.ai/tasks/focal-tasks-tags.md:219` say unknown request fields are ignored, but `.ai/tasks/focal-tasks-tags.md:212` says create rejects `status`/`completed`/`eventId` inputs. Decide whether those fields are ignored, stripped with no effect, or return a validation error.
- `.ai/tasks/focal-tasks-tags.md:48` says `eventId` is stored without validation, while `.ai/tasks/focal-tasks-tags.md:91`, `.ai/tasks/focal-tasks-tags.md:110`, and `.ai/tasks/focal-tasks-tags.md:185` say `eventId` is not client-settable and event linking is out of scope. Remove or qualify the `eventId` storage requirement.

## Should Consider
- Define allowed values and error behavior for `priority` and `status`; they are writable at `.ai/tasks/focal-tasks-tags.md:89` and `.ai/tasks/focal-tasks-tags.md:109`, but invalid-value handling is not specified.
- Add acceptance coverage that `tasks.tags` array elements are strings, not just that the value is an array, to match `.ai/tasks/focal-tasks-tags.md:66`.

## Tests Reviewed
Read `.ai/tasks/focal-tasks-tags.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`. No test commands were run; this was a task-definition review only.

## Release Risk
Medium
