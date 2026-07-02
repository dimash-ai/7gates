# Summary

Implement the `focal-tasks-tags` backend slice on the existing scaffold (the `tasks` + `task_tags`
models already landed in `focal-foundation`; the error envelope — `AppError`+`details`+the
`RequestValidationError` handler — and `get_current_user_id` already landed in `focal-spheres-projects`;
`app/api/tags.py`+`app/services/tags.py` are the router→service→async-repo pattern to mirror). Four
independently-green slices: **(1) domain primitives + schemas** — pure `daterange`, `priority`, and
`completion` modules (unit-tested, incl. the priority oracle table) + task Pydantic schemas + one new
typed `AppError`; **(2) tags reconcile** — bring the bootstrap `/api/tags` to legacy parity (require
`color`, length caps, non-blank, POST→200); **(3) tasks reads** — `GET /api/tasks` (enriched + date
window) and `GET /api/tasks/:id`, tenant-scoped; **(4) tasks writes** — create/update/delete with the
completion transition, the partial-PATCH null-vs-omitted contract, link-ownership, and server-side
priority. Every endpoint is tenant-scoped to the JWT `sub`, ignores any client `userId`, treats `:id` as
an opaque string, and raises only typed `AppError`. The multi-factor priority model is ported over
project/product/sphere with the `activity` term = 0 (Phase-4 deferral). Task:
[focal-tasks-tags.md](../tasks/focal-tasks-tags.md). Binding contract: legacy
`focal/server/{routes,storage}.ts` + `focal/server/utils/functions.ts` + `contract-freeze/`.

## Decisions (design + resolving Gate-1 carryovers)

- **Reuse the existing error envelope; add exactly one code.** `app/errors.py` already has `AppError`
  (with `details`), `NotFoundError`→404, `ValidationError`→422, and both handlers (`app_error_handler`,
  `validation_exception_handler` → `validation_error` 422). Add **`RelatedRecordNotFoundError`→400
  (`related_record_not_found`)** for a create/update link that doesn't resolve to one of the user's own
  rows. Mapping: task/tag missing-or-non-owned → `not_found` (404); bad input (missing `title`, bad
  `dueDate`/`dueTime`, non-array/non-string `tags`, missing/over-long tag `name`/`color`,
  null/blank `title` on PATCH) → `validation_error` (422); non-owned link → `related_record_not_found`
  (400). No raw `HTTPException` anywhere.
- **Opaque `:id` (closes the Gate-1 envelope hole).** Task and tag path params are declared `str` (never
  a typed/coerced `UUID`/`int`), so an unknown or malformed id flows through the scoped lookup to the
  typed `not_found` (404) — never FastAPI's default path-validation 422. Applies to every
  `GET`/`PATCH`/`DELETE /:id`.
- **PATCH null-vs-omitted via `model_fields_set`.** `TaskUpdate`/`TagUpdate` are all-optional Pydantic v2
  models; the service applies `payload.model_dump(by_alias=False, exclude_unset=True)` so **only keys the
  client actually sent** are written — an omitted key is left unchanged, an **explicit `null` on a
  nullable scalar** (`dueDate`,`dueTime`,`description`,`projectId`,`productId`,`activityId`,`contactId`,
  `goalId`) writes `NULL`. **`tags`** is `list[str]` (a `field_validator` rejects `null` and non-string
  elements → `validation_error`; `[]` empties); **`title`** sent `null`/blank → `validation_error`
  (a `NOT NULL` column can't be cleared). `completedAt`/`priorityScore`/`priorityLevel` are **not schema
  fields** (never client-settable); a body `userId` is dropped at the schema boundary.
- **Completion transition is server-owned** (`app/domain/completion.py`, pure; ports
  `transitionCompletedAt`, `storage.ts:763`-`772`): `next` undefined/null → no change; `false→true` →
  `completed_at = now()`; `true→false` → `NULL`; no state change → no change. The router/schema never
  accept `completedAt`. Reuses the legacy `storage.updateTaskCompletedAt.test.ts` as the oracle.
- **Date window** (`app/domain/daterange.py`, pure; ports `getDateRange`,
  `focal/server/utils/functions.ts`): `get_date_range(start, end, *, today) -> (from, to)` — when both
  are present **and parseable** `YYYY-MM-DD`, use them; when either is missing **or malformed**, default
  both to `today`'s calendar month (`YYYY-MM-01` … month's last day). *Documented intentional hardening:*
  legacy only falls back on *missing* and 500s on a malformed value; treating malformed as missing keeps
  the endpoint typed. `today` is injected (a `current_utc_date` dependency, overridden in tests) so the
  month boundary is deterministic; the row filter is `(due_date BETWEEN from AND to) OR due_date IS NULL`
  (`storage.ts:4621`-`4627`), so undated tasks always return and `from>to` returns only undated.
