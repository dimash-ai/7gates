# Codex Review Verdict

Score: 8.3 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly measurable, but it has a few contract-level ambiguities that can send the implementation to the wrong observable behavior for scoped recurring mutations. The riskiest gaps are target-date precedence, the exact `all` date-reset condition, and unresolved-occurrence semantics for `following`.

## Must Fix
- `.ai/tasks/focal-calendar-recurrence-write.md:20` and `.ai/tasks/focal-calendar-recurrence-write.md:58` say an occurrence-id date wins over `occurrenceDate`, but the cited legacy resolver uses `options.occurrenceDate ?? parsed.occurrenceDate`. Clarify the intended precedence and add an acceptance test for conflicting occurrence-id/query dates.
- `.ai/tasks/focal-calendar-recurrence-write.md:67` describes the `all` moved-override date reset too broadly and only for occurrence ids. Legacy resets only when `updates.date == currentOccurrence.event.date != master.date`, and it is keyed off any resolved target occurrence date. This needs exact wording and a focused test.
- `.ai/tasks/focal-calendar-recurrence-write.md:39`, `.ai/tasks/focal-calendar-recurrence-write.md:91`, and `.ai/tasks/focal-calendar-recurrence-write.md:97` conflict on whether `following` DELETE must validate that the target occurrence actually resolves before truncating. Clarify whether this intentionally diverges from legacy and test excepted/soft-deleted targets.

## Should Consider
- `.ai/tasks/focal-calendar-recurrence-write.md:156` says the new master has the “same recurrenceGroupId”; make the assertion explicit as `recurrence_group_id(new_master) == recurrence_group_id(original_master)` so legacy/imported rows with a null stored group id are not misread.
- `.ai/tasks/focal-calendar-recurrence-write.md:49` calls `previous_occurrence` the inverse of `advance_occurrence`; monthly/yearly clamp behavior is not a true inverse. Prefer exact examples matching the legacy date-fns behavior.

## Tests Reviewed
No tests run; task-definition review only. Inspected `.ai/tasks/focal-calendar-recurrence-write.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and the cited legacy recurrence mutation snippets for contract comparison.

## Release Risk
Medium
