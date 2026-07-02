# Goal

Port the focal meeting-requests **read surface** (Phase 2 step 6, deferred into Phase 3): the
`meeting_requests` model + migration and the Google-independent read/delete endpoints —
`GET /api/meeting-requests` (status filter), `GET /api/meeting-requests/count` (pending badge),
`GET /api/meeting-requests/{id}`, `DELETE /api/meeting-requests/{id}` (declined-only). The five RSVP
actions (accept / decline / accept-reschedule / decline-reschedule / tentative) are **deferred** —
each calls the Google Calendar API (`googleCalendarMeetings.respondTo*`, routes.ts:6772+) and lands
with the Google-sync slice.

# Scope

- **`app/models/meeting_request.py`** — `MeetingRequest`, faithful to the legacy `meeting_requests`
  table (schema.ts:46): String uuid PK (`default=lambda: str(uuid4())`, matching the codebase),
  `user_id` (indexed), `shared_calendar_id` (FK `focal.shared_calendars.id` ondelete SET NULL,
  nullable), `google_event_id` / `google_calendar_id` (String(500), required), `title` / `description`
  (Text), `start_time` / `end_time` (tz-aware DateTime, required), `location` (Text), `timezone`
  (String(50)), `organizer_email` (String(255)) / `organizer_name` (String(255)), `status`
  (String(20) default `"pending"`), `request_type` (String(20) default `"new"`),
  `original_start_time` / `original_end_time` (tz-aware DateTime, nullable), `focal_event_id` (FK
  `focal.calendar_events.id` ondelete SET NULL, nullable), `responded_at` / `google_updated_at`
  (tz-aware DateTime, nullable), `created_at` / `updated_at` (TimestampMixin); indexes on `user_id`,
  `shared_calendar_id`, `status`, `google_event_id`.
- **Migration** — new `meeting_requests` table (next after `4949a1234913`), created + reviewed in-slice
  (this migration program's established pattern).
- **`app/schemas/meeting_request.py`** — `MeetingRequestRead` (camelCase, all columns).
- **`app/services/meeting_requests.py`** — `MeetingRequestsService`:
  - `list_requests(user_id, *, status=None)` → the user's requests, optional status filter, ordered by
    `start_time` DESC (port of `getMeetingRequests`).
  - `pending_count(user_id)` → count of `status == "pending"` (port of
    `getPendingMeetingRequestsCount`).
  - `get_request(user_id, id)` → tenant-scoped; `NotFoundError` if missing **or not the caller's**.
  - `delete_request(user_id, id)` → tenant-scoped; allowed only when `status == "declined"` else
    `ConflictError` (port of the "can only delete declined" rule).
- **`app/api/meeting_requests.py`** — `/api/meeting-requests` router; the static `/count` declared
  **before** `/{id}`; `GET` list (`?status=`), `GET /count`, `GET /{id}`, `DELETE /{id}` (→ 204).
  Registered in `app/main.py`.
- **Tests** — list + status filter + ordering, count, get (own + cross-tenant 404), delete (declined →
  204, non-declined → 409, cross-tenant → 404), tenant isolation.

# Decisions (design rulings to confirm at Gate 1)

- **RSVP actions deferred (Google-coupled).** accept / decline / accept-reschedule /
  decline-reschedule / tentative all call the Google Calendar API → blocked on Google credentials;
  they ship with the Google-sync slice. This slice ports the model + read/delete surface only — the
  sidebar count badge + list/detail — which is Google-independent and ETL-populatable.
- **Tenant hardening over the legacy.** Tenant is the JWT `sub` (the legacy trusted a client-supplied
  `?userId=`). `get_request` / `delete_request` by id **also verify ownership** (404 when the row is
  not the caller's) — the legacy fetched/deleted any row by id, a cross-tenant read/delete leak, fixed
  here.
- **No manual create endpoint** (faithful) — meeting requests are created only by Google ingestion
  (deferred); rows arrive via ETL / Google sync.
- **`start_time` / `end_time` tz-aware DateTime**, with the separate `timezone` column carrying the
  display zone (codebase convention; ETL maps the legacy naive timestamps as UTC).
- Typed `AppError` only (`NotFoundError`, `ConflictError`); camelCase responses; `DELETE` → 204
  (codebase convention, vs the legacy `{success:true}`).

# Out of scope

- The 5 RSVP POST actions + their Google API calls + the accept → focal-event creation (Google-sync
  slice); Google ingestion (webhook → `meeting_requests`); the React UI; ETL. CRM (→ PRIMA).

# Acceptance criteria

- [ ] `GET /api/meeting-requests` returns the caller's requests (`start_time` DESC); `?status=pending`
      filters to pending; `GET /count` returns `{ "count": N }` of pending.
- [ ] `GET /{id}` returns the caller's request; a missing id or another user's id → 404.
- [ ] `DELETE /{id}` removes the caller's request only when `status == "declined"` (→ 204); a
      non-declined status → 409; missing / other-user → 404.
- [ ] Tenant isolation: a second user's requests never appear in list/count and cannot be fetched or
      deleted by id.
- [ ] `make verify` green; the migration applies (`alembic upgrade head`) and `alembic check` is clean.

# Verification commands

```sh
make verify
docker exec focal-local-postgres-1 psql -U focal -d focal_dev -c "DROP SCHEMA IF EXISTS focal CASCADE; CREATE SCHEMA focal; DROP TABLE IF EXISTS public.alembic_version;"
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic upgrade head
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```
