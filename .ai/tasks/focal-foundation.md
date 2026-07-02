# Goal

Stand up Focal's FastAPI backend as a verifiable, migratable walking skeleton on the canonical
superapp stack, with **real Supabase authentication** replacing the demo stub. After this slice every
later Focal feature builds on a proven foundation: real users authenticate (Supabase ES256 JWT,
verified locally), their profile persists, the `focal.*` schema is managed by Alembic, and
`make verify` is green.

This is Phase 0 of [superapp/apps/focal/docs/MIGRATION_PLAN.md](../../superapp/apps/focal/docs/MIGRATION_PLAN.md).
It consolidates the plan's `focal-foundation` + `focal-auth-spine` slice IDs (§9 calls them "rough;
split further as needed") because auth is the load-bearing part of the foundation. The toolchain
realignment (PyJWT, Python 3.14, dep floors, ES256 naming) already landed; this slice builds on it.

> **Paths in this task are relative to the pipeline root** (where `.ai/` lives). The Focal service is
> at `superapp/apps/focal/server`; within-server paths like `app/deps.py` are relative to that dir.

# Scope

**Foundation infra**

- Commit the first lockfile: `uv sync` on Python 3.14 → commit `superapp/apps/focal/server/uv.lock`
  (root CLAUDE.md: the first install commits the lockfile; CI later runs `--frozen`).
- Add a `Makefile` so `make verify` = ruff (lint + format check) + mypy + pytest (mirrors prima; the
  plan and root CLAUDE.md both reference `make verify`).
- Configure Alembic for **async** against the `focal.*` schema (`alembic.ini` + `env.py` mirroring
  `superapp/apps/prima/server/alembic/`), with `app/models/__init__.py` importing every model so
  autogenerate sees them.
- Confirm `/health` returns 200 with `db` + `redis` connectivity flags (R2 `not_applicable` for now).

**Auth spine (replaces the demo stub)**

- Author a Focal-local auth module that verifies Supabase **ES256** JWTs locally against the cached
  JWKS public key (PyJWT): no per-request network call in steady state; JWKS warmed at startup (a
  startup warm failure is logged but **non-fatal** — the first auth request lazily fetches via the same
  bounded path); `alg` pinned to ES256, `audience="authenticated"`, issuer pinned to
  `{SUPABASE_URL}/auth/v1` with `SUPABASE_URL`'s trailing slash normalized (both `…supabase.co` and
  `…supabase.co/` validate) — reject any other issuer; `require=[exp, iss, sub]`. Reads `sub`, `email`,
  `app_metadata.tier` (defaults to `free`). Authz reads `app_metadata` only, never `user_metadata`. On
  an unknown `kid` (key rotation) the verifier performs **one** bounded JWKS refresh **awaited within
  the request via a threadpool with a timeout** (config `SUPABASE_JWKS_TIMEOUT_S`, default ~2s; the
  async event loop is never blocked): if it returns the key the request is accepted, and if it times
  out / can't resolve the request is rejected with `AuthRequiredError` — never blocking indefinitely,
  never failing open. Failures raise a typed `AuthRequiredError`, never a raw `HTTPException`; no token
  contents or PII in logs. Contract:
  [superapp/docs/AUTH_FLOWS.md](../../superapp/docs/AUTH_FLOWS.md).