- **Priority model** (`app/domain/priority.py` = pure scoring; hierarchy *resolution* in the service).
  Pure (unit-tested with the oracle): `priority_to_score`, `urgency_score(due_date,*,today)`
  (no/unparseable → 0.1; day-delta ≤0→1.0, 1→0.9, ≤3→0.7, ≤7→0.5, ≤14→0.3, else 0.1),
  `max_hierarchy_priority([...])`, `priority_score(mission,hierarchy,urgency,energy)` =
  `clamp(0.4·m+0.3·h+0.2·u+0.1·e,0,1)` with level `≥0.6 high / ≥0.3 medium / else low`
  (`storage.ts:140`-`175`). The service `_hierarchy_context` ports `getHierarchyContext`
  (`storage.ts:931`-`945`), all lookups **scoped to `sub`**: resolve the `product` (by `productId`, a
  `projects` row); then `project` = **`projectId` if given, else the product's `parent_project_id`**
  (the legacy product→parent fallback, `storage.ts:936`-`938`); then the **sphere** — a `life_spheres`
  row by `name == project.sphere` **only when `project.is_work_time is False` and `project.sphere` is
  set** (`storage.ts:941`-`943`). **`activity` = `None`** (Phase-4 deferral → its hierarchy term is 0;
  the legacy `activity?.projectId/productId` fallbacks are inert here). **Nullish-coalescing (first
  non-`None`), NOT boolean `or`** (`storage.ts:967`,`976`): `project_type = project.project_type if
  project is not None else (product.project_type if product is not None else None)` (mission iff
  `== "mission"`); `gives_energy = project.gives_energy if project is not None else (sphere.gives_energy
  if sphere is not None else False)` — so a project with `gives_energy=False` scores energy 0 even when
  its sphere gives energy. (Enrichment's project join stays `projectId`-only, `storage.ts:4620` — the
  product→parent fallback is **priority-only**; a product-only task is still `isOrphan=noProject` in the
  enriched read.) Computed on every create/update; the user-set `priority` string is stored separately
  and **not** an input to the model.
- **Tenant tightening (Gate-1 ruling).** The legacy task-by-id endpoints and links are unscoped
  (`storage.ts:4691`/`4774`/`4801`, `routes.ts:3019`-`3032`); here every read/update/delete and every
  `projectId`/`productId`/`activityId` link is scoped to `sub` (non-owned == missing, no existence leak),
  and the enrichment left-join resolves only the user's **own** projects. `activityId` ownership is a
  lightweight query against the (already-modelled) `activities` table — no activities exist yet, so a
  non-null `activityId` resolves to not-found in practice.
- **camelCase** via `ConfigDict(alias_generator=to_camel, populate_by_name=True, extra="ignore")`:
  responses serialize camelCase (`by_alias`), requests accept camelCase + snake_case, and unknown fields
  (incl. `status`/`completed`/`eventId` on **create**, and `userId` anywhere) are ignored.
