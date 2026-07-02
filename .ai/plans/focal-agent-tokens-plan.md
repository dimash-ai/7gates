# Summary

Implement `focal-agent-tokens` (Phase 8, slice 1 of the `foc_` agent API): the `ai_agent_tokens` model
+ migration + a pure token domain + JWT-authed token CRUD under `/api/ai-agent/tokens`. The raw
`foc_<64hex>` is shown once; only its SHA-256 hash is stored. Agent auth + `/v1/*` data endpoints +
webhooks + iCal are later slices. Task: [focal-agent-tokens.md](../tasks/focal-agent-tokens.md).
Legacy: `ai-agent.ts:44-355`, `schema.ts:1646`.

## Decisions (design + the Gate-1 rulings)

- **`AiAgentToken` extends `Base`** (not `TimestampMixin`): plain `String` `user_id` (indexed, the JWT
  `sub` — no FK to `users`), `name`, `token_hash` (unique), `scopes`, `webhook_url`/`webhook_secret`/
  `webhook_fail_count`/`ical_token_hash` (modeled, unused this slice), `type` (SmallInt default 1),
  `expires_at`, `created_at` (`utcnow`), `last_used_at`. Unique `(user_id, name)`, `token_hash`,
  `ical_token_hash`. Registered in `app/models/__init__.py`; migration in-slice.
- **`app/domain/agent_token.py`** (pure): `VALID_SCOPES`, `DEFAULT_SCOPES`, `AGENT_NAME_RE`,
  `generate_agent_token() -> (raw, hash)` (`secrets.token_hex(32)`, `hashlib.sha256`),
  `hash_agent_token(raw)`, `normalize_scopes(str) -> str` (raise on an unknown / empty scope).
- **Schema validation** on `AgentTokenCreate`: `name` regex + ≤ 100; `scopes` via `normalize_scopes`
  (422 on bad); `expiresAt` (`datetime`) — null ok, else must be **future** and **≤ 2 years** out
  (a `field_validator` using `datetime.now(UTC)`), else 422.
- **Service** (JWT-authed, tenant = `user_id`): `create` enforces the **per-user cap of 20** (count →
  `ConflictError` at the cap; a count-then-insert soft cap, faithful to the legacy — the rare
  concurrent-create race is acceptable and noted), `(user, name)` dup → `ConflictError`, generates,
  inserts, returns the raw once. `list_tokens` returns `AgentTokenRead` (no hash/secret/raw). `rotate`
  replaces `token_hash` + resets `created_at`/`last_used_at` (the old token no longer hashes to a
  stored value), returns the new raw; 404 missing. `rename` → 404 missing / 409 target taken.
  `update_scopes`, `delete` → 404 missing/cross-tenant.
- **Hash-only storage** — the raw token is never persisted (only its SHA-256). camelCase; typed
  `AppError`; `DELETE` → 204; `create`/`rotate` return the one-time token.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/models/agent_token.py` | add | the `AiAgentToken` model |
| `app/models/__init__.py` | modify | import + export `AiAgentToken` |
| `alembic/versions/<rev>_ai_agent_tokens.py` | add | the new-table migration |
| `app/domain/agent_token.py` | add | scopes + token generation/hash + name regex |
| `app/schemas/agent_token.py` | add | `AgentTokenCreate`/`Read`/`Created`/`ScopesUpdate`/`Rename` |
| `app/services/agent_tokens.py` | add | `AgentTokensService` |
| `app/api/agent_tokens.py` | add | `/api/ai-agent` router |
| `app/main.py` | modify | register the router |
| `tests/test_agent_token.py` | add | domain unit tests (gen/hash/scopes/regex) |
| `tests/test_agent_tokens_db.py` | add | CRUD + cap + expiry + hash-only + tenant tests |
| `tests/test_migration.py` | modify | assert the new table + indexes |

# Implementation slices

1. **Model + registration + migration + domain.** *Verify:* reset → `alembic upgrade head` →
   `alembic check`; domain unit tests.
2. **Schema + service + router + main.** *Verify:* `make verify`.
3. **Tests.** *Verify:* full `make verify` green.

# Tests

- **domain (unit):** `generate_agent_token` → `raw` starts `foc_`, 64 hex chars, `hash == sha256(raw)`,
  two calls differ; `normalize_scopes` accepts valid, raises on unknown/empty; `AGENT_NAME_RE`.
- **create:** returns the raw `foc_…` + metadata once; default scopes when absent; bad name/scope/
  expiry → 422; duplicate `(user, name)` → 409; the **21st** token → 409 (cap); a past / >2yr
  `expiresAt` → 422, a valid future ≤2yr accepted.
- **hash-only:** after create, the DB row's `token_hash` equals `sha256(raw)` and is **not** the raw
  token; the response on `list`/read never contains `tokenHash`/`token`/`webhookSecret`.
- **list:** the caller's tokens without hash/secret/raw; tenant-scoped.
- **rotate:** returns a **new** raw token; the old raw's hash no longer matches the stored row; 404
  missing/cross-tenant.
- **rename:** renames; 409 if the target name is taken; 404 missing/cross-tenant.
- **update scopes / delete:** scopes validated (422 bad); delete → 204; each 404 missing/cross-tenant.
- **migration:** `test_migration.py` asserts `ai_agent_tokens` + the unique `(user_id, name)` /
  `token_hash` indexes.

# Error & rescue map

| failure mode | error | response |
|--------------|-------|----------|
| duplicate `(user, name)` / 21st token | `ConflictError` | 409 |
| rotate / rename / update / delete a missing or other-user token | `NotFoundError` | 404 |
| bad name / scope / past-or-far expiry | Pydantic validation | 422 |
| no auth | `AuthRequiredError` | 401 |

# Risks & migrations

- **Migration** adds `ai_agent_tokens`; `alembic check` clean after.
- **Cap concurrency** — count-then-insert is a soft cap (faithful to the legacy's non-atomic check); a
  simultaneous pair at the boundary could reach 21. Acceptable for this slice; noted.
- **Token secrecy** — only the hash is stored; the raw is returned once and never logged. Pinned by the
  hash-only test.
- **No behavior change** to existing endpoints — additive.

# Scope check

- [x] Matches the task (token model + CRUD; agent auth / data endpoints / webhooks / iCal deferred).
- [x] Reviewable in one pass — 3 sequenced slices, each green.
- [x] Size smell: one model + one migration + a pure domain + service + router + tests.

# Out of scope

X-Focal-Token agent auth + scope enforcement + `/v1/*` (slice B); webhooks; iCal; rate-limiting;
`ai_agent_logs`; the React UI; ETL.
