# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly verifiable, but it leaves security and ownership ambiguities that can produce incompatible "passing" implementations. The JWT verifier criteria are missing issuer validation, and the Alembic baseline responsibility is unclear.

## Must Fix
- `.ai/tasks/focal-foundation.md:29-36` defines JWT validation with `alg`, `audience`, `exp`, and `sub`, but omits issuer validation; `.ai/tasks/focal-foundation.md:81-83` and `.ai/tasks/focal-foundation.md:100-103` also omit wrong/missing issuer tests. A verifier can pass this task while accepting a token not issued for the configured Supabase Auth project.
- `.ai/tasks/focal-foundation.md:65-68` says hand-writing/hand-editing migrations is out of scope but that the generated baseline "is committed"; `.ai/tasks/focal-foundation.md:94-96` and `.ai/tasks/focal-foundation.md:116-119` require a developer-run autogenerate/upgrade/check flow. Clarify whether Claude must generate and commit the baseline migration or only make config sufficient for a human to do so.
- `.ai/tasks/focal-foundation.md:33-35` says unknown-`kid` refresh happens "off the request path," while `.ai/tasks/focal-foundation.md:84-88` requires the same request to accept the rotated token if refresh returns the key. Clarify whether this is awaited in-request threadpool work with a timeout or asynchronous background refresh with the first rotated request rejected.

## Should Consider
- `.ai/tasks/focal-foundation.md:39-46` says the shadow user row is upserted from JWT claims but mandates `ON CONFLICT DO NOTHING`; clarify which columns persist and whether later email/tier claim changes should update the row.
- `.ai/tasks/focal-foundation.md:97-99` should specify DB/Redis health-check timeout budgets so `/health` cannot hang on a dead dependency.
- `.ai/tasks/focal-foundation.md:100-104` should explicitly test missing required `exp`/`sub`, startup JWKS warm failure behavior, and PII-free logging.

## Tests Reviewed
Read-only review only. Inspected `nl -ba .ai/tasks/focal-foundation.md`, `nl -ba .ai/checklists/scoring-rubric.md`, and `nl -ba CLAUDE.md`; no implementation tests run.

## Release Risk
Medium
