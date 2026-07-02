# Summary

Implement `focal-meeting-requests-read` (Phase 2 step 6, deferred into Phase 3): the
Google-independent meeting-requests read surface. A new `MeetingRequest` model + migration, a
`MeetingRequestRead` schema, a `MeetingRequestsService` (list / pending-count / get / delete), and the
`/api/meeting-requests` router (`GET` list `?status=`, `GET /count`, `GET /{id}`, `DELETE /{id}`). The
five Google-API RSVP actions are deferred to the Google-sync slice. Task:
[focal-meeting-requests-read.md](../tasks/focal-meeting-requests-read.md). Legacy: `routes.ts:6684`,
`storage.ts:6622`, `schema.ts:46`.

## Decisions (design + the Gate-1 rulings)

- **RSVP deferred (Google-coupled).** accept / decline / accept-reschedule / decline-reschedule /
  tentative each call the Google Calendar API; they ship with Google sync. This slice is model + reads
  + delete only — Google-independent, ETL-populatable, and enough for the sidebar count badge.
- **Tenant from the JWT `sub`** (no `?userId=`); `get_request` / `delete_request` by id **verify
  ownership** → `NotFoundError` (404) when the row is missing **or** not the caller's, closing the
  legacy cross-tenant read/delete leak.
- **Delete only a `declined` request** → else `ConflictError` (409); `DELETE` returns 204. The delete
  is **atomic** (Gate-2 Should-Consider): a conditional `DELETE ... WHERE id = :id AND user_id = :sub
  AND status = 'declined'`; on 0 rows affected, re-query by `(id, user_id)` to distinguish 404
  (missing / other-user) from 409 (exists but not declined), so a concurrent status change can't race
  between the check and the delete.
- **No manual create endpoint** (faithful — rows arrive only via Google ingestion / ETL).
- **tz-aware DateTime** for all instants; the separate `timezone` column carries the display zone.
- **Register `MeetingRequest` in `app/models/__init__.py`** (Gate-1 Should-Consider) so
  `alembic/env.py`'s `import app.models` sees it and `alembic check` stays clean.
- **Migration created + reviewed in-slice** (this program's established pattern), next after
  `4949a1234913`.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/models/meeting_request.py` | add | the `MeetingRequest` model (faithful to `meeting_requests`) |
| `app/models/__init__.py` | modify | import + `__all__` export `MeetingRequest` (alembic visibility) |
| `alembic/versions/<rev>_meeting_requests.py` | add | the new-table migration (SET NULL FKs + 4 indexes), under the server-root `alembic/versions` |
| `app/schemas/meeting_request.py` | add | `MeetingRequestRead` (camelCase) |
| `app/services/meeting_requests.py` | add | `MeetingRequestsService` (list / count / get / delete) |
| `app/api/meeting_requests.py` | add | `/api/meeting-requests` router + session-backed service dep |
| `app/main.py` | modify | register the router |
| `tests/test_meeting_requests_db.py` | add | read/delete behavior + tenant isolation + the full-shape contract pin |
| `tests/test_migration.py` | modify | assert the new table, SET NULL FKs, and indexes (Gate-1 SC) |

# Implementation slices

Each leaves `make verify` green.

1. **Model + registration + migration.** Add `MeetingRequest`; export it in `__init__.py`; autogenerate
   the migration, then verify SET NULL FKs (`shared_calendar_id` → `focal.shared_calendars.id`,
   `focal_event_id` → `focal.calendar_events.id`) and the four indexes. *Verify:* reset schema →
   `alembic upgrade head` → `alembic check` clean.
2. **Schema + service + router + main.** `MeetingRequestRead`; `MeetingRequestsService`; the router
   (static `/count` before `/{id}`); register in `app/main.py`. *Verify:* `make verify` green.
3. **Tests.** DB integration tests + the migration assertion + the contract pin. *Verify:* full
   `make verify` green.

# Tests

- **list:** the caller's requests ordered by `start_time` DESC; `?status=pending` filters to pending.
- **count:** `{ "count": N }` = number of the caller's `pending` requests.
- **get:** the caller's request by id → 200; a missing id or another user's id → 404.
- **delete:** the caller's `declined` request → 204 and gone; a `pending`/`accepted` request → 409 and
  still present; a missing / other-user id → 404.
- **tenant isolation:** a second user's requests never appear in list/count and can't be fetched or
  deleted by id.
- **migration:** `test_migration.py` asserts `meeting_requests` exists with the SET NULL FKs and the
  `user_id` / `shared_calendar_id` / `status` / `google_event_id` indexes.
- **contract:** the `GET /{id}` test asserts the **full** `MeetingRequestRead` camelCase key set,
  pinning the serialized shape end-to-end (in lieu of a separate `test_contracts.py` entry).

# Error & rescue map

| failure mode | error | response |
|--------------|-------|----------|
| get / delete a missing or other-user id | `NotFoundError` | 404 |
| delete a non-`declined` request | `ConflictError` | 409 |
| no auth / bad JWT | `AuthRequiredError` (dependency) | 401 |
| status filter with an unknown value | none — empty list (faithful; legacy passes it through) | 200 `[]` |

# Review lenses (pre-answer)

- **Scope / strategy.** One model + migration + a thin read service + router; the Google-coupled writes
  are explicitly deferred. No new error code (reuses `NotFoundError` / `ConflictError`).
- **Architecture.** Tenant-scoped reads via the JWT `sub`; ownership verified on by-id access (closes a
  legacy leak); typed errors; tz-aware columns.
- **Completeness.** Status filter, ordering, pending count, the declined-only delete rule, and tenant
  isolation each map to a test; the migration is asserted.
- **Tests & verification.** `make verify` green; migration applies; `alembic check` clean.

# Risks & migrations

- **Migration FK targets** (`focal.shared_calendars`, `focal.calendar_events`) already exist earlier in
  the chain; both FKs are `ON DELETE SET NULL`, nullable. Verify autogenerate emits them (it can miss
  ondelete — adjust by hand if so).
- **Route ordering:** `/count` must precede `/{id}` or "count" is captured as an id.
- **No behavior change** to existing endpoints — only additive (new table + router).

# Scope check

- [x] Matches the task Scope / Out of scope (model + reads + delete; RSVP + ingestion deferred; no
      create; CRM → PRIMA).
- [x] Reviewable in one pass — 3 sequenced slices, each green.
- [x] Size smell: one model, one migration, one schema, one small service, one thin router, tests.

# Out of scope

The 5 RSVP actions + their Google API calls + accept → focal-event creation; Google ingestion
(webhook → `meeting_requests`); the React UI; ETL; CRM (→ PRIMA).
