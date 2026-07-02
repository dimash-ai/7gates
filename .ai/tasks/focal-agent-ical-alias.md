# Goal

Port the **iCal-alias credential lifecycle** (Phase 8, iCal slice 2a): `POST`/`DELETE
/api/ai-agent/tokens/{name}/ical-token` — issue / revoke a calendar-feed alias on an existing `foc_`
token. The alias is a **second, independent credential** (its sha256 is stored in the modeled
`ical_token_hash`); it authenticates the read-only iCal feed (the consuming `GET /v1/calendar.ics`
endpoint is the next slice). Legacy: `ai-agent.ts:628-684`.

# Scope

- **`app/domain/agent_token.py`** (modify) — `generate_ical_alias() -> tuple[str, str]`: `raw =
  secrets.token_hex(32)` (64 hex, **no** `foc_` prefix — it is a distinct credential), `hash =
  hash_agent_token(raw)` (reuse the SHA-256 helper).
- **`app/services/agent_tokens.py`** (modify) — `create_ical_alias(user_id, name) -> str` (`_require`
  the token by `(user_id, name)` → 404 if missing/cross-tenant; generate the alias; set
  `ical_token_hash`; commit; return the **raw** once) and `revoke_ical_alias(user_id, name) -> None`
  (`_require`; set `ical_token_hash = None`; commit).
- **`app/schemas/agent_token.py`** (modify) — `IcalAliasCreated` (`_Camel`): `ical_token` (the raw,
  shown once) + `ical_url` (the feed URL).
- **`app/api/agent_tokens.py`** (modify) — on the token router (JWT-authed, user manages own):
  - `POST /tokens/{name}/ical-token` → 200 `IcalAliasCreated`; `ical_url = f"{request.base_url}api/
    ai-agent/v1/calendar.ics?ical_token={raw}"`; emit `ICAL_TOKEN_CREATED` (info) after success.
  - `DELETE /tokens/{name}/ical-token` → 204; emit `ICAL_TOKEN_REVOKED` (info) after success.
- **`app/agent_logging.py`** (modify) — add `ICAL_TOKEN_CREATED` / `ICAL_TOKEN_REVOKED` → `info`.
- **Tests** (extend `tests/test_agent_tokens_db.py`).

# Decisions (design rulings to confirm at Gate 1)

- **The alias is independent of the `foc_` token** — a separate 64-hex secret, sha256-stored in
  `ical_token_hash` (modeled-but-unused until now), returned **once**. It does **not** carry scopes (the
  feed it authenticates is a fixed read-only calendar export). `POST` issues or **re-issues** (rotates)
  it; `DELETE` revokes it (null → the old feed URL stops working).
- **JWT-authed management** — `user_id` = the JWT `sub`; `404` (`NotFoundError`) when the named token
  doesn't exist or belongs to another user (matching the token-CRUD `_require`).
- **`POST` → 200** (issue/re-issue, like `rotate`), **`DELETE` → 204**. The standard `{error:{code}}`
  envelope on failure (these are JWT management endpoints, not the agent `/v1` surface).
- **Audit at the router, success-only** (`ICAL_TOKEN_CREATED`/`REVOKED`, info) via the best-effort
  `log_agent_event`, exactly like the other control-plane token events.

# Out of scope

- The **feed** itself — `GET /v1/calendar.ics?ical_token=`, the alias auth (sha256 vs `ical_token_hash`),
  the `CalendarEvent` → `IcalEvent` mapping, and the `text/calendar` response — the next slice (2b),
  which consumes this alias + the shipped serializer. Webhooks; the Redis rate-limit backend.

# Acceptance criteria

- [ ] `POST /tokens/{name}/ical-token` for an owned token → 200 with `icalToken` (64-hex, returned once)
      + `icalUrl` (`…/api/ai-agent/v1/calendar.ics?ical_token=<raw>`); the row's `ical_token_hash` equals
      `sha256(icalToken)` (the raw is **not** stored); one `ICAL_TOKEN_CREATED` audit row.
- [ ] A second `POST` **rotates** the alias — a new `icalToken`, and the stored hash changes (the old
      raw no longer hashes to the stored value).
- [ ] `DELETE /tokens/{name}/ical-token` → 204; `ical_token_hash` becomes null; one `ICAL_TOKEN_REVOKED`
      audit row. **Idempotent:** a `DELETE` on an owned token whose alias is already null still → 204 +
      one `ICAL_TOKEN_REVOKED` (the token exists, so it is a successful revoke).
- [ ] `POST`/`DELETE` on a missing or another user's token → 404 with **no** audit row and no hash
      change; an **unauthenticated** `POST`/`DELETE` → 401 (`auth_required`) with no audit row.
- [ ] `make verify` green; no migration.

# Verification commands

```sh
cd superapp/apps/focal/server && DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev make verify
```
