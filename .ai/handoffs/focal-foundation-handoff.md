# Stage

Stage 5 — final release review for the `focal-foundation` feature
([task](../tasks/focal-foundation.md) · [plan](../plans/focal-foundation-plan.md)). Cumulative
change: `c6297f4..HEAD` on `feature/focal-migration` (slices 1–5).

# What changed

Phase 0 of the Focal migration — a verifiable, migratable FastAPI walking skeleton with real
Supabase authentication — built in five gated slices on top of the existing scaffold:

1. **`make verify` harness** — dev tools moved to a PEP 735 `[dependency-groups] dev`; committed
   `uv.lock`; `Makefile` (`verify` = ruff + ruff format + mypy + pytest, brings up local
   Docker Postgres/Redis and exports their URLs); scaffold brought into ruff/mypy conformance.
2. **Alembic (async, `focal.*`)** — `alembic.ini` + `env.py` with an `include_name` filter scoped to
   the `focal` schema (autogenerate can never `DROP` other apps' tables in the shared DB) and a
   `CREATE SCHEMA IF NOT EXISTS focal` so `upgrade head` works on an empty DB; `script.py.mako`.
   (The baseline migration is developer-authored — see "Still needs review".)
3. **Auth spine** — `app/auth.py`: local Supabase **ES256** JWT verification against the cached JWKS
   key (no per-request network; alg/audience/issuer pinned; `exp`/`iss`/`sub` required; bounded,
   threadpool-awaited key fetch; **fail-closed** on any error; `app_metadata`-only tier). `focal.users`
   shadow table (id == JWT `sub`, no cross-schema FK) + inline, idempotent, best-effort identity heal.
   Startup JWKS warm (non-fatal).
4. **Demo→real swap** — real auth is the default request path; the `X-Demo-User-Id` bypass survives
   only behind `DEMO_AUTH_ENABLED` (off by default). `deps.get_current_user_id` delegates to the real
   verifier.
5. **`/me` + `/health`** — read-only `GET /me` (authenticated principal); lifespan warms JWKS; each
   `/health` probe is timeout-bounded so a dead dependency surfaces as an `"error"` flag instead of
   stalling.

# Files touched

27 files under `apps/focal/server/` (+1836 / −56). New: `Makefile`, `alembic.ini`,
`alembic/env.py`, `alembic/script.py.mako`, `alembic/versions/.gitkeep`, `uv.lock`, `app/auth.py`,
`app/api/me.py`, `app/models/users.py`, `tests/test_auth.py`, `tests/test_me.py`. Modified:
`pyproject.toml`, `Dockerfile`, `.env.example`, `app/config.py`, `app/db.py`, `app/deps.py`,
`app/main.py`, `app/api/health.py`, `app/api/tags.py`, `app/models/__init__.py`, `app/schemas/tags.py`,
`tests/{test_health,test_tags,test_tags_db,test_models_db,conftest}.py`.

# Tests run

```sh
cd superapp/apps/focal/server && make verify   # docker compose up + ruff + mypy + pytest
```

# Verification output

```sh
All checks passed!                              # ruff check + ruff format --check
Success: no issues found in 32 source files     # mypy app
======================= 114 passed, 2 warnings in 5.36s ========================
```

(The 2 warnings are a Starlette/httpx deprecation and pyjwt's short-HMAC-key note from a negative
"wrong-alg" test — neither is a failure.)

# Still needs review

- **Deliberate deferral — client Bearer attach.** Focal's React client still sends `X-Demo-User-Id`;
  the real shared-session token comes from the host/shell (AUTH_FLOWS.md / SHELL_CONTRACT.md), which
  isn't built yet, and the env-gated demo bypass keeps local dev working. The client has no
  `node_modules` here, so client changes couldn't be verified — deferred to shell integration.
- **Developer-authored Alembic baseline.** Per root CLAUDE.md, agents don't write migration files;
  this slice lands the config + import-complete models. The developer runs
  `alembic revision --autogenerate`, reviews, and commits the baseline.
- **Non-blocking (gate-test):** a Redis-probe-timeout test mirroring the DB one; restoring the tags
  `get_current_user_id` overrides for order-independence.
- Look hardest at: the auth verifier's fail-closed paths and `app_metadata`-only tier handling.

# PR / release notes (for users)

**Focal backend foundation — real Supabase auth on the superapp stack.**

The Focal FastAPI service now:

- **Authenticates real users** by verifying Supabase **ES256** JWTs locally against the cached JWKS
  public key — no per-request network call — with the algorithm, audience, and issuer pinned and any
  verification failure rejected (never failing open). A user's AI tier is read only from the
  server-controlled `app_metadata` claim.
- **Persists user identity** in a local `focal.users` profile row, healed best-effort on first
  authenticated request (a DB hiccup never fails the request).
- Exposes **`GET /me`** (the signed-in principal) and a **`GET /health`** that reports DB and Redis
  liveness via bounded probes and never hangs on a dead dependency.
- Runs on the canonical stack — Python 3.14, FastAPI on Granian, SQLAlchemy 2.0, PyJWT — with the
  `focal.*` schema managed by Alembic and a single `make verify` (lint + types + 114 tests) gating it.

No user-facing UI changes ship in this PR; this is backend foundation. No secrets, tokens, keys, or
PII appear in this description.

# Status

CODEX APPROVED (9.1 / 10) — final gate cleared for release.

---
Do not continue implementation until Codex review is complete.
