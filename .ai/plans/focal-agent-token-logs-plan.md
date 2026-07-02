# Summary

Implement `focal-agent-token-logs` (Phase 8 hardening follow-on): emit the control-plane token events
`TOKEN_CREATED`/`TOKEN_ROTATED`/`TOKEN_REVOKED`/`AGENT_RENAMED` to `ai_agent_logs` from the token
router, after each successful op, via the shipped best-effort `log_agent_event`. No schema change, no
service change. Task: [focal-agent-token-logs.md](../tasks/focal-agent-token-logs.md). Legacy:
`ai-agent.ts:328/452/490/593`.

## Decisions (design + the Gate-1 ruling)

- **`app/agent_logging.py`** (modify) — extend `AGENT_EVENT_LEVELS` with four `info` entries:
  `TOKEN_CREATED`, `TOKEN_ROTATED`, `TOKEN_REVOKED`, `AGENT_RENAMED`.
- **`app/api/agent_tokens.py`** (modify) — `import log_agent_event`; emit after each successful service
  call (so a service-raised 409/404 is reached *before* the log line and writes nothing). The token
  service is **untouched**:
  - `create_token`: `result = await service.create(...)`; `await log_agent_event("TOKEN_CREATED",
    user_id=user_id, agent_name=result.name, details={"scopes": result.scopes, "hasExpiry":
    result.expires_at is not None})`; `return result`.
  - `rotate_token`: `result = await service.rotate(...)`; `await log_agent_event("TOKEN_ROTATED",
    user_id=user_id, agent_name=result.name)`; `return result`.
  - `rename_token`: `result = await service.rename(user_id, name, payload)`; `await
    log_agent_event("AGENT_RENAMED", user_id=user_id, agent_name=payload.name, details={"oldName": name,
    "newName": payload.name})`; `return result`.
  - `delete_token`: `await service.delete(user_id, name)`; `await log_agent_event("TOKEN_REVOKED",
    user_id=user_id, agent_name=name)`; keep the **existing** `return Response(status_code=
    status.HTTP_204_NO_CONTENT)` (a bare `Response(204)` would send 204 as the body and leave the
    status 200 — do not change the 204 contract).
  - `update_token_scopes` (`PATCH /tokens/{name}`) is **not** logged (no legacy event).
- **Attribution** — `user_id` is the JWT `sub`, `agent_name` the token name; `endpoint`/`status` are
  left null (these are control-plane management events, not request-access events). Reuses
  `log_agent_event` (best-effort, never raises).

# Files to change

| path | change | why |
|------|--------|-----|
| `app/agent_logging.py` | modify | four `info` event levels |
| `app/api/agent_tokens.py` | modify | emit the four events after success |
| `tests/test_agent_tokens_db.py` | modify | truncate `ai_agent_logs` + audit-row assertions |

# Implementation slices

1. **Levels + router wiring.** *Verify:* imports + ruff/mypy.
2. **Tests.** *Verify:* full `make verify`.

# Tests (extend `tests/test_agent_tokens_db.py`; add `focal.ai_agent_logs` to its truncate)

- **create:** a successful `POST /tokens` writes one `TOKEN_CREATED` (`level=info`, `user_id`=caller,
  `agent_name`=name, `details={"scopes": <scopes>, "hasExpiry": False}`); creating with an `expiresAt`
  → `hasExpiry True`.
- **create dup:** a duplicate-name `POST /tokens` → 409 and **no** second `TOKEN_CREATED` row (one total).
- **rotate:** `POST /tokens/{name}/rotate` → one `TOKEN_ROTATED` (`agent_name`, `details` null).
- **delete:** `DELETE /tokens/{name}` → one `TOKEN_REVOKED` (`agent_name`, `details` null).
- **rename:** `PATCH /tokens/{name}/rename` → one `AGENT_RENAMED` with `details={"oldName": old,
  "newName": new}` and `agent_name=new`.
- **scope update not logged:** capture the total audit-row count, `PATCH /tokens/{name}` (scopes), then
  assert the count is unchanged (the setup `TOKEN_CREATED` row makes a bare "no rows" assertion
  ambiguous, so compare counts).
- **404/cross-tenant writes nothing:** a `rotate`/`rename`/`delete` on a **missing** name → 404 and the
  relevant event_type has zero rows; a `rotate` on **another user's** token → 404 and the total
  audit-row count is unchanged.

# Error & rescue map

| failure | handling |
|---------|----------|
| the `ai_agent_logs` insert fails | swallowed inside `log_agent_event` (structlog `ai_agent_log_write_failed`); the token op already committed and the response is unaffected |
| a 409/404 control-plane op | the service raises before the router log line → no audit row (success-only) |

# Risks

- **Success-only** — logging after the awaited service call means failed ops never log. Pinned by the
  409 + 404 "no row" tests.
- **No service change / no migration / no behavior change** to the token endpoints' responses — additive.

# Scope check

- [x] Matches the task (the four control-plane events; data-plane/RATE_LIMITED/iCal/webhook out).
- [x] Reviewable in one pass — four router log lines + four level entries + tests.
- [x] Size smell: tiny; reuses `log_agent_event`.

# Out of scope

Data-plane events (shipped); `RATE_LIMITED`; `ICAL_TOKEN_*`; `WEBHOOK_UPDATED`; a logs read API;
rate-limiting; iCal; webhooks.
