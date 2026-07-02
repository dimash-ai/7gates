# Goal

Port the focal **RFC 5545 (iCalendar) serializer** as a pure domain module — `generate_ical_file(events)
-> str` producing a `text/calendar` `VCALENDAR` body. This is the substantial, review-worthy core of the
agent iCal feed; the `/v1/calendar.ics` feed endpoint + the ical-alias auth + the alias-token CRUD are a
follow-on slice that consumes this serializer. Legacy: `icalendar.ts:225-418` (`generateICalFile`).

# Scope

- **`app/domain/icalendar.py`** (pure — no HTTP, no DB, no I/O):
  - `IcalEvent` (frozen dataclass): `id`, `title`, `date: datetime.date`, `start_time: str` ("HH:MM"),
    `end_time: str | None`, `description: str | None`, `location: str | None`, `recurrence: str | None`,
    `timezone: str | None`.
  - `generate_ical_file(events: list[IcalEvent], *, stamp: datetime | None = None) -> str` — the
    `VCALENDAR` (header `VERSION:2.0` / `PRODID:-//Focal//Focal Calendar v2.0//RU` /
    `CALSCALE:GREGORIAN` / `METHOD:PUBLISH`, then a `VEVENT` per event, then `END:VCALENDAR`), every line
    **folded** and joined with `\r\n` + a trailing `\r\n`. `stamp` (the `DTSTAMP`, default
    `datetime.now(UTC)`) is injectable so the output is deterministic for tests.
  - Per `VEVENT`: `UID:{id}@focal.app`; `DTSTAMP:{stamp:%Y%m%dT%H%M%S}Z`; then dates —
    - **all-day** (`start_time == "00:00"` and `end_time == "23:59"`): `DTSTART;VALUE=DATE:{YYYYMMDD}` +
      `DTEND;VALUE=DATE:{next day}`;
    - **timed**: `DTSTART:{YYYYMMDD}T{HHMM}00` (prefixed `;TZID={timezone}` when set); `DTEND:…` likewise
      when `end_time` is set. (Wall-clock from the `start_time`/`end_time` strings — no timezone math,
      matching the legacy's local formatting.)
    - `SUMMARY:{escape(title)}`; `DESCRIPTION`/`LOCATION` when present (escaped); `RRULE:FREQ=…` for a
      `daily`/`weekly`/`monthly`/`yearly` recurrence (else omitted); `BEGIN/END:VEVENT`.
  - Helpers (module-private): `_escape` (`\`→`\\`, then `;`→`\;`, `,`→`\,`, newline→`\n`), `_fold_line`
    (≤75 chars as-is; else 75 then 74-char continuations each prefixed with one space, `\r\n`-joined),
    `_format_date` (`%Y%m%d`), `_rrule` (the recurrence map).
- **Tests** (`tests/test_icalendar.py`).

# Decisions (design rulings to confirm at Gate 1)

- **Pure domain, no consumers yet** — the serializer ships unused this slice (modeled-but-unconsumed,
  like other deferred surfaces); the feed endpoint that calls it is the next slice. This keeps the
  RFC 5545 logic reviewable in isolation with exhaustive unit tests.
- **`IcalEvent` is a plain dataclass**, not the ORM model or a Pydantic schema — the serializer must not
  couple to DB/transport; the feed slice maps `CalendarEvent` rows → `IcalEvent`.
- **Faithful port of the legacy formatting**: char-based line folding (not octet-based), the same escape
  order (backslash first), `UID@focal.app`, the all-day 00:00–23:59 heuristic, and `DTSTART` as
  wall-clock `{date}T{HHMM}00`. **One deliberate correctness fix:** `DTSTAMP` uses real **UTC**
  (`datetime.now(UTC)`, injectable) rather than the legacy's local-time-marked-`Z`; an injected `stamp`
  is **normalized to UTC** (`stamp.astimezone(UTC)`, treating a naive value as UTC) before formatting,
  so the trailing `Z` is always truthful.
- **TZID without VTIMEZONE (legacy-compatible)** — a timed event with a `timezone` emits `;TZID=<name>`
  but the calendar does **not** include a `VTIMEZONE` definition block (matching the legacy; most
  clients resolve the IANA name). Full RFC 5545 `VTIMEZONE` generation is out of scope.

# Out of scope

- The `/v1/calendar.ics` **feed endpoint**, the **ical-alias auth** (sha256 vs `ical_token_hash`), the
  **alias-token CRUD** (`POST`/`DELETE /tokens/{name}/ical-token`), and the `ICAL_TOKEN_*` events — all
  the follow-on feed slice. iCal **parsing/import** (`parseICalFile`) — not used by the agent feed.

# Acceptance criteria

- [ ] `generate_ical_file([])` is just the `VCALENDAR` header + `END:VCALENDAR`, `\r\n`-terminated, no
      `VEVENT`.
- [ ] A timed event → a `VEVENT` with `UID:{id}@focal.app`, `DTSTAMP:{stamp}Z` (the injected stamp),
      `DTSTART:{YYYYMMDD}T{HHMM}00`, `DTEND` when `end_time` set, and `SUMMARY`; with `timezone` set, the
      `DTSTART`/`DTEND` carry `;TZID={timezone}`.
- [ ] An all-day event (`00:00`/`23:59`) → `DTSTART;VALUE=DATE:{YYYYMMDD}` + `DTEND;VALUE=DATE:{next
      day}` (no `T` time).
- [ ] `recurrence` `daily`/`weekly`/`monthly`/`yearly` → the matching `RRULE:FREQ=…`; `none`/unknown →
      no `RRULE`.
- [ ] `SUMMARY`/`DESCRIPTION`/`LOCATION` escape `\` `;` `,` and newlines; a line longer than 75 chars is
      folded (75 then 74-char continuations each starting with a space), `\r\n`-joined.
- [ ] Output uses `\r\n` between every line and ends with a trailing `\r\n`; `make verify` green; no
      migration.

# Verification commands

```sh
cd superapp/apps/focal/server && DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev make verify
```
