# Codex Review Verdict

Score: 7.4 / 10
Status: BLOCKED

## Reason
The plan is largely aligned with the backend foundation and actual Focal scaffold, and it fixes prior gaps around Alembic safety, DB-backed tests, and client Bearer headers. It is still blocked because the planned client-side "self-generated ES256 token" stopgap conflicts with the real Supabase/session contract and creates a security-shaped implementation path.

## Must Fix
- Replace the planned client token source with a host/shared-session consumption path or a strictly test-only fixture. `.ai/plans/focal-foundation-plan.md:55` and `.ai/plans/focal-foundation-plan.md:96-100` plan `localStorage`/`VITE_*` self-generated ES256 tokens, but the task says Focal's client only consumes the shared session and attaches the Bearer token (`.ai/tasks/focal-foundation.md:70-72`), and the auth contract says Supabase issues the JWT while the client only attaches it (`superapp/docs/AUTH_FLOWS.md:13-23`). A Vite/client-side signing-token path risks exposing signing material or silently replacing real Supabase auth with another demo bypass.

## Should Consider
- Make the verify harness set or test `REDIS_URL` explicitly. The plan's Makefile only exports `DATABASE_URL` (`.ai/plans/focal-foundation-plan.md:35`, `.ai/plans/focal-foundation-plan.md:67-71`), while local Redis is on `6380` (`superapp/apps/focal/docker-compose.yml:33-36`) and the current real health test skips without `REDIS_URL` (`superapp/apps/focal/server/tests/test_health.py:28-31`).
- Clarify whether existing tag routes keep a `get_current_user_id` wrapper or switch to `current_user.id`; the current service path expects a plain `user_id: str` (`superapp/apps/focal/server/app/api/tags.py:27-41`).

## Tests Reviewed
Read `.ai/tasks/focal-foundation.md`, `.ai/plans/focal-foundation-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, superapp auth/shell docs, Focal server/client code, tests, Prima Alembic files, and Focal compose/env files. No tests were run; this was a read-only plan review.

## Release Risk
High
