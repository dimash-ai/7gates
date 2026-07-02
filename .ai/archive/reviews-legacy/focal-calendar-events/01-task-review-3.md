# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The task definition is much stronger after round 3 and the prior hierarchy/PATCH-null gaps are addressed. One contract-sensitive behavior is still not backed by explicit test/acceptance coverage, which weakens Goal-Driven Execution.

## Must Fix
- `.ai/tasks/focal-calendar-events.md:116-119` specifies malformed list-query `startDate`/`endDate` must fall back to the default window, but the test/acceptance bullets at `.ai/tasks/focal-calendar-events.md:218-219` and `.ai/tasks/focal-calendar-events.md:265-266` only require date-window/default-window coverage, not an explicit malformed-query case. Add an explicit test/acceptance item for malformed `startDate` and/or `endDate` returning the default window, not `422`.

## Should Consider
- Clarify POST explicit-null semantics for defaulted NOT NULL optional fields like `status`, `completed`, `tags`, and `contactIds` (`.ai/tasks/focal-calendar-events.md:130-136`). PATCH null handling is precise, but create-time null behavior is left to inference.
- Clarify whether PATCH blank `title` should be rejected like create blank title, or allowed for legacy parity (`.ai/tasks/focal-calendar-events.md:130`, `.ai/tasks/focal-calendar-events.md:150-155`).

## Tests Reviewed
Inspected `.ai/tasks/focal-calendar-events.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`; read legacy `routes.ts`, `storage.ts`, and `schema.ts` for context only. No tests run because this was a task-definition review.

## Release Risk
Medium
