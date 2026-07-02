# Summary

Implement `focal-agent-ical-alias` (Phase 8, iCal slice 2a): `POST`/`DELETE
/api/ai-agent/tokens/{name}/ical-token` — issue / revoke an independent calendar-feed alias on a `foc_`
token, sha256-stored in `ical_token_hash`, returned once. JWT-authed; the consuming `/v1/calendar.ics`
feed is the next slice. No schema change. Task:
[focal-agent-ical-alias.md](../tasks/focal-agent-ical-alias.md). Legacy: `ai-agent.ts:628-684`.

## Decisions (design + the Gate-1 rulings)

- **`app/domain/agent_token.py`** (modify) — `generate_ical_alias() -> tuple[str, str]`: `raw =
  secrets.token_hex(32)` (64 hex, **no** `foc_` prefix), `return raw, hash_agent_token(raw)`.
- **`app/services/agent_tokens.py`** (modify):
  - `create_ical_alias(user_id, name) -> str`: `token = await self._require(user_id, name)` (404
    missing/cross-tenant); `raw, h = generate_ical_alias()`; `token.ical_token_hash = h`; `commit`;
    return `raw`. (Plain commit — an `ical_token_hash` collision is random-256-bit, not a user-driven
    race, so no `_commit_unique` needed.)
  - `revoke_ical_alias(user_id, name) -> None`: `token = await self._require(...)`; `token.ical_token_hash
    = None`; `commit`. Idempotent — null→null on an owned token is still a successful revoke.
- **`app/schemas/agent_token.py`** (modify) — `IcalAliasCreated(_Camel)`: `ical_token: str`, `ical_url:
  str` (camelCase out: `icalToken`/`icalUrl`).
- **`app/api/agent_tokens.py`** (modify):
  - `POST /tokens/{name}/ical-token` (`response_model=IcalAliasCreated`, default 200) — `raw = await
    service.create_ical_alias(user_id, name)`; `await log_agent_event("ICAL_TOKEN_CREATED",
    user_id=user_id, agent_name=name)`; `ical_url = f"{request.base_url}api/ai-agent/v1/calendar.ics?
    ical_token={raw}"`; return `IcalAliasCreated(ical_token=raw, ical_url=ical_url)`. Adds `request:
    Request`.
  - `DELETE /tokens/{name}/ical-token` (204) — `await service.revoke_ical_alias(user_id, name)`; `await
    log_agent_event("ICAL_TOKEN_REVOKED", …)`; `return Response(status_code=status.HTTP_204_NO_CONTENT)`.
  - Imports: `Request` (fastapi), `IcalAliasCreated`. Audit is **after** the awaited service call
    (success-only — a 404 raises first), like the other control-plane events.
- **`app/agent_logging.py`** (modify) — add `ICAL_TOKEN_CREATED` / `ICAL_TOKEN_REVOKED` → `info`.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/domain/agent_token.py` | modify | `generate_ical_alias` |
| `app/services/agent_tokens.py` | modify | `create_ical_alias`, `revoke_ical_alias` |
| `app/schemas/agent_token.py` | modify | `IcalAliasCreated` |
| `app/api/agent_tokens.py` | modify | the two ical-token routes + audit |
| `app/agent_logging.py` | modify | the two `ICAL_TOKEN_*` levels |
| `tests/test_agent_tokens_db.py` | modify | alias lifecycle + audit + 404/401 tests |

# Implementation slices

1. **Domain + service + schema + levels.** *Verify:* imports + ruff/mypy.
2. **Router.** *Verify:* `make verify`.
3. **Tests.** *Verify:* full `make verify`.

# Tests (extend `tests/test_agent_tokens_db.py`; add an `_ical_hash(name, user)` reader)

- **create:** `POST …/ical-token` for an owned token → 200; `icalToken` is 64 hex; `icalUrl` ends
  `/api/ai-agent/v1/calendar.ics?ical_token={icalToken}`; the row's `ical_token_hash ==
  hash_agent_token(icalToken)` (raw not stored); one `ICAL_TOKEN_CREATED` row.
- **rotate:** a second `POST` → a **different** `icalToken`; the stored hash changes and no longer
  matches the first raw.
- **revoke:** `DELETE` → 204; `ical_token_hash` is null; one `ICAL_TOKEN_REVOKED` row.
- **revoke idempotent:** `DELETE` on an owned token with no alias → still 204 + one `ICAL_TOKEN_REVOKED`.
- **404 missing / cross-tenant:** `POST`/`DELETE` on a missing name, and on another user's token, →
  404, the total audit count unchanged, and (cross-tenant) the victim's `ical_token_hash` unchanged.
- **401 no-auth:** with the `get_current_user_id` override popped, `POST`/`DELETE` → 401
  (`auth_required`), audit count unchanged.

# Error & rescue map

| failure | error | response |
|---------|-------|----------|
| POST/DELETE a missing / other-user token | `NotFoundError` | 404 `{error:{code}}` |
| unauthenticated | `AuthRequiredError` | 401 |
| the `ICAL_TOKEN_*` log write fails | swallowed in `log_agent_event` | the op already committed; response unaffected |

# Risks

- **Independent credential** — the alias is sha256-stored, returned once, scope-less; a DB compromise
  doesn't leak it. Pinned by the hash-not-raw test.
- **Success-only audit** — a 404 raises before the log line (no audit on failure). Pinned by the 404/401
  count tests.
- **No migration / no schema change** (`ical_token_hash` already exists); no behavior change to other
  endpoints.

# Scope check

- [x] Matches the task (alias lifecycle; the feed deferred to 2b).
- [x] Reviewable in one pass — one domain helper + two service methods + two routes + tests.
- [x] Size smell: small; reuses `_require`, `hash_agent_token`, `log_agent_event`.

# Out of scope

The `GET /v1/calendar.ics` feed, the alias auth, the `CalendarEvent`→`IcalEvent` mapping (slice 2b);
webhooks; the Redis rate-limit backend.