- **DB-backed tasks service, no in-memory fallback** (like spheres/projects): the behavior here
  (enrichment join, FK link-ownership, the date-window query) is DB-semantic; tests run against local
  Docker PG. Tags keeps its existing in-memory + SQLAlchemy repos (validation moves to the shared schema,
  so both honor it).
- **Tags reconcile, not rebuild.** Existing list already orders `created_at` ASC (`services/tags.py:79`)
  and returns `{id,name,color}` (`TagRead`). Deltas only: make `color` **required** + `≤20`, `name`
  `≤50` + non-blank (schema-level → both repos); on `PATCH`, `name`/`color` are optional but an
  **explicit `null` (distinct from omission, via `model_fields_set`) → `validation_error`**, as is a
  blank/over-long value — today `TagUpdate` accepts `None` and the service treats it as a silent no-op
  (`schemas/tags.py:10`, `services/tags.py:98`), which the task's PATCH rule forbids; an **empty body**
  stays a no-op returning the unchanged tag; and **POST returns 200** (drop the `201` at `api/tags.py:34`
  — legacy `res.json` is 200).

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/server/app/errors.py` | modify | add `RelatedRecordNotFoundError`→400 (`related_record_not_found`) |
| `superapp/apps/focal/server/app/models/tasks.py` | (verify) | reconcile vs `contract-freeze/tables.json`; no functional change expected |
| `superapp/apps/focal/server/app/schemas/tasks.py` | add | `TaskCreate`/`TaskUpdate`/`TaskRead`/`EnrichedTaskRead` (camelCase aliases, `populate_by_name`, `extra="ignore"`; `tags: list[str]` validator; `title`/`dueDate`/`dueTime` validators) |
| `superapp/apps/focal/server/app/schemas/tags.py` | modify | `color` required + `≤20`, `name` `≤50` + non-blank; `TagUpdate` name/color non-blank when provided |
| `superapp/apps/focal/server/app/domain/daterange.py` | add | pure `get_date_range(start,end,*,today)` (port `getDateRange`; missing/malformed → month) + parse helper |
| `superapp/apps/focal/server/app/domain/completion.py` | add | pure `transition_completed_at(prev,next,*,now)` (port `transitionCompletedAt`) |
| `superapp/apps/focal/server/app/domain/priority.py` | add | pure scoring (`priority_to_score`/`urgency_score`/`max_hierarchy_priority`/`priority_score`) |
| `superapp/apps/focal/server/app/services/tasks.py` | add | DB-backed service: list (date-window+enriched), get, create, update (partial), delete; `_hierarchy_context` + `_require_owned_link` |
| `superapp/apps/focal/server/app/services/tags.py` | (verify) | validation now schema-level; no logic change expected |
| `superapp/apps/focal/server/app/api/tasks.py` | add | thin `tasks` router; `:id` as `str`; `startDate`/`endDate` query params |
| `superapp/apps/focal/server/app/api/tags.py` | modify | POST status 200 (drop `HTTP_201_CREATED`); `tag_id` already `str` |
| `superapp/apps/focal/server/app/deps.py` | modify | add `current_utc_date()` dependency (UTC `date.today`), overridable in tests |
| `superapp/apps/focal/server/app/main.py` | modify | include the `tasks` router (tags already included; handlers already registered) |
| `superapp/apps/focal/server/tests/test_daterange.py` | add | unit: missing/malformed→month, both honored, `from>to` |
| `superapp/apps/focal/server/tests/test_completion.py` | add | unit: the 4 transition cases (port the legacy test) |
| `superapp/apps/focal/server/tests/test_priority.py` | add | unit: the priority **oracle table** |
| `superapp/apps/focal/server/tests/test_tasks_db.py` | add | DB: CRUD + date-window + enrichment + completion + PATCH null-vs-omitted + link-ownership + tenant + opaque id |
| `superapp/apps/focal/server/tests/test_tags.py` / `test_tags_db.py` | modify | extend for the reconciled validation (required/over-long `color`, non-blank `name`, POST 200) |
| `superapp/apps/focal/server/tests/test_contracts.py` | modify | add task/tag camelCase shapes, the `related_record_not_found` envelope, opaque-id→404, ignored client `userId` |

# Implementation slices

Each slice is independently reviewable (gate-code → fix loop) and leaves `make verify` green.

1. **Domain primitives + schemas (no endpoints).** Add `app/domain/{daterange,completion,priority}.py`
   (pure) + their unit tests, including the **priority oracle table** (urgency thresholds, mission vs
   provision, energy on/off, hierarchy-max, 0.6/0.3 cutoffs) and the ported completion test. Add
   `app/schemas/tasks.py` (camelCase aliases + `populate_by_name` + `extra="ignore"`; `tags: list[str]`
   validator rejecting `null`/non-string; `title` non-blank; `dueDate`/`dueTime` format validators) and
   `RelatedRecordNotFoundError` in `app/errors.py`. *Verify:* unit tests green; schemas round-trip
   camelCase↔snake; `make verify` green.
2. **Tags reconcile to parity.** Tighten `app/schemas/tags.py` (`color` required + `≤20`, `name` `≤50` +
   non-blank, `TagUpdate` non-blank-when-provided) and switch `app/api/tags.py` POST to status 200.
   Extend `test_tags*` + `test_contracts` (required/over-long `color` → `validation_error`; blank `name`
   → `validation_error`; list ordered `created_at` ASC; `{id,name,color}` shape; `{"success":true}` on
   delete; opaque `tag_id` → 404). *Verify:* tag tests green at parity; no rebuild of passing behavior.
3. **Tasks reads.** `app/services/tasks.py` (`list_tasks` with `get_date_range(today=current_utc_date)`
   + the enriched left-join to the user's **own** projects + orphan flags; `get_task` scoped) and
   `app/api/tasks.py` (`GET /api/tasks` with `startDate`/`endDate`; `GET /api/tasks/{id}` opaque `str`).
   Include the router in `main.py`; add `current_utc_date` to `deps.py`. *Verify:* `test_tasks_db` read
   cases green — date-window (no-params→current month + all undated; both honored; missing/malformed→
   fallback; `from>to`→undated), `EnrichedTask` shape, tenant isolation, opaque-id→404.
4. **Tasks writes.** Extend the service: `create_task` (require non-blank `title`; validate
   `dueDate`/`dueTime`; default `priority="medium"`,`tags=[]`; `_require_owned_link` for
   `projectId`/`productId`/`activityId` → `related_record_not_found`; `contactId`/`goalId` stored as-is;
   `_hierarchy_context`→priority; `completed=false`), `update_task` (partial via `exclude_unset`;
   completion transition; priority recompute; link-ownership; `title` null/blank → `validation_error`),
   `delete_task` (→ `{"success":true}`). Add the write routes. *Verify:* `test_tasks_db` write cases
   green — create defaults/validation/links/priority, PATCH null-vs-omitted, completion transition,
   delete; `make verify` **plus `uv run alembic upgrade head` + `uv run alembic check`** green end-to-end
   (no model/migration drift — the task's verification commands; `make verify` alone does not run
   `alembic check`, `Makefile:14`).

# Tests

- **Date-window unit** (`test_daterange.py`): no params → current month; both valid honored; one
  missing/malformed → current month; `from>to` handled. *Proves `getDateRange` parity + the hardening.*
- **Completion unit** (`test_completion.py`, ports `storage.updateTaskCompletedAt.test.ts`): set on
  `false→true`, clear on `true→false`, untouched when `completed` absent or unchanged. *Proves the
  `completed_at` contract.*
- **Priority oracle** (`test_priority.py`): a parametrized table over urgency day-deltas
  (no-date/0/1/3/7/14/>14), `mission` vs `provision`, `gives_energy` on/off, the hierarchy-max, and the
  `0.6`/`0.3` level cutoffs; the `activity` term is 0. *Proves the scoring math.*
- **Tasks CRUD + tenant** (DB): create/list/get/patch/delete at the `routes.json` paths, scoped to `sub`;
  a second user gets `not_found` for the first user's task and cannot mutate/delete it; a body/query
  `userId ≠ sub` is ignored. *Proves the tightened tenant contract + client-compat.*
- **Create ignores extras** (DB): a create body carrying `status`/`completed`/`eventId` stores the
  defaults (`pending`/`false`) and no `eventId` — those inputs have no effect (`extra="ignore"`).
- **Date window** (DB, injected `current_utc_date`): no params → due-in-month + **all** undated, ordered
  `created_at` DESC; explicit range honored; missing/malformed → month; `start>end` → only undated.
- **Enrichment** (DB): `projectType`/`sphere`/`projectName`/`isWorkTime`/`projectHasProducts` and
  `isOrphan`/`orphanReason` (`noProject`, `noProduct`); the join never returns another user's project.
- **Completion + priority** (DB): toggling `completed` moves `completed_at` per the transition and never
  via a client `completedAt`; `priority_score`/`priority_level` recompute on create/update per the model.
- **Product-only priority context** (DB): a task with `productId` and no `projectId` resolves the project
  via `product.parent_project_id` for the priority hierarchy (`storage.ts:936`-`938`); the enriched read
  still reports `isOrphan=noProject` (the join is `projectId`-only). *Proves the product→parent fallback.*
- **PATCH null-vs-omitted** (DB): explicit `null` clears a nullable scalar; omission preserves;
  `tags:null` → `validation_error`, `tags:[]` empties; `title` null/blank → `validation_error`.
- **Link existence+ownership** (DB): a create/update `projectId`/`productId`/`activityId` not owned by
  `sub` → `related_record_not_found` (identical for missing vs non-owned); `contactId`/`goalId` stored
  unvalidated; a user-owned `productId` need not be a child of `projectId`.
- **Opaque id** (DB): an unknown/malformed `:id` on any task/tag `GET`/`PATCH`/`DELETE` → typed
  `not_found` (404), never FastAPI's path-validation 422.
- **Tags parity** (`test_tags*` + contracts): `color` required + `≤20`, `name` `≤50` + non-blank,
  missing/over-long → `validation_error` (422); POST 200; list `created_at` ASC; `{id,name,color}`;
  `{"success":true}` on delete.
- **Contracts** (`test_contracts.py`): responses camelCase; the `{error:{code,message,details?}}`
  envelope for `not_found`/`validation_error`/`related_record_not_found`. *Proves the envelope + shapes.*
- **No-PII / typed-error sweep** (review + `grep`): no raw `HTTPException` in business code; no
  token/email/title logged on any path (log only `user_id`/ids).

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| Task/tag missing, or owned by another user (incl. unknown/malformed `:id`) | `NotFoundError("not_found")` | service (scoped lookup) → AppError handler | 404 `{error:{code:"not_found",…}}` (identical missing vs non-owned) |
| Create/update link `projectId`/`productId`/`activityId` not one of the user's own rows | `RelatedRecordNotFoundError("related_record_not_found")` | tasks service (`_require_owned_link`) | 400 (identical missing vs non-owned — no leak) |
| Missing `title`; bad `dueDate`/`dueTime`; `tags` not a string array; PATCH `title` null/blank; tag missing/over-long `name`/`color` | `ValidationError("validation_error")` or `RequestValidationError` | schema / service → both handlers | 422 `{error:{code:"validation_error",message,details?}}` |
| Body carries `completedAt`/`priorityScore`/`userId`/`status`/`completed` on create | ignored (`extra="ignore"`; not schema fields) | schema boundary | field has no effect; defaults/transition apply |
| Mid-write DB failure | exception → transaction rollback | tasks service (`async with` txn) | transaction rolls back (no partial write); an *unexpected* error surfaces as the framework 500 — only **business** errors are typed `AppError` |

# Review lenses (pre-answer)

- **Scope / strategy.** Minimum viable: reuses the shipped models + the error envelope + the tags
  router/service pattern; adds 3 pure domain modules + one DB-backed service + one router + one error
  code, and reconciles the existing tags surface. No new abstraction. `taskSort`, the `activity`
  priority branch, RLS, `eventId` linking, and the React UI stay deferred (their homes are named). All
  additive + reversible (routers/schemas additive; no schema/migration change — the `tasks`/`task_tags`
  models already exist and need no edit).
- **Architecture.** router→service→async SQLAlchemy (mirrors `tags.py`); one tenant dependency (`sub`);
  pure domain math isolated + unit-tested, DB-only concerns (joins, link-ownership, txn) in the service;
  every unhappy path is a typed `AppError` (map above), never a raw `HTTPException`; the date/now clock
  is injected for deterministic tests.
- **Completeness.** Tenant tightening (by-id + links + enrichment join), the date-window default + the
  malformed-hardening, PATCH null-vs-omitted, the completion transition, the multi-factor priority with
  the activity deferral, opaque ids, and the tags parity deltas — all enumerated + each mapped to a named
  test.
- **Tests & verification.** Each acceptance criterion maps to a test (above); pure modules are unit-tested
  (incl. the priority oracle); DB tests run under `make verify` (local Docker PG/Redis) with an injected
  `current_utc_date`; no `eventId`/activities/RLS work leaks in.

# Risks & migrations

- **No schema change / no migration.** `tasks` + `task_tags` already exist from `focal-foundation`; this
  slice adds no column/constraint, so `alembic check` stays clean. (If model reconciliation against
  `contract-freeze/tables.json` surfaces a real drift, that's a separate flagged migration, not assumed
  here.)
- **PATCH null-vs-omitted correctness** is the subtle part: it rides on Pydantic `model_fields_set` /
  `exclude_unset`. Mitigation: explicit DB tests for omitted-preserves vs null-clears vs `tags` rules.
- **Priority parity is partial by decision** (Gate-1): the `activity` hierarchy term is 0 until Phase 4;
  documented in the task + here, and the oracle test asserts the 0-activity behavior so it can't silently
  regress when activities land.
- **Date "today" timezone**: computed in UTC via the injected clock (legacy used server-local); a
  documented, tested choice — the only observable difference is the month-boundary edge, covered by the
  injected-clock tests.
- **Tags POST status change (201→200)** could affect a client asserting 201; the legacy returns 200 and
  the contract test pins 200, so this is the parity-correct direction.
- **Shared-DB safety.** No new schema/table; the `focal`-scoped Alembic filter is untouched; all queries
  filter by `user_id == sub`.

# Scope check

- [x] Matches the task's Scope and Out of scope (tasks + tags reconcile only; `taskSort`, mindmap, goals
      CRUD, `eventId` linking, activities, RLS, frontend, `foc_`/AI, ETL, shared-package extraction stay out).
- [x] Small enough to review per slice — 4 sequenced, each green + independently gate-coded.
- [x] Size smell: no new service/abstraction; no migration; one new error code; tags is reconcile-only.

# Out of scope

- `taskSort` (client-side comparator → frontend tasks slice); the `activity` branch of the priority model
  + recompute-on-parent-change (Phase 4 / events); `eventId` linking (Phase 2 calendar); RLS (dedicated
  enablement step); `mindmap` nodes/edges/init (next slice); goals REST CRUD (none in source); the React
  frontend; Google/habits/dashboard/push (Phases 3–5); `foc_`/AI (Phases 7–8); real-data ETL (§6);
  `shared/python` extraction.
