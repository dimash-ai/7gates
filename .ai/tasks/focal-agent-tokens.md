# Goal

Port the focal AI-agent **token lifecycle** (Phase 8, slice 1 of the `foc_` agent API): the
`ai_agent_tokens` model + migration + JWT-authed token CRUD under `/api/ai-agent/tokens`. The raw
`foc_<64hex>` token is shown **once** at create / rotate; only its SHA-256 hash is stored. The
X-Focal-Token agent auth + the scoped `/v1/*` data endpoints + webhooks + iCal are later slices.
Legacy: `ai-agent.ts:44-355`, `schema.ts:1646`.

# Scope

- **`app/models/agent_token.py`** — `AiAgentToken` (`ai_agent_tokens`), extends `Base` (NOT
  `TimestampMixin` — the legacy has `created_at` + `last_used_at`, **no** `updated_at`): String uuid
  PK; `user_id` (String, indexed — the JWT `sub`, plain like every other focal table, **not** a FK to
  `users`; the legacy FK + CASCADE is dropped, since identity is Supabase); `name` (String(100)); `token_hash`
  (Text, **unique**); `scopes` (Text, default the all-scopes string); `webhook_url` / `webhook_secret`
  / `webhook_fail_count` (SmallInt default 0) / `ical_token_hash` (Text, unique) — **modeled but unused
  here** (deferred to the webhook / iCal slices, for table + ETL fidelity); `type` (SmallInt default 1
  = user); `expires_at` (tz-aware, nullable); `created_at` (tz-aware, default `utcnow`); `last_used_at`
  (tz-aware, nullable). Unique: `(user_id, name)`, `token_hash`, `ical_token_hash`.
- **Migration** — the new `ai_agent_tokens` table, created + reviewed in-slice; register
  `AiAgentToken` in `app/models/__init__.py` so Alembic + `create_all` see it.
- **`app/domain/agent_token.py`** — `VALID_SCOPES = ("events:read","tasks:read","tasks:write",
  "goals:read","budgets:read")`, `DEFAULT_SCOPES` (all, space-joined), `AGENT_NAME_RE`
  (`^[A-Za-z0-9_-]+$`); `generate_agent_token() -> (raw, hash)` (`raw = "foc_" + secrets.token_hex(32)`,
  `hash = sha256(raw)`); `hash_agent_token(raw)`; `normalize_scopes(str) -> str` (each token ∈
  `VALID_SCOPES`, else raise).
- **`app/services/agent_tokens.py`** — `AgentTokensService`: `create(user_id, payload)` (validate name
  + scopes + expiry, enforce the **per-user cap of 20** (`ConflictError` at the cap), generate, insert;
  `(user, name)` dup → `ConflictError`; returns the raw token once); `list_tokens(user_id)` (no hash /
  secret / raw); `rotate(user_id, name)` (replace `token_hash` with a new raw token + reset
  `created_at` / `last_used_at`, returns the new raw — the old token no longer hashes to a stored
  value; 404 if missing); `rename(user_id, name, new_name)` (404 missing, 409 if the new name is taken);
  `update_scopes(user_id, name, scopes)`; `delete(user_id, name)`. All tenant-scoped to the JWT user.
- **`app/schemas/agent_token.py`** — `AgentTokenCreate` (`name` regex + ≤ 100, `scopes?` validated,
  `expiresAt?` a `datetime` — null = no expiry, otherwise must be in the **future** and **≤ 2 years**
  out, else 422),
  `AgentTokenRead` (id, name, scopes, webhookUrl, type, expiresAt, createdAt, lastUsedAt — **never** the
  hash / secret), `AgentTokenCreated` (= `AgentTokenRead` + `token`), `AgentTokenScopesUpdate`,
  `AgentTokenRename`.
- **`app/api/agent_tokens.py`** — `/api/ai-agent` router; `POST /tokens` (→ 201, raw token once),
  `GET /tokens`, `POST /tokens/{name}/rotate` (→ raw token), `PATCH /tokens/{name}` (scopes),
  `PATCH /tokens/{name}/rename`, `DELETE /tokens/{name}` (→ 204). Registered in `app/main.py`.
- **Tests.**

# Decisions (design rulings to confirm at Gate 1)

- **JWT-authed** — the **user** manages their own tokens (the X-Focal-Token *agent* auth is slice B).
  Tenant = the JWT `sub` = `user_id`; every read/mutation is scoped to it (404 cross-tenant).
- **Raw token shown once** (create + rotate); only the SHA-256 hash is stored, so a DB compromise does
  not leak active tokens. `list` / read responses **never** include the hash, secret, or raw.
- **`name`** matches `AGENT_NAME_RE` and is ≤ 100; `(user, name)` is unique → `ConflictError` (409).
  **`scopes`** — each space-separated token ∈ `VALID_SCOPES`, else 422; absent → `DEFAULT_SCOPES`.
- **Per-user cap of 20** (`MAX_AGENT_TOKENS_PER_USER`) — `create` rejects the 21st token with
  `ConflictError` (409). **`expiresAt`** — `null` = no expiry; otherwise a valid future datetime
  ≤ 2 years out (else 422).
- **`webhook_url` / `webhook_secret` / `ical_token_hash` are modeled but not settable here** (deferred
  to the webhook + iCal slices) — present for table/ETL fidelity. `type` defaults 1 (user).
- **No `updated_at`** (the legacy table has only `created_at` + `last_used_at`) — explicit columns, not
  `TimestampMixin`.
- Typed `AppError`; camelCase; `create`/`rotate` return the one-time token; `DELETE` → 204. Migration
  created + reviewed in-slice.

# Out of scope

- The X-Focal-Token agent auth + scope **enforcement** + the `/v1/*` data endpoints (slice B); webhook
  delivery + SSRF validation; iCal alias tokens; rate-limiting (Redis); the `ai_agent_logs` audit
  table; the `{ok,…}` agent response envelope (decided with the data endpoints). React UI; ETL.

# Acceptance criteria

- [ ] `POST /api/ai-agent/tokens` creates a token, returns the raw `foc_<64hex>` **once** + the
      metadata; a duplicate `(user, name)` → 409; an invalid `name` (regex / length) or an unknown
      scope → 422; no `scopes` → the default all-scopes set.
- [ ] A 21st token for the same user (the per-user cap of 20) → 409.
- [ ] `expiresAt` in the past or > 2 years out → 422; a valid future `expiresAt` ≤ 2 years is accepted;
      no `expiresAt` → no expiry.
- [ ] `GET /api/ai-agent/tokens` lists the caller's tokens **without** the hash / raw / secret.
- [ ] `POST /tokens/{name}/rotate` returns a **new** raw token (old hash replaced, so the old token no
      longer hashes to a stored value); a missing name → 404.
- [ ] `PATCH /tokens/{name}` updates scopes (validated → 422 on bad); `PATCH /tokens/{name}/rename`
      renames (409 if the target name is taken); `DELETE /tokens/{name}` → 204; each → 404 for a
      missing or another user's token.
- [ ] Tenant isolation (a user only sees / mutates their own tokens); `make verify` green; the
      migration applies (`alembic upgrade head`) and `alembic check` is clean.

# Verification commands

```sh
make verify
docker exec focal-local-postgres-1 psql -U focal -d focal_dev -c "DROP SCHEMA IF EXISTS focal CASCADE; CREATE SCHEMA focal; DROP TABLE IF EXISTS public.alembic_version;"
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic upgrade head
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```
