# Codex Review Verdict

Score: 9.1 / 10
Status: APPROVED

## Reason
The plan is aligned with the actual Focal scaffold and task: it accounts for the existing lockfile, optional dev deps, demo auth removal, client Bearer handoff, async Alembic setup, JWKS behavior, heal semantics, and health hardening. Scope is large but split into independently green slices, with risky migration/data-loss paths explicitly called out.

## Must Fix
None

## Should Consider
- `.ai/plans/focal-foundation-plan.md:55` and `.ai/plans/focal-foundation-plan.md:102-108`: define the concrete `getAccessToken()` host-session adapter shape, since `superapp/docs/SHELL_CONTRACT.md:35-40` defines module mounting but not a token handoff API.
- `.ai/plans/focal-foundation-plan.md:68-72`: consider `docker compose --wait` or an explicit readiness probe; the compose file has healthchecks (`superapp/apps/focal/docker-compose.yml:27-41`) and DB tests connect during setup (`superapp/apps/focal/server/tests/test_models_db.py:86-93`).
- `.ai/plans/focal-foundation-plan.md:43-45` and `.ai/plans/focal-foundation-plan.md:99-101`: make the config change explicitly flip/rename the current default demo flag, because `superapp/apps/focal/server/app/config.py:21` currently enables demo auth by default.

## Tests Reviewed
Not run; this was a read-only plan/codebase review. Inspected the task, plan, rubric, root and superapp CLAUDE docs, auth/shell docs, Focal server/client scaffold, existing tests, docker-compose, env examples, and PRIMA Alembic reference.

## Release Risk
Medium
