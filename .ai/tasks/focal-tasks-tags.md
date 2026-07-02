# Goal

Port Focal's **tasks** domain — the user's to-dos with priority, due date/time, tags, completion, and the
**multi-factor priority model** — from the standalone Express/Drizzle app onto the Focal FastAPI backend,
faithful to the legacy contract, and **reconcile the already-shipped `/api/tags`** (the `task_tags`
per-user master list) to full parity. After this slice, tasks and tags are reachable as tenant-scoped,
typed FastAPI endpoints the existing client can call unchanged.

Second of the three slices the former `focal-mindmap-core` was split into for Phase 1 of
[superapp/apps/focal/docs/MIGRATION_PLAN.md](../../superapp/apps/focal/docs/MIGRATION_PLAN.md) §9
(after `focal-spheres-projects`; `focal-mindmap-graph` follows). Builds on the approved
`focal-foundation` (the `tasks` + `task_tags` models already landed there) and `focal-spheres-projects`
(the `projects` rows the links + enrichment + priority hierarchy resolve against).

> **Binding contract = the legacy source** (`focal/server/routes.ts` + `focal/server/storage.ts` +
> `focal/shared/schema.ts`); cited line numbers are the authority.
> `superapp/apps/focal/docs/contract-freeze/routes.json` is the path inventory,
> `superapp/apps/focal/docs/contract-freeze/tables.json` the column mapping. Behavior is
> reverse-engineered and **rebuilt idiomatically (router → service → async SQLAlchemy repo), not
> transliterated** — but must match observably (contract tests).

> **Backend-only slice.** No React `features/` UI (deferred to a frontend tasks slice). Responses
> **preserve the legacy camelCase field names** (`dueDate`, `dueTime`, `priorityLevel`, `completedAt`,
> `projectId`, `productId`, …) via Pydantic `by_alias`; request bodies **accept** those same camelCase
> aliases (`populate_by_name`) and **ignore unknown fields** (`extra="ignore"`; the legacy client sends
> e.g. `userId`). Paths are relative to the pipeline root; service at `superapp/apps/focal/server`,
> legacy read-only at `focal/`.

> **Tenant model — a deliberate, documented tightening of the legacy.** Two legacy gaps are closed:
> (a) the **task-by-id** endpoints fetch/mutate **by `id` alone with no ownership check** —
> `getTaskEnriched` (`storage.ts:4691`), `updateTask`→`getTask` (`storage.ts:4774`), `deleteTask`
> (`storage.ts:4801`); (b) **create/update do not scope the `projectId`/`productId`/`activityId` links to
> the user** (`routes.ts:3019`-`3032`) — only a DB-FK existence check — yet the enriched GET joins the
> project and returns its `projectName`/`sphere`/`projectType` (`storage.ts:4620`,`4670`-`4672`), so a
> task pointing at another user's project would **leak** that project's data. The new contract **scopes
> every task read/update/delete AND every link to the JWT `sub`**: a task or a referenced
> project/product/activity that is missing **or** owned by another user is treated identically (no
> existence leak), and the enrichment join only ever resolves the user's **own** projects. Any
> client-supplied `userId` is **ignored** (tenant is always `sub`). This is the intended behavior change
> vs. the source.

