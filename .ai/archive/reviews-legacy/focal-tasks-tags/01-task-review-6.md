# Codex Review Verdict

Score: 8.8 / 10
Status: BLOCKED

## Reason
The task definition is detailed and mostly measurable, but one public API edge is under-specified enough to let implementations violate the stated error-envelope contract. The scope is otherwise well bounded and acceptance criteria are strong.

## Must Fix
- `.ai/tasks/focal-tasks-tags.md:92-93` defines malformed `:id` behavior only for `GET /api/tasks/:id`; `.ai/tasks/focal-tasks-tags.md:112-130` and `.ai/tasks/focal-tasks-tags.md:161-173` do not specify malformed-id behavior for task PATCH/DELETE or tag PATCH/DELETE. In FastAPI, typed path params can otherwise produce the default 422 response, conflicting with the typed `{error:{code,message}}` contract at `.ai/tasks/focal-tasks-tags.md:42-50` and `.ai/tasks/focal-tasks-tags.md:246-247`.

## Should Consider
- `.ai/tasks/focal-tasks-tags.md:164-173` does not pin the exact tag response shape for list/create/update, despite requiring legacy parity; add fields/status expectations if contract tests should enforce them.
- `.ai/tasks/focal-tasks-tags.md:164-170` validates tag `name` length but only says `color` is non-blank; specify color length or typed handling for too-long values so DB constraint failures do not escape the error envelope.

## Tests Reviewed
Read `.ai/tasks/focal-tasks-tags.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`. No tests run; this was a read-only task-definition review.

## Release Risk
Medium
