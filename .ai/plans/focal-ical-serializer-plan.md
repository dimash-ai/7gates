# Summary

Implement `focal-ical-serializer` (Phase 8): a pure `app/domain/icalendar.py` RFC 5545 serializer —
`generate_ical_file(events) -> str`. No HTTP, no DB, no schema change. The feed endpoint + ical-alias
auth + alias CRUD are the deferred follow-on slice. Task:
[focal-ical-serializer.md](../tasks/focal-ical-serializer.md). Legacy: `icalendar.ts:225-418`.

## Decisions (design + the Gate-1 rulings)

- **`app/domain/icalendar.py`** (pure):
  - `IcalEvent` (frozen dataclass): `id`, `title`, `date: date`, `start_time: str`, `end_time: str |
    None = None`, `description: str | None = None`, `location: str | None = None`, `recurrence: str |
    None = None`, `timezone: str | None = None`.
  - `generate_ical_file(events, *, stamp=None) -> str`: compute the `DTSTAMP` once — `raw = stamp or
    datetime.now(UTC)`; **if `raw.tzinfo is None` treat as UTC (`replace(tzinfo=UTC)`)** else
    `astimezone(UTC)`; `dtstamp = raw.strftime("%Y%m%dT%H%M%SZ")`. Build the line list (`BEGIN:VCALENDAR`,
    `VERSION:2.0`, `PRODID:-//Focal//Focal Calendar v2.0//RU`, `CALSCALE:GREGORIAN`, `METHOD:PUBLISH`,
    each event's `_vevent(...)`, `END:VCALENDAR`), then `"\r\n".join(_fold_line(l) for l in lines) +
    "\r\n"`.
  - `_vevent(event, dtstamp) -> list[str]`: `BEGIN:VEVENT`, `UID:{id}@focal.app`, `DTSTAMP:{dtstamp}`;
    then **all-day** (`start_time == "00:00" and end_time == "23:59"`) → `DTSTART;VALUE=DATE:{_fmt_date}`
    + `DTEND;VALUE=DATE:{_fmt_date(date + 1 day)}`; else **timed** → `tzid = f";TZID={timezone}" if
    timezone else ""`; `DTSTART{tzid}:{_fmt_dt(date, start_time)}` and, when `end_time`,
    `DTEND{tzid}:{_fmt_dt(date, end_time)}`. Then `SUMMARY:{_escape(title)}`, optional
    `DESCRIPTION`/`LOCATION` (escaped), the `RRULE` for a known recurrence, `END:VEVENT`.
  - Helpers: `_fmt_date(d)` → `d.strftime("%Y%m%d")`; `_fmt_dt(d, hhmm)` → `f"{_fmt_date(d)}T{hhmm.
    replace(':','')}00"` (wall-clock, seconds `00`); `_escape` (`\`→`\\`, `;`→`\;`, `,`→`\,`,
    `\n`→`\n`, backslash first); `_fold_line` (≤75 → as-is; else `line[:75]` then 74-char chunks each
    prefixed with one space, `"\r\n".join`); `_RRULE = {"daily": "RRULE:FREQ=DAILY", "weekly": …,
    "monthly": …, "yearly": …}` (`.get(recurrence or "")`).

# Files to change

| path | change | why |
|------|--------|-----|
| `app/domain/icalendar.py` | add | the pure RFC 5545 serializer + `IcalEvent` |
| `tests/test_icalendar.py` | add | exhaustive serializer unit tests |

# Implementation slices

1. **The module.** *Verify:* unit tests + ruff/mypy.
2. **Tests.** *Verify:* full `make verify`.

# Tests (`tests/test_icalendar.py`, pure — no DB; use a fixed `stamp`)

- **empty:** `generate_ical_file([])` → exactly the 5 header lines + `END:VCALENDAR`, CRLF-joined +
  trailing CRLF, **no** `VEVENT`.
- **timed event:** asserts `BEGIN:VEVENT`, `UID:{id}@focal.app`, `DTSTAMP:{stamp}Z` (the injected
  fixed stamp), `DTSTART:{YYYYMMDD}T{HHMM}00`, `DTEND:…` when `end_time`, `SUMMARY:{title}`,
  `END:VEVENT`.
- **timezone:** a timed event with `timezone="Asia/Almaty"` → the lines begin exactly
  `DTSTART;TZID=Asia/Almaty:` and `DTEND;TZID=Asia/Almaty:` (uppercase `TZID`, **no space** after `;`).
- **all-day:** `start_time="00:00"`, `end_time="23:59"` → `DTSTART;VALUE=DATE:{YYYYMMDD}` +
  `DTEND;VALUE=DATE:{next day}`, no `T`.
- **recurrence:** parametrized `daily`/`weekly`/`monthly`/`yearly` → the matching `RRULE:FREQ=…`;
  `none`/`None`/unknown → **no** `RRULE` line.
- **description/location:** present → `DESCRIPTION:`/`LOCATION:` lines; absent → omitted.
- **escape (exact):** a title `"a\\b;c,d\ne"` (a · backslash · b · `;` · c · `,` · d · newline · e) →
  the `SUMMARY` line is **exactly** `SUMMARY:a\\b\;c\,d\ne` (backslash doubled **first**, so `;`/`,` and
  the newline-as-`\n` are escaped once, never double-escaped). Assert the whole line equals the literal.
- **fold (exact 75/74):** a >75-char field (e.g. a 100-char `SUMMARY` value) → every physical line
  (`output.split("\r\n")`) is ≤ 75 chars; the **first** chunk of the folded line is exactly 75 chars and
  each continuation is `" "` + ≤ 74 payload chars; reconstructing (first chunk + each continuation minus
  its leading space) equals the original unfolded line.
- **stamp normalization:** a naive `stamp` is formatted as if UTC; an aware non-UTC `stamp` is converted
  to UTC before the `Z`.

# Risks

- **Pure + deterministic** — `stamp` injection removes the only nondeterminism; no DB/HTTP, so no
  flakiness.
- **Legacy-compatible, not strict RFC 5545** — `TZID` without a `VTIMEZONE` block; char-based (not
  octet-based) folding. Documented; matches the legacy + the deferred feed slice.
- **No consumers yet** — the serializer ships unused; the feed slice wires it. No behavior change.

# Scope check

- [x] Matches the task (pure serializer; feed/alias deferred).
- [x] Reviewable in one pass — one pure module + exhaustive unit tests.
- [x] Size smell: a single self-contained domain module.

# Out of scope

The `/v1/calendar.ics` feed endpoint, ical-alias auth, the alias-token CRUD, `ICAL_TOKEN_*` events, iCal
parsing/import, and `VTIMEZONE` generation — all deferred.