> **Error envelope (this slice's contract):** every business error is a typed `AppError` subclass mapped
> to `{error:{code,message}}` (no raw `HTTPException`). The typed errors (contract-tested):
> `not_found` (404) for a task/tag missing **or** owned by another user (identical response — no
> existence leak); `validation_error` (422) for a missing `title`, an invalid `dueDate` (not
> `YYYY-MM-DD`) / `dueTime` (not `HH:MM`, 00:00–23:59), or a `tags` value that is not an array;
> `related_record_not_found` (400) when a create/update **`projectId`/`productId`/`activityId`** does not
> resolve to one of the user's **own** rows (no existence leak). `contactId`/`goalId` are **stored without
> DB/ownership validation** (their tables aren't ported / never FK'd) — but are typed as optional strings
> (`str | None`; a non-string → `validation_error`, never a raw DB error); `eventId` is **not a client input** in this
> slice (set only by calendar linking, Phase 2). Tag-validation failures also use `validation_error` (422).

# Scope

**Domain models — reconcile, don't rebuild**

- `tasks` and `task_tags` **already landed** in `focal-foundation` (`app/models/tasks.py`,
  `app/models/tags.py`). Reconcile against `superapp/apps/focal/docs/contract-freeze/tables.json`
  (`tasks` = `focal/shared/schema.ts:462`-`506`; `task_tags` = `:1089`-`1097`); expect **no schema
  change** — columns, defaults (`priority="medium"`, `priority_level="medium"`, `priority_score=0.5`,
  `status="pending"`, `completed=false`, `tags=[]`), the `project_id`/`product_id`/`activity_id`
  `ON DELETE SET NULL` FKs, and the plain `contact_id`/`event_id`/`goal_id` columns are present.
- **Tenant isolation is enforced at the application layer** (every query filtered by `sub`) and tested.
  **RLS is out of scope here** — no `focal.*` table carries a policy yet (the baseline migration and the
  approved `focal-spheres-projects` add none); RLS lands later in a dedicated enablement step (when the
  local test image switches `postgres:16` → `supabase/postgres`, per the plan's Phase-0 caveat). Do
  **not** add a one-off policy.
- **`tasks.tags` is a JSONB array of tag *names* (strings)** (`schema.ts:478`), **not** a join table; the
  `task_tags` table is the per-user **master list** (`id, name, color`) — the existing `/api/tags`. There
  is **no task↔tag assignment endpoint**; a task's tags are just its `tags` array on create/update.

**Tasks — `/api/tasks`, `/api/tasks/:id`**

- **List — `GET /api/tasks`** (`routes.ts:2976`-`2987`, `getAllTasksEnriched`, `storage.ts:4606`-`4679`):
  the user's tasks **within a date window**, ordered **`created_at` DESC** (`storage.ts:4628`). Query
  params are **`startDate`/`endDate`** (`YYYY-MM-DD`). The window is `getDateRange(startDate, endDate)`
  (`focal/server/utils/functions.ts`; port it faithfully): **when both are present and parseable as
  `YYYY-MM-DD`, use them; when either is missing/empty OR malformed, default *both* to the current
  calendar month** (`YYYY-MM-01` … month's last day). The legacy only falls back on *missing* and passes
  a malformed value to Postgres (which errors); **treating malformed as missing is a documented,
  intentional hardening** so the endpoint never 500s on a bad query date.
  The row filter is **`(due_date BETWEEN window-start AND window-end) OR due_date IS NULL`**
  (`storage.ts:4621`-`4627`) —
  **undated tasks are always included**; a `startDate > endDate` simply yields no *dated* rows (undated
  still returned). Compute the month boundary via an **injected clock in UTC** (the legacy used
  server-local time) so it is deterministically testable.
  - Returns the **`EnrichedTask`** shape — each task plus, from a left join to the user's **own**
    projects (`storage.ts:4649`-`4677`): `projectType` (`mission|provision|null`), `sphere`,
    `projectName`, `isWorkTime` (`project.is_work_time ?? true`), `projectHasProducts`, and orphan flags
    — `isOrphan=true, orphanReason="noProject"` when no `project_id`; `isOrphan=true,
    orphanReason="noProduct"` when the project has products but the task has no `product_id`. No display
    sort here (see Out of scope: `taskSort`).
- **Get — `GET /api/tasks/:id`** (`routes.ts:2989`-`3003`): single `EnrichedTask`, scoped to `sub`
  (`not_found` if missing/non-owned; a malformed `:id` likewise yields `not_found`).
- **Create — `POST /api/tasks`** (`routes.ts:3005`-`3049`): the body fields are exactly
  `title, description, dueDate, dueTime, priority, tags, contactId, goalId, projectId, productId,
  activityId` (`routes.ts:3007`) — any other field (incl. `status`, `completed`, `eventId`) is **ignored**
  (not read): `status`/`completed` take the defaults `"pending"`/`false`; `eventId` is set only by
  calendar linking (Phase 2). Require a **non-blank** `title` (empty or whitespace-only → `validation_error`);
  validate `dueDate`/`dueTime` when present (an explicit `null` is accepted as absent — stored null);
  defaults `priority="medium"`, `tags=[]`. The owner is `sub`.
  **Links:** `projectId`/`productId`/`activityId`, when provided, must each resolve to one of the user's
  **own** rows → else `related_record_not_found` (400, no existence leak). (`activityId` ownership is
  checked against the `activities` table, which exists from foundation though its CRUD vertical lands
  Phase 4 — **no activities exist yet, so a non-null `activityId` resolves to not-found in practice**.) A
  user-owned `productId` need **not** be a child of the supplied `projectId` — the legacy validates the
  links **independently** (cross combinations allowed, faithful). `contactId`/`goalId` stored as-is.
  Compute `priority_score`/`priority_level` (Priority model below).
  - **`priority` (a create + update field) and `status` (PATCH-only — create ignores it) are stored as
    free-form strings** — the legacy applies **no enum check**; the canonical values (`priority` ∈
    {`high`,`medium`,`low`}, `status` ∈ {`pending`,`in_progress`,`completed`,`cancelled`}) are documented
    but **not enforced** (faithful). **`tags` must be an array of strings** (non-array → `validation_error`;
    non-string elements → `validation_error`).
- **Update — `PATCH /api/tasks/:id`** (`routes.ts:3051`-`3092`, `updateTask`, `storage.ts:4772`-`4796`):
  **true partial update**, scoped to `sub`. The legacy applies `.set({ ...updates })` over only the keys
  the client sent (`storage.ts:4792`):
  - **A key omitted** → column unchanged. **A nullable *scalar* key sent as `null`** (`dueDate`, `dueTime`,
    `description`, `projectId`, `productId`, `activityId`, `contactId`, `goalId`) → column **cleared to
    null**. Distinguish *omitted* from *explicit-null* via Pydantic `model_fields_set` (do not collapse
    null into "unchanged").
  - **`tags`** is an array: a provided array (incl. `[]`) replaces it; `tags: null` is **rejected**
    (`validation_error`) — use `[]` to empty; omitted preserves.
  - **`completed: null/omitted`** → no completion change (transition below). **`completedAt` is always
    stripped** (`routes.ts:3068`) — never client-settable. `priority_score`/`priority_level` are **always
    recomputed**.
  - **`title`** is `NOT NULL`: omitting it preserves the existing value; sending `null` or a
    blank/whitespace-only string → `validation_error` (a required column cannot be cleared).
  - **Editable whitelist:** `title, description, dueDate, dueTime, priority, tags, status, completed,
    contactId, goalId, projectId, productId, activityId`. **Never settable:** `id`, `userId`, `eventId`
    (Phase 2), `completedAt`, `priorityScore`, `priorityLevel`, `createdAt`, `updatedAt`. Link-ownership +
    date validation as on create.
- **Delete — `DELETE /api/tasks/:id`** (`routes.ts:3094`-`3116`): legacy `{"success": true}`; scoped to
  `sub` (`not_found` if missing/non-owned).

**Priority model — port now (project/product/sphere); `activity` deferred to Phase 4**
(`calculatePriorityForItem` + helpers, `storage.ts:140`-`175`, `958`-`985`). Computed on every
create/update and stored in `priority_score`/`priority_level`:

- `getHierarchyContext` resolves the linked **project, product** (built) and the **sphere** — but the
  sphere is resolved **only when `project.isWorkTime === false` and `project.sphere` is set**
  (`storage.ts:940`-`943`); otherwise no sphere. **`activity` is treated as `null`** (the activities
  vertical lands Phase 4 — its priority contribution is `0` until then; documented deviation).
- `missionScore = 1.0 if (project.projectType ?? product.projectType) == "mission" else 0.0`.
- `hierarchyPriorityScore = max(priorityToScore(p) for p in [activity(=null), product.priority,
  project.priority, sphere.priority])` (port `priorityToScore` exactly).
- `urgencyScore = calculateUrgencyScore(dueDate)`: no/invalid date → `0.1`; by calendar-day delta (UTC,
  injected clock) → `≤0: 1.0`, `==1: 0.9`, `≤3: 0.7`, `≤7: 0.5`, `≤14: 0.3`, else `0.1`.
- `energyScore = 1.0 if (project.givesEnergy ?? sphere.givesEnergy ?? false) else 0.0`.
- `priorityScore = clamp(0.4·mission + 0.3·hierarchy + 0.2·urgency + 0.1·energy, 0, 1)`;
  `priorityLevel = "high" if ≥0.6 else "medium" if ≥0.3 else "low"`.

**Completion transition (`completed_at`)** (`transitionCompletedAt`, `storage.ts:763`-`772`; pinned by
`storage.updateTaskCompletedAt.test.ts`):

```
nextCompleted undefined/null → no change   |   false→true → completed_at = now()
true→false → completed_at = null           |   no state change → no change
```

Editing other fields of a completed task leaves `completed_at` untouched. Port exactly; reuse the legacy
test as the oracle.

**Tags — `/api/tags`, `/api/tags/:id` (reconcile to parity)** (`routes.ts:3119`-`3173`,
`storage.ts:4530`-`4602`)

- `GET /api/tags` lists the user's tags (legacy applies no order; this slice orders by `created_at` ASC
  for deterministic tests — a documented determinism improvement). `POST` requires **both `name` (≤ 50,
  non-blank) and `color` (non-blank, ≤ 20 — the `task_tags.color` schema cap)** — a missing or over-long
  `name`/`color` → typed `validation_error` (422) (the legacy used a bare 400, `routes.ts:3132`; rebuilt
  to this slice's envelope); `userId` comes from `sub` (not a required body field, unlike the legacy which
  also demanded a body `userId`). `PATCH /api/tags/:id` is a partial merge of `name`/`color` — each
  **optional**, but when provided the same rules apply (`name` ≤ 50 + non-blank, `color` non-blank + ≤ 20
  → else `validation_error`; a provided `name`/`color` of `null` or blank → `validation_error`); an empty
  body is a no-op that returns the unchanged tag; no duplicate-name check (the legacy `task_tags` has none).
  `DELETE` → `{"success": true}`. All scoped to `sub` (client `userId` ignored); `not_found` for
  missing/non-owned. **Responses are the legacy `{id, name, color}` shape** (camelCase; list = array,
  item = object; HTTP 200). **Verify-and-close** — add contract tests where missing; do not rebuild
  passing behavior.

**Cross-cutting**

- Every endpoint tenant-scoped to `sub` (`get_current_user_id`), including the by-id and link paths the
  legacy left unscoped. **Every `:id` path param is an opaque string (not typed/coerced), so an unknown or
  malformed id flows through the scoped lookup to the typed `not_found` (404) — never FastAPI's default
  path-validation `422`** — on every task and tag `GET`/`PATCH`/`DELETE`. Async; SQLAlchemy 2.0 +
  Pydantic v2. Ordering: the **tasks** list/detail returns the legacy `created_at`-**DESC** order; the
  **tags** list returns `created_at`-**ASC** (above). All responses keep the legacy array/object camelCase
  shapes — pinned by contract tests.

**Tests** (vs local Docker Postgres)

- CRUD; `dueDate`/`dueTime` validation; **date-window** (no params → current month + all undated; valid
  `startDate/endDate` honored; either missing or malformed → current-month fallback; `startDate>endDate`
  → undated only); **tenant
  isolation** (second user cannot get/update/delete the first user's task, nor reference its
  project/product as a link — all `not_found`/`related_record_not_found`); **completion transition** (port
  `storage.updateTaskCompletedAt.test.ts`); **PATCH null-vs-omitted** (explicit null clears a scalar,
  omission preserves, `tags:null` rejected, `tags:[]` empties); **enrichment** (`isOrphan`/`orphanReason`,
  `isWorkTime`, `projectType`, `projectHasProducts`); **priority-model oracle** — a table covering
  urgency thresholds (no-date, 0/1/3/7/14/>14 days), `mission` vs `provision`, `givesEnergy` on/off, the
  hierarchy-max, and the `0.6`/`0.3` level cutoffs; **link existence+ownership** (`related_record_not_found`
  for non-existent or non-owned `projectId`/`productId`/`activityId`; `contactId`/`goalId` stored
  unvalidated); contract tests pinning camelCase shapes + the error envelope. Reconcile/extend the
  existing `/api/tags` tests.

# Out of scope

- **`taskSort` + the tasks React UI — deferred to the frontend tasks slice.** `focal/shared/taskSort.ts`
  is a client-side display comparator (the backend returns `created_at` DESC; the client sorts). Recorded
  here, built in the frontend slice with its 21-case test as the parity oracle. This backend slice does
  **not** apply display sort and **does** contract-test the `created_at`-DESC order.
- **The `activity` branch of the priority model** — its contribution is `0` until the activities vertical
  (Phase 4) completes the hierarchy; recompute-on-parent-change cascades are also Phase 4 / events.
- **RLS policies** — the dedicated enablement step; tenant isolation is app-layer here.
- **`mindmap` nodes/edges/init** — the next slice. **Goals** — the legacy exposes no `/api/goals` CRUD
  (read-only via AI/agent, Phases 7–8); the model exists, no routes here. **`eventId` linking** — Phase 2
  calendar. **React frontend**; Google/habits/dashboard/push (Phases 3–5); `foc_`/AI (Phases 7–8); ETL
  (§6); shared-package extraction.

# Acceptance criteria

- [ ] `cd superapp/apps/focal/server && make verify` is green (ruff + mypy + pytest); any `uv.lock` change
      committed; `uv run alembic check` shows no model/migration drift.
- [ ] CRUD over `tasks` works at the `routes.json` paths; responses camelCase matching the legacy shape
      (contract test).
- [ ] **Tenant scoping (tightened):** `GET/PATCH/DELETE /api/tasks/:id` scoped to `sub` (second user →
      `not_found`, no leak); a body/query `userId` ≠ `sub` is ignored; a create/update referencing another
      user's `projectId`/`productId`/`activityId` returns `related_record_not_found` (no leak); the
      enrichment join never returns another user's project data (tested).
- [ ] **Date window:** no params → tasks with `due_date` in the current calendar month **plus all** undated
      tasks, `created_at` DESC; explicit valid `startDate`+`endDate` honored; either missing or malformed
      → current-month fallback; `startDate>endDate` → only undated (tested with an injected clock).
- [ ] **`EnrichedTask`** shape returned (`projectType`, `sphere`, `projectName`, `isWorkTime`,
      `projectHasProducts`, `isOrphan`/`orphanReason`) per `storage.ts:4649`-`4677` (tested).
- [ ] **Priority model** matches the oracle table: urgency by day-delta (no-date→0.1, ≤0→1.0, 1→0.9, ≤3→0.7,
      ≤7→0.5, ≤14→0.3, else 0.1), `0.4·mission+0.3·hierarchy+0.2·urgency+0.1·energy` clamped, level cutoffs
      0.6/0.3; the `activity` term is 0 (Phase-4 deferral) (tested).
- [ ] **Completion transition:** `false→true` sets `completed_at`, `true→false` clears, other edits leave it,
      a client `completedAt`/`completed:null` does not move it (tested, porting the legacy test).
- [ ] **PATCH null-vs-omitted:** explicit `null` clears a nullable scalar; omission preserves; `tags:null`
      rejected, `tags:[]` empties; `title` sent `null`/blank → `validation_error` (NOT NULL), omitted
      preserves; `priorityScore`/`priorityLevel`/`completedAt`/`id`/`userId`/`eventId` never
      client-settable (tested).
- [ ] **Create** requires a non-blank `title` (empty/whitespace → `validation_error`), defaults
      `priority="medium"`+`tags=[]`, **ignores** `status`/`completed`/`eventId` inputs (not read),
      validates `dueDate`/`dueTime`, derives priority;
      non-existent/non-owned link → `related_record_not_found`; `contactId`/`goalId` stored unvalidated
      (tested).
- [ ] `priority`/`status` are stored as free-form strings (no enum check — faithful), and `tags` must be
      an **array of strings** (a non-array or a non-string element → `validation_error`) (tested).
- [ ] `DELETE /api/tasks/:id` → `{"success": true}`; `not_found` for missing/non-owned (tested).
- [ ] An unknown/malformed `:id` on any task or tag `GET`/`PATCH`/`DELETE` yields the typed `not_found`
      (404) envelope, never FastAPI's default path-validation `422` (tested).
- [ ] `/api/tags` at legacy parity — list (ordered `created_at` ASC)/create/update/delete returning the
      `{id, name, color}` shape (camelCase), `name` ≤ 50 non-blank, `color` non-blank ≤ 20, **create
      requires both `name` and `color`** (missing/over-long → `validation_error` 422), no dup-name check,
      tenant-scoped, `{"success": true}` on delete — with contract tests (added where missing).
- [ ] Unknown request fields are ignored (`extra="ignore"`); every error path raises a typed `AppError`
      (`{error:{code,message}}`), never raw `HTTPException`; no PII logged on error paths (review + grep).
- [ ] No out-of-scope route/service (mindmap, goals CRUD, server-side `taskSort`, RLS, `eventId` linking,
      activities) is added.

# Verification commands

```sh
# focal's documented local-first exception (apps/focal/CLAUDE.md): Postgres + Redis via compose
docker compose -f superapp/apps/focal/docker-compose.yml up -d

cd superapp/apps/focal/server
uv sync --frozen
uv run alembic upgrade head
make verify
uv run alembic check           # no drift between models and committed migrations
```
