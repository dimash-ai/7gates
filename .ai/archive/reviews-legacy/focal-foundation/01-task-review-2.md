# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly well-scoped, but key auth/security behaviors are not made verifiable enough for a foundation slice. A Claude implementation could pass the listed acceptance criteria while still trusting user-controlled metadata, rejecting valid rotated Supabase keys, or racing identity healing.

## Must Fix
- `.ai/tasks/focal-foundation.md:31-32` requires tier/authz to read only `app_metadata`, never `user_metadata`, but `.ai/tasks/focal-foundation.md:88-90` has no acceptance test proving `user_metadata.tier` is ignored. This is security-relevant because a user-controlled metadata tier could accidentally grant elevated access while still passing the task.
- `.ai/tasks/focal-foundation.md:33-35` describes key-rotation handling, but `.ai/tasks/focal-foundation.md:76-79` and `.ai/tasks/focal-foundation.md:88-90` only require the unresolved unknown-`kid` rejection path. Add a success criterion/test for unknown `kid` where the bounded JWKS refresh returns the new key and the valid rotated token is accepted.
- `.ai/tasks/focal-foundation.md:39-43` says identity healing never blocks the response, while `.ai/tasks/focal-foundation.md:80-82` requires the `focal.users` row to be created on the first authed request. Define the timing/observability contract clearly, especially for concurrent first requests and tests.

## Should Consider
- Clarify the Alembic artifact boundary: `.ai/tasks/focal-foundation.md:62-63` says migration files are out of scope, but `.ai/tasks/focal-foundation.md:84-86` requires `upgrade head` and `alembic check`. Say whether the generated baseline revision is committed or only used as local verification.
- Clarify `/health` expected flag names and behavior when DB or Redis is unavailable; `.ai/tasks/focal-foundation.md:25` and `.ai/tasks/focal-foundation.md:87` only define the happy path.

## Tests Reviewed
Read `.ai/tasks/focal-foundation.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md` with line numbers. No runtime tests run; this was a task-definition review only.

## Release Risk
High
