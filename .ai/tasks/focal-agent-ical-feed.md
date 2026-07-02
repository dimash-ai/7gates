# Goal

Port the agent **iCal feed** (Phase 8, iCal slice 2b): `GET /api/ai-agent/v1/calendar.ics?ical_token=…`
— a read-only RFC 5545 calendar of the alias owner's events for the last 30 / next 60 days. This
consumes the shipped serializer (`generate_ical_file`) + the alias (`ical_token_hash`) and completes the
iCal feature. Legacy: `ai-agent.ts:907-1014`.

# Scope

- **`app/services/agent_data.py`** (modify) — extend `AgentDataService`:
  - `find_token_by_ical_hash(token_hash) -> AiAgentToken | None` — `select(AiAgentToken).where(
    ical_token_hash == token_hash)`.
  - `touch_token_last_used(token_id) -> None` — best-effort `last_used_at = utcnow()` (`try/except
    SQLAlchemyError: rollback`), like `get_agent_principal`'s touch.
  - `ical_events(user_id) -> list[IcalEvent]` — `today = datetime.now(UTC).date()`; select the user's
    `CalendarEvent` rows with `date` in `[today − 30d, today + 60d]`, ordered by `date`, `start_time`;
    map each → `IcalEvent` (id, title, date, start_time, end_time, description, location, recurrence,
    timezone).
- **`app/api/agent_data.py`** (modify) — `GET /calendar.ics` (public `/api/ai-agent/v1/calendar.ics`),
  **not** behind `require_scope`, depending only on the session/service:
  - read `ical_token` (query). Missing → `AUTH_FAILED` (`reason: missing_token`) + **plain-text 401**;
    `len > 128` → `AUTH_FAILED` (`invalid_token`) + 401; `find_token_by_ical_hash(hash_agent_token(
    ical_token))` is `None` → `AUTH_FAILED` (`invalid_token`) + 401; the token's `expires_at` is past →
    `AUTH_FAILED` (`expired`, attributed to its `user_id`/`name`) + 401.
  - on success: `touch_token_last_used(token.id)`; `ACCESS` log (endpoint `GET
    /api/ai-agent/v1/calendar.ics`); `ics = generate_ical_file(await service.ical_events(token.user_id))`;
    return `Response(ics, media_type="text/calendar; charset=utf-8")` with `Content-Disposition:
    attachment; filename="focal.ics"` and `Cache-Control: no-store`.
- **Tests.**

# Decisions (design rulings to confirm at Gate 1)

- **The feed is the one agent endpoint that does NOT use the `{ok}` JSON envelope** — calendar clients
  (Google/Apple Calendar) consume it, so success is `text/calendar` and every failure is a **plain-text
  `401 "Unauthorized"`**, returned as a bare `Response` (it does **not** raise `AgentApiError`, which
  would render JSON). This intentional divergence is the whole point of the endpoint.
- **Alias auth, not X-Focal-Token** — auth is the `ical_token` **query param** (no header), sha256'd and
  matched against `ical_token_hash`; there is **no scope check** (the alias is the credential and the
  feed is fixed read-only). Independent of `get_agent_principal` / `require_scope`.
- **Audit reuse** — `AUTH_FAILED` (with the feed's endpoint, the legacy reasons, the expired case
  attributed to the owner) and a success `ACCESS` go through the existing best-effort `log_agent_event`;
  `last_used_at` is touched best-effort (the feed bypasses the X-Focal-Token path that normally does it).
- **Window** — `[today − 30d, today + 60d]` computed in **UTC** (matching the legacy's `toISOString`
  date math); raw stored events (no recurrence expansion — the serializer emits `RRULE`).

# Out of scope

- Webhook delivery; the deferred Redis rate-limit backend. Rate-limiting the feed (the feed bypasses the
  X-Focal-Token limiter; the legacy did not limit it either) — not added. **Tracked operational
  follow-up:** the public, unauthenticated-until-lookup feed can be spammed into indexed `ical_token_hash`
  lookups + `AUTH_FAILED` log writes; a future limit (by IP, or via the deferred Redis backend) should
  cover it before a public multi-replica deploy.

# Acceptance criteria

- [ ] A valid `ical_token` → **200** `text/calendar` whose body is a `VCALENDAR` containing the owner's
      events within `[−30d, +60d]`; the response carries `Content-Type: text/calendar; charset=utf-8`,
      `Content-Disposition: attachment; filename="focal.ics"`, `Cache-Control: no-store`; one `ACCESS`
      audit row; the token's `last_used_at` is touched.
- [ ] A missing / oversized (>128) / unknown `ical_token` → **401** with a **plain-text** body (not the
      JSON `{ok}` envelope) and an `AUTH_FAILED` row (`missing_token`/`invalid_token`); an **expired**
      token → 401 + `AUTH_FAILED` (`expired`) attributed to its `user_id`/`agent_name`; **no** calendar
      body and `last_used_at` untouched.
- [ ] Events **outside** `[−30d, +60d]`, and **another user's** events, are excluded; the feed is scoped
      to the alias owner.
- [ ] `make verify` green; no migration.

# Verification commands

```sh
cd superapp/apps/focal/server && DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev make verify
```
