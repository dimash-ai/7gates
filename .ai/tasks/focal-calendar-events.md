# Goal

Port Focal's **non-recurring calendar-event CRUD** — `GET/POST/PATCH/DELETE /api/events` — from the
standalone Express/Drizzle app onto the Focal FastAPI backend, faithful to the legacy contract. After
this slice, calendar events (without recurrence) are reachable as tenant-scoped, typed FastAPI endpoints
returning the legacy enriched camelCase shape, with the same hierarchy-derived priority and completion
behavior the source applies.

First slice of **Phase 2 — Calendar & scheduling** in
[superapp/apps/focal/docs/MIGRATION_PLAN.md](../../superapp/apps/focal/docs/MIGRATION_PLAN.md) §9 /
[MIGRATION_BREAKDOWN.md](../../superapp/apps/focal/docs/MIGRATION_BREAKDOWN.md) Phase 2 step 1 (“Events
without recurrence”). Phase 1 (spheres, projects, tasks/tags, MindMap) is complete. Builds directly on
`focal-tasks-tags`: it **reuses** the `app/domain/{priority,completion,daterange}.py` modules and the
`projects`/`activities` models + the owned-link ownership pattern (`_require_owned_link`) already landed.

> **Binding contract = the legacy source** (`focal/server/routes.ts` + `focal/server/storage.ts` +
> `focal/shared/schema.ts`); cited line numbers are the authority.
> `superapp/apps/focal/docs/contract-freeze/` is the path/column inventory. Behavior is reverse-engineered
> and **rebuilt idiomatically (router → service → async SQLAlchemy repo), not transliterated** — but must
> match observably (contract tests). Paths are relative to the pipeline root; service at
> `superapp/apps/focal/server`, legacy read-only at `focal/`.

> **Backend-only slice.** No React `features/` UI — the Calendar canvas is a later frontend slice.
> Responses **preserve the legacy camelCase field names** (`startTime`, `endTime`, `projectId`,
> `productId`, `activityId`, `contactIds`, `otherParticipants`, `priorityScore`, `priorityLevel`,
> `projectType`, `project`, `product`, `projectColor`, `isWorkTime`, `projectHasProducts`, `isOrphan`,
> `orphanReason`, …) via Pydantic `by_alias`; request bodies **accept** those aliases (`populate_by_name`)
> and **ignore unknown fields** (`extra="ignore"`).

> **Non-recurring only — the scope boundary.** The legacy `calendar_events` table carries recurrence
> columns (`recurrence`, `recurringEventId`, `recurrenceEndDate`, `recurrenceExceptions`,
> `recurrenceGroupId`, `old_logic`) and a `calendar_event_overrides` table; the list/get handlers expand
> recurring masters into occurrences (`storage.ts:3707`-3767). **All recurrence is DEFERRED** to Phase 2
> step 2. This slice models and serves only the non-recurring event: `recurrence` is effectively `"none"`,
> no occurrence expansion, no overrides table. Google-sync columns (`googleEventId`, `lastSyncedAt`),
> source/CRM columns (`sourceType`, `sourceId`, `crmInteractionId`, the `event_contacts` join table), and
> the legacy denormalized text `project`/`product` columns are likewise **out of scope** (Phases 2-later/3).

> **New table — additive migration.** No `calendar_events` model exists yet (the foundation baseline
> created the Phase-0/1 tables only). This slice adds `app/models/calendar.py::CalendarEvent` and a **single
> additive migration** generated via the sanctioned `alembic revision --autogenerate`, reviewed (schema
> `focal`, indexes, nullability), and committed in-slice so `make verify` + `alembic check` run against
> it. Unlike the MindMap PK swap, this is a plain `create_table` — autogenerate handles it; no hand-authored
> exception.

> **Tenant model + the legacy security fix.** Every endpoint is scoped to the JWT `sub`
> (`get_current_user_id`); client-supplied `userId` (body or query) is **ignored**. This **fixes the legacy
> `GET /api/events/:id` bug** (`routes.ts:2754` → `storage.getEventEnriched(id)` with **no ownership
> check**, `storage.ts:3778`): a `GET`/`PATCH`/`DELETE` on an event missing **or owned by another user**
> returns the typed `not_found` (404). The `:id` path param is an opaque `str` (never coerced → never a
> framework `422`).

