# Goal

Complete the agent audit log (Phase 8 hardening, follow-on to `focal-agent-logs`): emit the
**control-plane** token-lifecycle events — `TOKEN_CREATED`, `TOKEN_ROTATED`, `TOKEN_REVOKED`,
`AGENT_RENAMED` — to `ai_agent_logs` when a user manages their `foc_` tokens. Reuses the shipped
`log_agent_event`. Legacy: `ai-agent.ts:328` / `:452` / `:490` / `:593`, `agentLogging.ts`.

# Scope

- **`app/agent_logging.py`** (modify) — add the four control-plane events to `AGENT_EVENT_LEVELS`, all
  `info`: `TOKEN_CREATED`, `TOKEN_ROTATED`, `TOKEN_REVOKED`, `AGENT_RENAMED`.
- **`app/api/agent_tokens.py`** (modify) — emit each event **in the router**, after the successful
  service call (so a 409/404 raised by the service is *not* logged), via the existing best-effort
  `log_agent_event` (never raises). The token **service stays unchanged** — audit lives at the API
  boundary, parallel to the data-plane events that log at the auth-dep boundary:
  - `POST /tokens` → `TOKEN_CREATED` — `user_id`, `agent_name=result.name`, `details={"scopes":
    result.scopes, "hasExpiry": result.expires_at is not None}`.
  - `POST /tokens/{name}/rotate` → `TOKEN_ROTATED` — `user_id`, `agent_name=result.name`.
  - `PATCH /tokens/{name}/rename` → `AGENT_RENAMED` — `user_id`, `agent_name=payload.name`,
    `details={"oldName": name, "newName": payload.name}`.
  - `DELETE /tokens/{name}` → `TOKEN_REVOKED` — `user_id`, `agent_name=name`.
- **Tests** — extend `tests/test_agent_tokens_db.py`: add `focal.ai_agent_logs` to its truncate, and
  assert each op writes its audit row.

# Decisions (design rulings to confirm at Gate 1)

- **Emit in the router, not the service** — keeps the token service pure (no audit side-effect) and
  mirrors the data-plane events, which log at the auth/scope dependency boundary, not in business code.
  Logged **only on success** (the service raises `ConflictError`/`NotFoundError` before the router's log
  line is reached), matching the legacy ordering.
- **info-level; JWT-user-attributed** — `user_id` is the JWT `sub` (the token owner), `agent_name` is
  the token name. Reuses the best-effort `log_agent_event` (structlog + a durable row, never raises).
- **Webhook legacy details dropped** — `TOKEN_CREATED.hasWebhook` and `TOKEN_ROTATED.{webhookChanged,
  scopesChanged}` don't apply here (webhook isn't settable; rotate only replaces the secret), so
  `TOKEN_CREATED` keeps `{scopes, hasExpiry}`, `AGENT_RENAMED` keeps `{oldName, newName}`, and
  `TOKEN_ROTATED`/`TOKEN_REVOKED` carry no `details`.
- **`update_scopes` (`PATCH /tokens/{name}`) is not logged** — the legacy has no event for it.

# Out of scope

- The data-plane events (already shipped: `ACCESS`/`AUTH_FAILED`/`SCOPE_DENIED`); `RATE_LIMITED`;
  `ICAL_TOKEN_*`; `WEBHOOK_UPDATED`; a logs read/query API; rate-limiting; iCal; webhooks.

# Acceptance criteria

- [ ] A successful `POST /tokens` writes one `TOKEN_CREATED` row (`level=info`, `user_id`=caller,
      `agent_name`=token name, `details={"scopes": …, "hasExpiry": …}`); a duplicate-name 409 writes
      **no** row.
- [ ] A successful `POST /tokens/{name}/rotate` writes `TOKEN_ROTATED`; a successful `DELETE
      /tokens/{name}` writes `TOKEN_REVOKED`; both carry `agent_name` and no `details`.
- [ ] A successful `PATCH /tokens/{name}/rename` writes `AGENT_RENAMED` with `details={"oldName": old,
      "newName": new}`; a `PATCH /tokens/{name}` scope update writes **no** audit row.
- [ ] A `rotate`/`rename`/`delete` on a **missing** (or another user's) token → 404 and writes **no**
      audit row (success-only logging).
- [ ] `make verify` green; no migration (the table already exists).

# Verification commands

```sh
make verify
```