- Replace the `X-Demo-User-Id` dependency in `app/deps.py` with the real verifier on the request path.
- Add the `users` **shadow table** model (PK = `auth.users.id`, plus `email`, `created_at`) + a
  best-effort `healUserIdentity` that upserts the local row from JWT claims on the first authed request
  (mirrors legacy Focal; `focal.users.id == auth.users.id`). The row is **identity/profile continuity
  only** — it does **not** store `tier` (tier/authz always read from the JWT per request), so
  `ON CONFLICT DO NOTHING` is intentional (no claim re-sync on the shadow row). The upsert runs
  **synchronously and inline** and is **idempotent**, so concurrent first-requests neither duplicate
  the row nor error. It is **best-effort**: a DB failure is caught and logged (structured, no PII) and
  the request still returns successfully with identity from the verified claims — heal never turns a
  valid request into a 5xx. (Inline, not fire-and-forget, so "the row exists after the first authed
  response" is deterministic and testable.)
- Add a read-only `/me` endpoint returning the authenticated user's `id` / `email` / `tier`.

# Out of scope

- **All domain features** — MindMap/goals/projects/tasks, calendar, focal-local CRM, Google sync,
  habits/time-budgets/analytics, product dashboard, push (Phases 1–5). Existing models stay as-is; no
  routes/services are added for them here.
- **`settings` endpoints + `user_settings` / `user_onboarding` wiring** — deferred; foundation ships
  only the read-only `/me`.
- **The `DASHBOARD_USER_EMAILS` allow-list** — deferred to the Phase-4 dashboard slice that consumes
  it (building it now is premature build-ahead).
- **The `foc_` agent API and the AI subsystem** (Phase 7).
- **Real-data ETL / migration** (plan §6).
- **Login / signup / reset UI** — per AUTH_FLOWS.md + SHELL_CONTRACT.md the login surface lives in the
  host (PRIMA's PWA / shell), not in Focal. Focal's client only consumes the shared session and
  attaches the Bearer token; no auth screens in `superapp/apps/focal/client`.
- **Extracting `shared/python/auth.py`** — the verifier is authored Focal-local now; shared extraction
  is the "2nd app → shared/" step (SHARED_PACKAGES.md), done later.
- **Generating or committing the Alembic baseline migration** — Claude's deliverable is the Alembic
  config (`alembic.ini` + async `env.py`) + import-complete models **only**. Per root CLAUDE.md the
  **developer** (not the agent) runs `alembic revision --autogenerate`, reviews the SQL, and commits the
  baseline; the `upgrade head` / `alembic check` items below are that developer verification step, not a
  Claude-authored migration file.
- **A permanent demo-auth bypass** — `X-Demo-User-Id` is retired from the request path (it may survive
  only as an explicitly env-gated test fixture, off by default).

# Acceptance criteria

- [ ] `cd superapp/apps/focal/server && uv sync --frozen` succeeds on Python 3.14; `uv.lock` is
      committed.
- [ ] `make verify` runs ruff + mypy + pytest and is green.
- [ ] A request bearing a valid Supabase **ES256** JWT (signed by a test key) resolves to the correct
      user; `/me` returns that user's `id` / `email` / `tier`.
- [ ] A token whose **`user_metadata`** carries `tier=internal` while `app_metadata` has no tier
      resolves to `tier=free` — `user_metadata` is never consulted for tier/authz (privilege-escalation
      guard).
- [ ] An expired, malformed, wrong-`alg`, wrong-`aud`, wrong-/missing-`iss`, or missing-`exp`/`sub`
      token yields exactly one typed `AuthRequiredError` (401-shaped `{error:{code,message}}`) — never
      a raw `HTTPException`, never a token value in logs.
- [ ] Auth performs **no per-request network call** under steady state (JWKS cached). On an unknown
      `kid` the verifier performs exactly **one** bounded JWKS refresh awaited in a threadpool with a
      timeout (`SUPABASE_JWKS_TIMEOUT_S`, default ~2s; event loop never blocked): if it returns the
      rotated key, a token signed by it is **accepted on that same request**; if it times out / can't
      resolve, it returns `AuthRequiredError` — never blocking indefinitely, never failing open.
- [ ] On the first authed request for a new user the heal **synchronously** creates a `focal.users` row
      with `id == auth.users.id` (deterministically present after that response); concurrent/repeat
      requests neither duplicate it nor error (idempotent `ON CONFLICT`); and if the upsert fails the
      request still returns 200 with `/me` serving the verified claims.
- [ ] `X-Demo-User-Id` no longer authenticates a request on the normal path.
- [ ] Alembic config (async `env.py` targeting `focal.*`) + import-complete models are in place such
      that the **developer-run** `alembic revision --autogenerate` produces a baseline creating every
      defined `focal.*` table, `alembic upgrade head` applies cleanly to an empty DB, and `alembic
      check` reports no drift. (This is developer verification of the config + models — not a
      Claude-authored migration file.)
- [ ] `/health` returns 200 with a JSON body carrying `db` and `redis` flags (`"ok"` when reachable,
      `"error"` when not) plus `r2: "not_applicable"`; each probe has a short timeout (~1s) so it never
      hangs on a dead dependency, and it stays 200 even when a dependency is down (orchestration reads
      the flags, not the HTTP code).
- [ ] New tests cover: valid-token → user; `user_metadata.tier` ignored → `free`;
      expired / malformed / wrong-alg / wrong-aud / wrong-or-missing-iss / missing-exp-or-sub →
      `AuthRequiredError`; unknown-`kid` + successful bounded refresh → token **accepted**; unknown-`kid`
      + failed refresh → `AuthRequiredError` (no indefinite block, no fail-open); JWKS startup-warm
      failure is non-fatal; heal idempotent on concurrent first-requests + heal-failure-still-serves-
      `/me`; logs carry no token/PII on failure paths; and `/me`.

# Verification commands

```sh
# local-first backing services (Postgres + Redis) for the DB-backed tests
docker compose -f superapp/apps/focal/docker-compose.yml up -d

cd superapp/apps/focal/server
uv sync --frozen
make verify

# developer step (agents don't author migration files):
uv run alembic revision --autogenerate -m "focal baseline"
uv run alembic upgrade head
uv run alembic check
```