> **Error envelope (this slice's contract):** every business error is a typed `AppError` subclass mapped to
> `{error:{code,message}}` (no raw `HTTPException`). `not_found` (404) for a `GET`/`PATCH`/`DELETE` on a
> missing/non-owned `:id`. `validation_error` (422) for a missing required field (`title`/`date`/`startTime`
> on create), a malformed **body** `date` (not `YYYY-MM-DD`) or `startTime`/`endTime` (not `HH:MM`), or
> `endTime` not strictly after `startTime` (a malformed **list-query** `startDate`/`endDate` is *not* a 422 —
> it falls back to the default window, see List). `related_record_not_found` (400) when a supplied `projectId`/`productId`/
> `activityId` does not exist **or is not owned** by `sub` (reusing `RelatedRecordNotFoundError`; this
> replaces the legacy raw Postgres `23503` → 400 handling, `routes.ts:2829`).

# Scope

**Domain model + the additive migration**

- New `app/models/calendar.py::CalendarEvent` → table `focal.calendar_events`, `TimestampMixin` +
  `__table_args__ = ({"schema": "focal"},)`, `id` a UUID `String` PK (`default=lambda: str(uuid4())`),
  matching the `app/models/tasks.py` conventions. **Non-recurring column set only:**
  - `user_id` (String, index, not null)
  - `title` (Text, not null), `date` (Date, not null), `start_time` (String(5), not null),
    `end_time` (String(5), nullable)
  - `description` (Text), `location` (Text), `color` (String(20)), `timezone` (String(50)),
    `other_participants` (Text)
  - `priority` (String(10), not null, default `"medium"`), `priority_score` (Float, not null,
    default `0.5`), `priority_level` (String(10), not null, default `"medium"`) — **server-computed**
    (see Priority), `status` (String(20), not null, default `"planned"`, **free-form — no enum**),
    `completed` (Boolean, not null, default `False`), `completed_at` (DateTime tz, nullable)
  - `tags` (JSONB, not null, default `list`), `contact_ids` (JSONB, not null, default `list`)
  - `project_id`, `product_id` (`ForeignKey("focal.projects.id", ondelete="SET NULL")`), `activity_id`
    (`ForeignKey("focal.activities.id", ondelete="SET NULL")`) — each nullable + indexed, **matching the
    shipped `tasks` model and the legacy schema** (`tasks.py:31`-39; legacy calendar_events FKs,
    `schema.ts:279`-380). A deleted linked project/product/activity is **auto-nulled** (`ON DELETE SET
    NULL`), so the event then reads as **orphaned** via the null id (`isOrphan`/`"noProject"` once
    `project_id` is null) — faithful to legacy. Ownership is **also** validated at the service layer (like
    `tasks`) so a create/patch with a missing or non-owned link → `related_record_not_found` (400). Note the
    enrichment keys off `project_id`/`product_id`, never `activity_id` (see Enriched read).
  - Indexes mirroring the legacy: `user_id`, `date`, `project_id`, `product_id`, `activity_id`,
    `completed_at` (`schema.ts:279`-380 index block).
- **Deferred columns are NOT modeled** in this slice (expand→contract; later slices add them additively):
  recurrence (6 cols), Google-sync (`google_event_id`, `last_synced_at`), source/CRM (`source_type`,
  `source_id`, `crm_interaction_id`), and the legacy denormalized text `project`/`product`.
- **Migration:** `uv run alembic revision --autogenerate -m "calendar events"`, review the generated
  `create_table` (focal schema, indexes, nullability — column defaults stay ORM-side Python defaults, the
  existing focal convention e.g. `default=utcnow`/`default=list`, not PG `server_default`), commit;
  `alembic upgrade head` + `alembic check`
  clean. **RLS out of scope** (aligns with the Phase-1 slices) — tenant isolation enforced at the app layer
  and tested; RLS lands in the later dedicated step.

**Priority — `computeEventPriorityFromHierarchy` (`storage.ts:126`-138, called at `:955`/`:3453`)**

- Event priority is a **first-valid cascade down the hierarchy**: `priority_level = activity.priority ??
  product.priority ?? project.priority ?? "medium"` (each normalized — only `high`/`medium`/`low` count,
  else fall through); `priority_score = priority_to_score(level)` (`high`→1.0, `low`→0.0, else 0.5);
  `priority == priority_level`. **Distinct from tasks** — *no* mission/urgency/energy term and *no* sphere
  `max` (the legacy comment, `storage.ts:122`-125, says so explicitly). Add a small
  `event_priority_from_hierarchy(...)` to `app/domain/priority.py` reusing the existing `priority_to_score`;
  do **not** call the task `priority_score`.
- Computed on **create**, and **recomputed on every update** from the **merged** hierarchy state: the
  legacy rebuilds `merged = {...current, ...updates}` and recomputes from `merged.projectId/productId/
  activityId` (`storage.ts:3935`-3941), so the recompute runs whether or not the links changed (idempotent
  when they didn't). A **client-supplied `priority` is ignored** (create overwrites it with the computed
  value, `storage.ts:3828`; update sets the computed value, `storage.ts:3950`).
- **Event hierarchy resolution for priority — event-specific (includes the activity), priority context
  ONLY:** the shipped `tasks._hierarchy_context` **defers** the activity (`tasks.py:193`-194 — its
  activity term is inert), so it **cannot** be reused for the activity-aware event path. Load the owned
  `activity` (by `activityId`), then `resolvedProjectId = projectId ?? activity.projectId`,
  `resolvedProductId = productId ?? activity.productId`; a resolved product whose row carries a
  `parentProjectId` resolves the project when none was given; load the owned project/product and feed
  `activity`/`product`/`project` into the cascade above (legacy `getHierarchyContext` +
  `computeEventPriorityFromHierarchy`, `storage.ts:3418`-3438 / `:126`). So an event carrying **only
  `activityId`** derives its **priority** from the activity (and the activity's project/product). **Reuse
  only** the owned-link validation (`_require_owned_link` / `_owned_project` / `_owned_activity`) and the
  `priority_to_score` primitive — **do not modify `tasks`** (if a helper is extracted to share, the existing
  task tests must still pass unchanged). **The enriched read does NOT use this fallback** — it resolves
  project/product from the **stored `projectId`/`productId` only** (`storage.ts:3323`-3327; see Enriched
  read), so an activity-only event reads as orphaned.

**List — `GET /api/events` (`routes.ts:2740`, `storage.getAllEventsEnriched`, `storage.ts:3701`)**

- Returns the user's events as an **array of enriched events**, filtered to a **date window**: optional
  `startDate` / `endDate` (`YYYY-MM-DD`) query params; when **omitted or malformed**, fall back to the
  current-month bounds via `app/domain/daterange.get_date_range` (it treats an unparseable value as absent,
  so **list-query dates never 422** — unlike the create/update **body** `date`). **Order: `date` ASC, then
  `start_time` ASC** (`storage.ts:3771`-3775) — chronological, since times are stored zero-padded (see
  Create), so a plain lexical `start_time` sort is correct even for a single-digit-hour input. Scoped to
  `sub`. (No recurrence expansion — non-recurring rows only.)

**Get — `GET /api/events/:id` (`routes.ts:2754`)**

- Single **enriched** event; **tenant-scoped** → `not_found` (404) if missing or owned by another user
  (the legacy security fix). Opaque `:id`.

**Create — `POST /api/events` (`routes.ts:2770`, `storage.createEventNew`, `storage.ts:3822`)**

- Required: `title` (non-empty after strip), `date` (a valid **calendar** date — format `YYYY-MM-DD` **and**
  a real date; `2026-02-31` rejected, matching legacy `isValidDate`, `userDateTime.ts:17`-20), `startTime`
  (`HH:MM`, 00:00–23:59 — **a single-digit hour like `9:05` is accepted**, matching legacy
  `VALID_TIME_RE = /^([01]?\d|2[0-3]):[0-5]\d$/`, `userDateTime.ts:3`); **`startTime`/`endTime` are
  normalized to zero-padded `HH:MM` on store** (`9:05`→`09:05`) so the `(date, start_time)` list ordering is
  chronological — a documented hardening over the legacy, which stored the raw string and sorted it
  lexically (mis-ordering a single-digit hour). Optional: `endTime` (same `HH:MM`
  rule, **strictly greater** than `startTime` — `timeToMinutes(end) <= timeToMinutes(start)` →
  `validation_error`, `routes.ts:2786`), `description`, `location`, `color`,
  `timezone` (sanitized to a valid IANA zone or null), `otherParticipants`, `tags`, `contactIds`
  (each typed `list[str]` — a non-array or non-string element → `validation_error`; **values are not
  semantically validated** — e.g. `contactIds` are not checked against the contacts table — loose, faithful),
  `projectId`, `productId`, `activityId`
  (each **owned-link validated** → `related_record_not_found` 400 if missing/non-owned), `status`,
  `completed`. Priority is **computed** (above). If `completed` is `true` at creation, **`completedAt` is
  set to now** (`initialCompletedAt`, `storage.ts:3854`). `timezone`, when provided, is sanitized to a valid
  IANA zone or null. **On create, an explicit `null` (or omission) for a defaulted field coalesces to its
  default** — `status`→`"planned"`, `completed`→`false`, `tags`→`[]`, `contactIds`→`[]` (legacy `?? default`,
  `storage.ts:3852`-3855); the **required** `title`/`date`/`startTime` have no default (null/missing →
  `validation_error`). This create-time coalescing is **distinct from PATCH**, where a `null` on those NOT
  NULL fields is rejected. `status` is a **free-form string** (legacy `varchar(20)`, no enum — `storage.ts`
  stores it as-is), so any non-null string **≤ 20 chars** is accepted (default `"planned"`); there is **no
  invalid-`status` 422** for an arbitrary value (an over-length value > 20 chars → `validation_error` from
  the column cap). **Client-writable capped strings are length-validated in the schema to their column caps**
  — `status` ≤ 20 and `color` ≤ 20 → `validation_error` on overflow, so a too-long value never falls through
  to a raw DB length error. Returns the created enriched event, **HTTP 200** (legacy parity — the source
  returns 200, not 201). Scoped to `sub`.

**Update — `PATCH /api/events/:id` (`routes.ts:2882`, `storage.updateEventNew`, `storage.ts:3930`)**

- **Partial-merge** with null-vs-omitted semantics (`model_fields_set`/`exclude_unset`): only provided
  fields are written. Re-validate `date`/`startTime`/`endTime` formats — and a **non-blank `title`** — when
  present (a blank/whitespace `title` → `validation_error`, consistent with create); a provided
  `startTime`/`endTime` is **normalized to zero-padded `HH:MM` on store** (same as create, preserving
  chronological list order); **`timezone`, when provided, is sanitized** to a valid IANA zone or null (same
  as create, `routes.ts:2912`-2914); the **`endTime > startTime`** check uses **effective values** (a
  provided field vs. the stored one when only one side changes, `routes.ts:2920`-2926). Owned-link
  re-validated for any changed
  `projectId`/`productId`/`activityId`; **priority is recomputed from the merged state on every update**
  (above).
- **Explicit `null` handling (so a null can never reach a NOT NULL column):** a `null` on a **NOT NULL**
  field (`title`, `date`, `startTime`, `status`, `completed`, `tags`, `contactIds`) → `validation_error`
  (422), rejected before the DB via a `model_validator(mode="before")` (the same pattern `tasks` uses); a
  `null` on a **nullable** field (`endTime`, `description`, `location`, `color`, `timezone`,
  `otherParticipants`, `projectId`, `productId`, `activityId`) **clears** it (sets NULL); an **omitted**
  field is preserved.
- **Completion transition** (reuse `app/domain/completion.transition_completed_at`): `completed`
  false→true sets `completedAt = now`; true→false clears it; `completed` omitted leaves both untouched
  (`routes.ts:2917`-2918). Returns the updated enriched event (200); `not_found` (404) if missing/non-owned.

**Delete — `DELETE /api/events/:id` (`routes.ts:2838`)**

- **204 No Content**, tenant-scoped → `not_found` (404) if missing/non-owned (the legacy returned
  `{success:true}` 200 and read `userId` from the query; the port standardizes on 204, consistent with the
  node/edge/task deletes, and scopes by `sub`).

**Enriched read — pins the legacy `buildEnrichedEventsFromRows` shape (`storage.ts:3316`-3414)**

- `GET` list and `GET /:id` return the **enriched** shape, using the **legacy field names**:
  - stored core (camelCase): `id`, `userId`, `title`, `date`, `startTime`, `endTime`, `description`,
    `location`, `color`, `timezone`, `otherParticipants`, `tags`, `contactIds`, `priority`,
    `priorityScore`, `priorityLevel`, `status`, `completed`, `projectId`, `productId`, `activityId`,
    `updatedAt`;
  - derived (computed exactly as `tasks` already does — reuse that logic): resolution uses the **stored
    `projectId`/`productId` only** — *not* `activityId` (the activity fallback is priority-context only,
    `storage.ts:3323`-3327), so an **activity-only event** (no stored `projectId`/`productId`) reads as
    `isOrphan=true`, `orphanReason="noProject"`. If `projectId` points to a row whose `parentProjectId` is
    set — i.e. it's a *product* — resolve `productId = that id`, `projectId = its parent`
    (`storage.ts:3346`-3350), then **`project`** (resolved
    project **name**), **`product`** (product **name**), **`projectColor`** (`product.color ?? project.color`,
    `storage.ts:3356`/`:3409`), `projectType` (`mission`/`provision`), `sphere`, `isWorkTime` (default
    `true` when no project, `storage.ts:3353`), `projectHasProducts`, `isOrphan` + `orphanReason`
    (`"noProject"` when no resolved project; `"noProduct"` when the project has products but none is set,
    `storage.ts:3358`-3367).
- **Two intentional, documented deviations from the legacy event enriched shape** (the rest is faithful):
  1. **Add `completedAt` and `createdAt`.** The legacy *event* enriched read omits them
     (`storage.ts:3369`-3414), but they are exposed here for parity with the already-shipped
     `EnrichedTaskRead` and to make the completion transition observable/testable.
  2. **Omit the deferred columns** the legacy still emits — recurrence (`recurrence`, `recurringEventId`,
     `recurrenceEndDate`, `recurrenceExceptions`, `recurrenceGroupId`, `old_logic`, `occurrenceDate`,
     `isRecurringInstance`), source/CRM (`sourceType`, `sourceId`, `crmInteractionId`), and Google
     (`googleEventId`, `lastSyncedAt`) — because those columns are out of scope this slice.
- The exact enriched field set is pinned by a contract test (mirroring the `EnrichedTaskRead` contract).

**Cross-cutting**

- Every endpoint tenant-scoped to `sub`; client `userId` (body/query) ignored; unknown body fields ignored
  (`extra="ignore"`). Async; SQLAlchemy 2.0 + Pydantic v2; service → repo, custom `AppError` only.
  Reuse `app/domain/{priority,completion,daterange}.py` and the `tasks` owned-link helpers (extract/share
  if cleaner — but no behavior change to tasks).

**Tests** (vs local Docker Postgres, mirroring `tests/test_tasks_db.py`)

- Create with all fields → 200, enriched camelCase shape; defaults (`status="planned"`, `completed=false`,
  `tags=[]`, `contactIds=[]`).
- **Priority cascade:** event under an `activity`/`product`/`project` with a set `priority` gets the first
  valid level down activity→product→project; none set → `"medium"`/0.5; recomputed from the merged
  hierarchy on every update; a client-supplied `priority` is ignored.
- **Hierarchy fallback (priority only):** an event with **only `activityId`** derives its **priority** from
  the activity's project/product links (falling through to product/project priority when the activity's own
  is null/invalid); its **enriched** read still reflects the stored ids — with no `projectId`/`productId` it
  reads as `isOrphan`/`"noProject"` (the activity does not supply the enriched project/product).
- **Validation → `validation_error` (422):** missing or **blank** `title` (create and update); a malformed
  **or non-calendar** `date` (e.g. `2026-02-31`); bad `startTime`/`endTime` (a single-digit hour like `9:05`
  is **accepted**); `endTime <= startTime` (incl. the PATCH effective-value case); a non-array or non-string
  `tags`/`contactIds`; an over-length `color` (> 20 chars).
- **Create defaults:** an explicit `null`/omission for `status`/`completed`/`tags`/`contactIds` coalesces to
  the default (`"planned"`/`false`/`[]`/`[]`), not a 422 (distinct from PATCH null handling).
- **Owned-link → `related_record_not_found` (400):** create/patch with a `projectId`/`productId`/
  `activityId` that is missing or owned by another user.
- **Completion transition:** create with `completed=true` sets `completedAt`; PATCH `completed` false→true
  sets `completedAt`, true→false clears it, omitted leaves it.
- **`timezone` sanitization:** an invalid `timezone` is coerced to null on **both create and PATCH** (a
  valid IANA zone is kept).
- **PATCH null handling:** `null` on a NOT NULL field (`title`/`date`/`startTime`/`status`/`completed`/
  `tags`/`contactIds`) → `validation_error`; `null` on a nullable field (e.g. `endTime`, `description`,
  `projectId`) clears it; omitted preserves.
- **List:** date-window filtering (in/out of `startDate`..`endDate`); default window when omitted; **a
  malformed `startDate`/`endDate` falls back to the default window (not `422`)**; **order `date` then
  `startTime`** asserted; tenant-scoped (only `sub`'s events).
- **Time normalization + ordering:** `startTime` `9:05` is stored as `09:05` (on **both create and PATCH**);
  on the same date, an event at `9:05` lists **before** one at `10:00` (chronological, not
  lexical-on-raw-input).
- **Free-form `status`:** a non-enum value (e.g. `status="rescheduled"`) round-trips on create (200) and on
  patch — no `planned`/`confirmed` enum rejection; an **over-length** `status` (> 20 chars) →
  `validation_error`.
- **Link nulled on deletion (`ON DELETE SET NULL`):** create an event linked to a `project`, delete that
  project, then read the event — its `projectId` is **null** (auto-nulled by the FK) and the enriched read
  renders it orphaned (`isOrphan`/`"noProject"`).
- **Delete:** a successful `DELETE /api/events/:id` returns **204 No Content** and the event is gone (a
  subsequent `GET` → 404).
- **Tenant isolation / legacy fix:** a second user's `GET`/`PATCH`/`DELETE` of the first user's event →
  `not_found` (404).
- **Opaque id:** unknown `:id` on `GET`/`PATCH`/`DELETE` → typed `not_found` (404), never a framework `422`.
- Contract test pins the enriched camelCase shape + the error envelope (404/422/400).

# Out of scope

- **Recurrence** (the 6 recurrence columns, occurrence expansion, `calendar_event_overrides`) — Phase 2
  step 2, the next slice.
- **Calendar init payload** (`/api/calendar*`), **bookings**, **shared calendars + participants/RBAC**,
  **meeting requests**, **focal-local CRM** (`contacts`/`interactions`/`event_contacts`) — later Phase 2 steps.
- **Google Calendar sync** (`googleEventId`/`lastSyncedAt`, auto-sync side effects) — Phase 3.
- **Source/CRM columns** (`sourceType`/`sourceId`/`crmInteractionId`) and the **legacy denormalized text
  `project`/`product`** columns.
- **AI-agent webhooks**, **calendar cache invalidation**, the **in-process schedulers** — not ported.
- **`contactIds` existence validation** — stored as-is (loose), faithful; CRM-aware validation is later.
- **RLS policies**, the **React Calendar UI**, ETL (§6), `foc_`/AI (Phases 7–8), shared-package extraction.

# Acceptance criteria

- [ ] `cd superapp/apps/focal/server && make verify` is green (ruff + mypy + pytest); any `uv.lock` change is
      committed; `uv run alembic check` shows no model/migration drift (incl. the new `calendar_events`
      additive migration).
- [ ] **New `focal.calendar_events` table** via a reviewed autogenerated migration (focal schema, indexes,
      ORM-side column defaults); `alembic upgrade head` applies it and `alembic check` is clean.
- [ ] Event CRUD works at the legacy paths (`GET/POST /api/events`, `GET/PATCH/DELETE /api/events/:id`),
      tenant-scoped to `sub`; responses are the **enriched** camelCase shape using the legacy names
      (`project`/`product`/`projectColor`/…), with the two documented deviations (adds `completedAt`/
      `createdAt`; omits the deferred recurrence/source/Google columns) (contract test).
- [ ] **Create** requires `title`/`date`/`startTime`; validates `date`=`YYYY-MM-DD`, times=`HH:MM`, and
      `endTime` **strictly after** `startTime`; returns **200** (tested).
- [ ] **Priority is server-computed** via the event cascade `activity → product → project → "medium"`
      (`priority_to_score` for the score), distinct from the task formula; **recomputed from the merged
      hierarchy on every update**; a client `priority` is ignored (tested).
- [ ] **Hierarchy fallback (priority only):** an event with only `activityId` derives its **priority** from
      the activity (and the activity's project/product) via an **event-specific** resolver — the shipped task
      resolver defers the activity, and **task behavior is unchanged** (task tests still pass) — falling
      through to product/project priority when the activity's own is null/invalid; its **enriched** read
      reflects the stored ids only (an activity-only event is `isOrphan`/`"noProject"`) (tested).
- [ ] **Owned-link**: a `projectId`/`productId`/`activityId` that is missing or non-owned →
      `related_record_not_found` (400), not a raw DB error (tested).
- [ ] **PATCH** is partial-merge (null-vs-omitted); `timezone` is sanitized; the `endTime > startTime`
      check uses effective values; the **completion transition** sets `completedAt` on create-when-completed
      and on false→true, clears it on true→false, leaves it when omitted (tested).
- [ ] **PATCH explicit `null`:** rejected with `validation_error` on a NOT NULL field
      (`title`/`date`/`startTime`/`status`/`completed`/`tags`/`contactIds`); clears a nullable field;
      omitted preserves — no null reaches a NOT NULL column (tested).
- [ ] **List** filters to the date window (default current month; a **malformed** `startDate`/`endDate`
      falls back to the default window, **not** `422`), is ordered **`date` ASC then `startTime` ASC**, and
      is tenant-scoped (tested).
- [ ] **Time normalization:** `startTime`/`endTime` accept a single-digit hour and are stored zero-padded
      (`9:05`→`09:05`) on **create and PATCH**; same-date events sort chronologically (`9:05` before `10:00`)
      (tested).
- [ ] **Free-form `status`:** a non-enum value (e.g. `"rescheduled"`) is accepted and persists on create and
      patch (200) — no `planned`/`confirmed` enum rejection; an over-length value (> 20 chars) →
      `validation_error` (tested).
- [ ] **`SET NULL` on linked-record deletion:** after a linked **`project`** is deleted, the event's
      `projectId` is auto-nulled (FK `ON DELETE SET NULL`, matching `tasks` + legacy) and the enriched read
      renders it orphaned (`isOrphan`/`"noProject"`) (tested); `product`/`activity` FKs use the same rule.
- [ ] **Delete** returns **204 No Content** and the event is then gone (`GET` → 404) (tested).
- [ ] **Tenant isolation / legacy fix:** a second user's `GET`/`PATCH`/`DELETE` of the first user's event →
      `not_found` (404); an unknown/malformed `:id` → typed `not_found`, never a framework `422` (tested).
- [ ] A body/query `userId` ≠ `sub` is served against `sub`'s data only; unknown body fields ignored
      (`extra="ignore"`) (tested).
- [ ] Every business-logic error raises a typed `AppError` (`{error:{code,message}}`), never a raw
      `HTTPException`; no PII logged on error paths (review + grep).
- [ ] No recurrence/overrides, no Google/CRM/source columns, no calendar-init/bookings/shared-calendar
      route, no React UI — nothing out of scope is added.

# Verification commands

```sh
# focal's documented local-first exception (apps/focal/CLAUDE.md): Postgres + Redis via compose
docker compose -f superapp/apps/focal/docker-compose.yml up -d

cd superapp/apps/focal/server
uv sync --frozen
uv run alembic upgrade head     # applies the new calendar_events additive migration
make verify
uv run alembic check            # no drift between models and committed migrations
```
