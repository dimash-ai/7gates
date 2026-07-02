# Codex Review Verdict

Score: 9.1 / 10
Status: APPROVED

## Reason
The task definition is tightly scoped, security-conscious, and has concrete acceptance criteria covering auth failure modes, JWKS rotation, health checks, Alembic configuration, and verification commands. Remaining gaps are clarifications rather than blockers.

## Must Fix
None

## Should Consider
- `.ai/tasks/focal-foundation.md:47` could clarify whether `focal.users.id` is only value-equal to `auth.users.id` or should declare a database foreign key; this matters for the empty-DB Alembic verification at `.ai/tasks/focal-foundation.md:107`.
- `.ai/tasks/focal-foundation.md:43` and `.ai/tasks/focal-foundation.md:94` require a typed `AuthRequiredError` response but do not name the exact `error.code` / `message`; tests may need to infer that from external docs.
- `.ai/tasks/focal-foundation.md:53` and `.ai/tasks/focal-foundation.md:120` say logs must contain no PII, but the task could explicitly define whether `sub` / user UUID counts as PII.

## Tests Reviewed
Inspected `.ai/tasks/focal-foundation.md`, `.ai/checklists/scoring-rubric.md`, and root `CLAUDE.md`. No tests run; this was a task-definition review only.

## Release Risk
Low
