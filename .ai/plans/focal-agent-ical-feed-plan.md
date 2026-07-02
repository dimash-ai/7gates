# Summary

Implement `focal-agent-ical-feed` (Phase 8, iCal slice 2b): `GET /api/ai-agent/v1/calendar.ics?
ical_token=…` — the read-only RFC 5545 feed of the alias owner's events for `[today−30d, today+60d]`
(UTC), `text/calendar` on success and **plain-text 401** on failure (not the JSON `{ok}` envelope).
Consumes the shipped `generate_ical_file` + the `ical_token_hash` alias. No schema change. Task:
[focal-agent-ical-feed.md](../tasks/focal-agent-ical-feed.md). Legacy: `ai-agent.ts:907-1014`.

## Decisions (design + the Gate-1 rulings)

- **`app/services/agent_data.py`** (modify) — extend `AgentDataService` (add imports `update`,
  `SQLAlchemyError`, `datetime`/`UTC`/`timedelta`, `AiAgentToken`, `IcalEvent`):
  - `find_token_by_ical_hash(token_hash) -> AiAgentToken | None` — `select(AiAgentToken).where(
    ical_token_hash == token_hash)` → `scalar_one_or_none()`.
  - `touch_token_last_used(token_id) -> None` — `update(AiAgentToken).where(id == token_id).values(
    last_used_at=utcnow())` + commit, wrapped `try/except SQLAlchemyError: rollback` (best-effort).
  - `ical_events(user_id) -> list[IcalEvent]` — `today = datetime.now(UTC).date()`; select the user's
    `CalendarEvent` where `date` in `[today − 30d, today + 60d]`, ordered `date, start_time`; map each
    row → `IcalEvent(id, title, date, start_time, end_time, description, location, recurrence, timezone)`.
- **`app/api/agent_data.py`** (modify) — add imports `Response` (fastapi), `hash_agent_token`,
  `generate_ical_file`, `UTC`; module constants `_ICAL_ENDPOINT = "GET /api/ai-agent/v1/calendar.ics"`,
  `_MAX_ICAL_TOKEN_LENGTH = 128`; `_unauthorized() -> Response("Unauthorized", status_code=401,
  media_type="text/plain")`:
  - `GET /calendar.ics` (no `require_scope`; `service = Depends(get_agent_data_service)`; query param
    `ical_token: str | None = None`):
    - missing → `log_agent_event("AUTH_FAILED", endpoint=_ICAL_ENDPOINT, status=401, details={"reason":
      "missing_token"})` + `_unauthorized()`; `len > 128` → same with `invalid_token`; `find_token_by_
      ical_hash(hash_agent_token(ical_token))` is `None` → `invalid_token` + 401.
    - **Capture the fields into locals immediately** — `token_id, user_id, agent_name, expires_at =
      token.id, token.user_id, token.name, token.expires_at` — because `touch_token_last_used` may
      `rollback` the shared session and **expire** the ORM `token`; reading `token.user_id` afterward
      could lazy-refresh and turn a best-effort telemetry failure into a feed failure. Then if
      `expires_at` is past (naive→UTC normalize, like `get_agent_principal`) → `AUTH_FAILED` (`expired`,
      `user_id`/`agent_name`) + 401.
    - success → `await service.touch_token_last_used(token_id)`; `log_agent_event("ACCESS", user_id,
      agent_name, endpoint=_ICAL_ENDPOINT)`; `ics = generate_ical_file(await service.ical_events(
      user_id))`; `return Response(ics, media_type="text/calendar; charset=utf-8", headers={
      "Content-Disposition": 'attachment; filename="focal.ics"', "Cache-Control": "no-store"})`. All
      post-lookup work uses the **captured locals**, never the ORM `token`.
  - The endpoint returns a bare `Response` (no `response_model`); it never raises `AgentApiError`.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/services/agent_data.py` | modify | `find_token_by_ical_hash`, `touch_token_last_used`, `ical_events` |
| `app/api/agent_data.py` | modify | the `/calendar.ics` feed endpoint |
| `tests/test_agent_ical_feed_db.py` | add | feed auth + body + window + tenant + plain-text 401 |

# Implementation slices

1. **Service methods.** *Verify:* imports + ruff/mypy.
2. **Endpoint.** *Verify:* `make verify`.
3. **Tests.** *Verify:* full `make verify`.

# Tests (`tests/test_agent_ical_feed_db.py`, DB-backed; seed a token with `ical_token_hash` set + events)

- **valid feed (inclusive window):** seed an aliased token + events at **today**, **today−30d**, and
  **today+60d** (all included) plus **today−31d** and **today+61d** (excluded); `GET /calendar.ics?
  ical_token=<raw>` → **200**; `Content-Type` starts `text/calendar`; `Content-Disposition: attachment;
  filename="focal.ics"`; `Cache-Control: no-store`; body starts `BEGIN:VCALENDAR`, contains the **three**
  in-window `SUMMARY`s and **neither** out-of-window one (pins the inclusive `[−30, +60]` boundary); one
  `ACCESS` row; the token's `last_used_at` is set.
- **missing token:** `GET /calendar.ics` (no param) → **401**, `resp.text == "Unauthorized"`, body is
  **not** JSON (`"ok"` absent), one `AUTH_FAILED` (`missing_token`).
- **oversized / unknown:** a >128-char token and an unknown token → 401 + `AUTH_FAILED` (`invalid_token`).
- **expired:** an aliased token with `expires_at` in the past → 401 + `AUTH_FAILED` (`expired`,
  `user_id`/`agent_name` set); `last_used_at` stays null; no calendar body.
- **tenant:** a feed for user-A's alias never includes user-B's events.

# Error & rescue map

| condition | handling |
|-----------|----------|
| missing / oversized / unknown / expired `ical_token` | `AUTH_FAILED` row + plain-text `401 "Unauthorized"` |
| the `last_used_at` / log write fails | swallowed (best-effort); the feed still serves |

# Risks

- **Distinct envelope** — the feed returns `text/calendar` / plain-text 401 via a bare `Response`, not
  the JSON `{ok}`/AppError path. Pinned by the plain-text-401 + content-type tests.
- **No feed rate-limit** (legacy parity) — tracked operational follow-up (out-of-scope note).
- **No migration / no schema change**; no behavior change to existing endpoints.

# Scope check

- [x] Matches the task (the feed; webhooks/Redis deferred).
- [x] Reviewable in one pass — three service methods + one endpoint + tests; reuses the serializer/alias.
- [x] Size smell: moderate, self-contained.

# Out of scope

Webhooks; the Redis rate-limit backend; feed rate-limiting (tracked follow-up); recurrence expansion
(the serializer emits `RRULE`).
