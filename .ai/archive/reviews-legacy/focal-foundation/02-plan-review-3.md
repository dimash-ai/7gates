# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The plan is broadly aligned with the backend foundation work, but it leaves concrete verification and regression gaps. In particular, it retires demo auth server-side without planning the current client's Bearer-token transition, and `make verify` can pass while DB-backed acceptance paths are skipped.

## Must Fix
- Plan the client auth handoff, or explicitly change the task scope. The task says Focal's client consumes the shared session and attaches the Bearer token (`.ai/tasks/focal-foundation.md:70-72`), but the current client still sends `X-Demo-User-Id` (`superapp/apps/focal/client/src/api/tags.ts:17-25`, `superapp/apps/focal/client/src/api/tags.ts:62-81`) and tests assert that demo header (`superapp/apps/focal/client/src/api/tags.test.ts:37-47`). The plan only lists server/test files and says backend-only (`.ai/plans/focal-foundation-plan.md:29-53`, `.ai/plans/focal-foundation-plan.md:138-141`), so slice 4 would make the existing Tags page 401.
- Make DB-backed acceptance tests non-skippable in the stated verification path. The plan says DB-backed heal/tags tests skip without `DATABASE_URL` and relies on `.env`/shell (`.ai/plans/focal-foundation-plan.md:113-115`), while existing DB tests read `os.getenv` directly (`superapp/apps/focal/server/tests/test_tags_db.py:30-33`, `superapp/apps/focal/server/tests/test_models_db.py:49-52`) and the task's commands do not export `DATABASE_URL` (`.ai/tasks/focal-foundation.md:124-130`). As written, `make verify` can go green without proving heal concurrency/upsert behavior.
- Fix the verify harness dependency story. Dev tools are currently optional extras (`superapp/apps/focal/server/pyproject.toml:20-26`, `superapp/apps/focal/server/uv.lock:267-289`), but the plan's Makefile uses plain `uv run ruff`, `uv run mypy`, and `uv run pytest` after plain `uv sync --frozen` (`.ai/plans/focal-foundation-plan.md:59-63`). The plan should either move dev tools into a uv dev dependency group or invoke them with the needed extra so a fresh checkout can actually run `make verify`.

## Should Consider
- Specify the JWKS fetch timeout mechanism explicitly, not just the high-level timeout requirement, because `PyJWKClient` is synchronous and the task is strict about never blocking the event loop.

## Tests Reviewed
Read `.ai/tasks/focal-foundation.md`, `.ai/plans/focal-foundation-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, Focal server/client auth call sites, server tests, pyproject/lock metadata, and relevant superapp auth/shell docs. No tests were run; this was a read-only plan review.

## Release Risk
Medium
