# Codex Review Verdict

Score: 8.7 / 10
Status: BLOCKED

## Reason
The task is detailed and most round-7 gaps are now covered, but the stale-link acceptance criteria overstate what is actually specified/tested and leave product/activity deletion behavior ambiguous. That is a Goal-Driven Execution gap because the acceptance line claims broader tested behavior than the concrete test bullets define.

## Must Fix
- `.ai/tasks/focal-calendar-events.md:258` only specifies the stale-link test for deleting a linked `project`, but `.ai/tasks/focal-calendar-events.md:317` expands acceptance to `project/product/activity` and says it is tested. Narrow the acceptance criterion to the verified project case, or add explicit product/activity stale-link semantics and tests. The expected orphan reason also needs case-specific wording, because product/activity stale links do not necessarily imply `"noProject"`.

## Should Consider
- `.ai/tasks/focal-calendar-events.md:147` and `.ai/tasks/focal-calendar-events.md:153` specify create-time timezone sanitization, but the test list only explicitly calls out PATCH timezone sanitization at `.ai/tasks/focal-calendar-events.md:246`. Add an explicit create invalid-timezone assertion if that behavior matters.
- `.ai/tasks/focal-calendar-events.md:72` defines client-writable capped strings like `color` without an over-length validation/error expectation; status is covered, but similar DB-length edge cases could otherwise fall through to raw persistence errors.

## Tests Reviewed
Read `.ai/tasks/focal-calendar-events.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`; spot-checked legacy `focal/server/storage.ts`, `focal/server/routes.ts`, and existing FastAPI task enrichment code for contract context. No tests were run.

## Release Risk
Medium
