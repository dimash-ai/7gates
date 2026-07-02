# Goal

Port the bookings vertical (Phase 2 step 4): tenant-scoped CRUD for `focal.bookings` (multi-day
date-range blocks shown on the calendar) and fold real bookings into the `GET /api/calendar/init`
aggregate (which currently returns `bookings: []`). This completes the calendar-init contract
(expand → contract).

# Scope

- **No model change, no migration.** The `Booking` model (`app/models/bookings.py`) and the
  `focal.bookings` table already exist (scaffolded in the foundation slice / baseline migration
  `25938473715d`). This slice is schema + service + router + init wiring only; `alembic check` must
  stay clean.
- **`app/api/bookings.py`** — the legacy `/api/bookings` surface (`routes.ts:3436-3555`):
  - `GET /api/bookings?startDate=&endDate=` — the window's bookings, ordered by `start_date`.
  - `GET /api/bookings/{id}` — one booking.
  - `POST /api/bookings` — create (→ 200, `BookingRead`).
  - `PATCH /api/bookings/{id}` — partial update.
  - `DELETE /api/bookings/{id}` — delete (→ 204).
  - Register the router in `app/main.py`.
- **`BookingsService`** over the existing model: list / get / create / update / delete, tenant-scoped
  to the JWT `sub`.
- **`BookingCreate` / `BookingUpdate` / `BookingRead`** Pydantic schemas (camelCase).
- **Wire into calendar-init:** `CalendarInitRead.bookings` becomes `list[BookingRead]` and
  `CalendarInitService.get_init` returns the window's bookings instead of `[]`.

# Decisions (design rulings to confirm at Gate 1)

- **Denormalized passthrough (not enrichment).** The existing model deliberately keeps the source's
  denormalized `project` / `product` / `project_type` name columns alongside the `project_id` /
  `product_id` FKs. So bookings are stored and returned **as the client sends them** — no read-time
  name resolution (unlike events/tasks, whose models dropped those columns). This is constrained by
  the already-shipped model; changing it would need a migration and diverge from the baseline.
- **Owned-link validation (tenant safety, a hardening over legacy).** `project_id` / `product_id`
  (FK `focal.projects.id`, cross-user) are validated as the caller's own when non-null →
  `related_record_not_found` otherwise, exactly like `tasks` / events. The denormalized `project` /
  `product` *name* strings are free-form labels, stored verbatim (not validated).
- **Tenant-scope every by-id op (fixes a legacy leak).** Legacy `getBooking` / `updateBooking` /
  `deleteBooking` look up by id with **no** owner check; the port scopes by `sub` and returns
  `not_found` for a missing or non-owned id.
- **Window = strict containment, faithful to legacy** (`getAllBookings`, storage.ts:5115):
  `start_date >= window_start AND end_date <= window_end` (a booking fully inside the window), via the
  shared `get_date_range` (same defaults/fallback as events/tasks). Note this differs from the event
  overlap window — it is the source's behavior and is ported as-is.
- **`source_type` / `source_id` are server-managed and omitted from `BookingCreate`.** They exist on
  the model for the future activity-instance integration; manual bookings leave them null. `BookingRead`
  still exposes them (null for now).
- **`BookingUpdate` is a partial update of the mutable fields only** — `title`, `description`,
  `project`, `projectId`, `projectType`, `product`, `productId`, `tags`, `startDate`, `endDate`,
  `color` (the legacy PATCH body, `routes.ts:3506`). `user_id` / `source_type` / `source_id` / `id` /
  timestamps are **not** client-writable. A null on a NOT NULL column (`title` / `startDate` /
  `endDate`) is rejected (`validation_error`); a null on a nullable field clears it; an omitted key
  leaves the stored value unchanged.
- **Status codes** match the superapp convention (events/tasks): `POST` → 200 with the created body,
  `DELETE` → 204. (Legacy used 201 / `{success:true}`.)

# Out of scope

- Any `Booking` model/column change or migration (the model + table already exist).
- Read-time project/product name resolution / orphan detection (bookings are denormalized passthrough).
- Activity-instance auto-creation of bookings and the `source_type='activity_instance'` flow (Phase 4).
- Calendar cache invalidation (no cache in the superapp), shared-calendar bookings, the React UI, ETL.

# Acceptance criteria

- [ ] `GET /api/bookings?startDate=&endDate=` returns the caller's bookings fully inside the window,
      ordered by `start_date`; omitted/malformed dates fall back to the default range.
- [ ] `GET/PATCH/DELETE /api/bookings/{id}` act only on the caller's booking; a missing or non-owned
      id → 404 `not_found` (no cross-tenant access).
- [ ] A booking that overlaps the window but is not fully contained (e.g. `start_date` before the
      window) is **excluded** (strict containment, not overlap).
- [ ] `POST /api/bookings` requires `title` + `startDate` + `endDate`, defaults `color` to `#f43f5e`,
      stores the denormalized `project`/`product`/`projectType` + `tags` verbatim, and returns
      `BookingRead` (camelCase); `DELETE` → 204.
- [ ] `PATCH /api/bookings/{id}` applies the provided mutable fields and returns `BookingRead`;
      omitted keys stay unchanged, an explicit null clears a nullable field, a null on
      `title`/`startDate`/`endDate` → 422, and `userId`/`sourceType`/`sourceId` are not client-writable.
- [ ] A non-null `projectId`/`productId` that is not the caller's own → 400 `related_record_not_found`.
- [ ] `GET /api/calendar/init` now returns the window's bookings as `BookingRead` objects (no longer
      always `[]`), tenant-scoped and windowed identically to `GET /api/bookings`.
- [ ] Typed `AppError` only (no raw `HTTPException`); no PII/token logged.
- [ ] `make verify` green and `alembic check` clean (no model/migration change).
- [ ] Contract tests pin the `BookingRead` camelCase shape and the init `bookings` list.

# Verification commands

```sh
make verify
DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev uv run --frozen alembic check
```
