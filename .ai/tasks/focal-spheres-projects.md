# Goal

Port Focal's **life spheres + projects** — the user's life spheres and the project/product tree, with
its Mission/Provision + work-time rules — from the standalone Express/Drizzle app onto the Focal FastAPI
backend, faithful to the legacy contract. After this slice spheres and projects are reachable as
tenant-scoped, typed FastAPI endpoints the existing client can call unchanged.

First of the three slices the former `focal-mindmap-core` was split into for Phase 1 of
[superapp/apps/focal/docs/MIGRATION_PLAN.md](../../superapp/apps/focal/docs/MIGRATION_PLAN.md) §9
(`focal-tasks-tags`, `focal-mindmap-graph` follow). Builds on the approved `focal-foundation` and
`focal-data-mapping`.

> **Binding contract = the legacy source** (`focal/server/routes.ts` + `focal/server/storage.ts`); cited
> line numbers are the authority. `superapp/apps/focal/docs/contract-freeze/routes.json` is the path
> inventory, `superapp/apps/focal/docs/contract-freeze/tables.json` the column mapping. Behavior is
> reverse-engineered and **rebuilt idiomatically (router → service → async SQLAlchemy repo), not
> transliterated** — but must match observably (contract tests).

> **Backend-only slice.** No React `features/` UI (deferred to a frontend slice). Responses **preserve
> the legacy camelCase field names** (`projectType`, `isWorkTime`, `parentProjectId`, `allocatedHours`,
> …) via Pydantic `by_alias`, and request bodies **accept** those same camelCase aliases
> (`populate_by_name`) since the legacy client sends them. Paths are relative to the pipeline root;
> service at `superapp/apps/focal/server`, legacy read-only at `focal/`.

> **Error envelope (this slice's contract):** every business error is a typed `AppError` subclass mapped
> to `{error:{code,message}}` (no raw `HTTPException`). The legacy sphere dup/fuzzy responses become
> `AppError(code="duplicate_sphere_name" | "similar_sphere_name")` at HTTP 400, with the offending names
> in **`error.details.similar_names`**; a contract test pins the exact shape. The other typed errors this
> slice raises (all sharing `{error:{code,message}}`, contract-tested): `not_found` (404) for a sphere/project that is missing **or** owned by another
> user (identical response — no existence leak); **`parent_project_not_found` (400) when create's `parentProjectId`
> is missing OR owned by another user — the identical response either way (no existence leak)**;
> `invalid_project_type` (422) for an out-of-enum `project_type`; `validation_error` (422) otherwise.

# Scope

**Domain models + the work-time constraint decision**

- `life_spheres` and `projects` already landed in `focal-foundation`. Reconcile against
  `superapp/apps/focal/docs/contract-freeze/tables.json`; add only the project self-reference
  `parent_project_id → projects.id` (`ON DELETE CASCADE`, `focal/shared/schema.ts:556`).
- **Decision (resolved): relax the work-time CHECK constraint to match legacy.** Remove
  `CheckConstraint("NOT is_work_time OR sphere IS NULL", name="work_time_sphere")` from
  `app/models/projects.py:13` so a work-time project may retain a `sphere` (legacy update preserves it).
  Because Alembic autogenerate does **not** reliably detect a named CHECK-constraint **drop**, the
  migration is hand-written, and **for this slice the agent writes and commits it** — a documented
  exception to root CLAUDE.md's "agents don't author migration files" (that rule assumes autogenerate
  produces the file; it can't here). The agent edits the model **and** commits
  `op.drop_constraint("ck_projects_work_time_sphere", "projects", schema="focal", type_="check")` as a
  reviewed migration (scrutinized at gate-code/gate-final like any change); `alembic upgrade head` applies
  it so `make verify` runs against the dropped schema — the slice stays self-contained and reproducible.

**Spheres — `/api/spheres`, `/api/spheres/:id`** (legacy `routes.ts:4750`-`4877`)

- **Create:** require `name`; reject (a) an **exact case-sensitive duplicate** for the user
  (`getSphereByName`, `storage.ts:5837` — `name = name`, case-sensitive), and (b) a **fuzzy-similar** name
  (`findSimilar`, `focal/server/utils/fuzzy.ts`: case-insensitive Levenshtein similarity ≥ 0.75, which
  **excludes any same-lowercase value**). Net legacy behavior: a pure case-variant ("Health" vs existing
  "health") is **allowed** — match that, do not reject case-only variants. → the typed error above. No
  auto-project creation (`routes.ts:4790`).
- **Update:** same dup + fuzzy checks **excluding the current sphere** (`routes.ts:4812`, `4819`) — saving
  its own name / editing other fields succeeds; colliding with another sphere's name/similar is rejected.
  Renaming a sphere does **not** rewrite the `sphere` name stored on existing projects (legacy has no
  rename-cascade — only delete cascades); projects keep their stored value.
- **Delete (destructive cascade, `routes.ts:4847`-`4868`):** in one transaction, first delete every
  project of that sphere's owner where `project.sphere == sphere.name`, then delete the sphere. Deleting
  each matching project **also deletes its child products** via the `parent_project_id` cascade — **even
  if a child product's own `sphere` differs** (legacy behavior: `deleteProject` relies on the FK cascade);
  cover this edge explicitly in a test.

**Projects — `/api/projects`, `/api/projects/:id`, `/api/projects/root`, `/api/projects/:id/products`**

- **Create** (`routes.ts:3621`-`3712`): if `parentProjectId` is supplied it's a **product** — the parent
  is fetched **scoped to the user** (`getProject(parentProjectId, sub)`); missing/non-owned → typed
  `AppError`, no existence leak. Each of `projectType`/`sphere`/`isWorkTime`/`color` is **the request-body
  value if provided, else inherited from the parent, else the default** (`routes.ts:3656`-`3659`) —
  defaults: `project_type`→`"provision"`, `is_work_time`→`true`, `color`→`"#3b82f6"` (`sphere` has none).
  **Sphere is coerced on create:** stored null when `is_work_time` is true, else the resolved sphere
  (`routes.ts:3688`). For a non-work-time create with `parent_type == "budget"` and no supplied position,
  legacy auto-computes `position_x`/`position_y` (`routes.ts:3666`-`3679`) — match it.
- **Update** (`routes.ts:3715`-`3768`): updates the editable project columns (`name`, `description`,
  `full_description`, `color`, `priority`, `project_type`, `sphere`, `is_work_time`, `position_x`/`_y`,
  `parent_type`, `status`, `sort_order`, `allocated_work_hours`, `allocated_hours`, `gives_energy` —
  everything except `id`/`user_id`/`parent_project_id`/timestamps); **does not modify `parent_project_id`**
  (reparenting only via the deferred `/move`); and **preserves `sphere`** — setting `is_work_time=true`
  does **not** clear it (`routes.ts:3731`); omitted fields keep their existing values
  (`new = submitted ?? existing`).
- `/root` = root projects (`parent_project_id is null`); `/:id/products` = a project's child projects
  (for a missing/non-owned parent, return `not_found` — no existence leak; confirm vs the legacy
  `/products` handler and pin in a contract test).
- **Delete:** returns the legacy success body `{"success": true}` (`routes.ts:3789`); `not_found` if missing/non-owned. Deleting a parent
  project **cascades to its child products** (`parent_project_id ON DELETE CASCADE`). The on-delete
  behavior of out-of-slice tables that reference a project (`tasks`, `activities`, `calendar_events`,
  `bookings`) is defined by **their own models** (it varies — e.g. `activities` is `CASCADE`) and is **not
  asserted or tested here**.
- **Invariant:** `project_type` ∈ `{"mission", "provision"}`, NOT NULL, default `"provision"`.

**Cross-cutting**

- Every endpoint tenant-scoped to the authenticated `sub` (`get_current_user_id`); no cross-tenant read
  or write. Any client-supplied `userId` (body/query — the legacy client still sends it) is **ignored**:
  the tenant is always the JWT `sub`, never trusted from the request, so the existing client works
  unchanged. Async; SQLAlchemy 2.0 + Pydantic v2. GET list/detail endpoints return the legacy
  array/object shapes and preserve legacy ordering (per the `storage` queries) — pinned by contract tests.

**Tests**

- Per-route integration tests vs local Docker Postgres (CRUD, validation, not-found, tenant isolation),
  the project_type + work-time tests (**create-coerces** vs **update-preserves**), the sphere dup/fuzzy +
  self-exclusion tests, the destructive **delete-cascade** test (incl. cross-tenant isolation), and
  contract tests pinning the camelCase shapes + the error envelope.

# Out of scope

- **`/api/projects/:id/move` + `/api/projects/:id/move-preview` — deferred.** Legacy `moveProject`
  (`storage.ts:5279`-`5393`) moves a root project to one of four fixed budget nodes and **cascades to
  child products, tasks, calendar_events, and bookings**; tasks land in `focal-tasks-tags` and
  calendar_events/bookings in Phase 2, so it can't be built faithfully here. (Recorded, not dropped.)
- **Other Phase-1 slices:** tasks/tags/`task_tags`/`taskSort`; mindmap nodes/edges/init/batch.
- **React frontend**; calendar/CRM/Google/habits/dashboard/push (Phases 2–5); `timezone`/`datePresetRange`
  + shared-calendar RBAC (Phase 2); `foc_`/AI (Phase 7); ETL (§6); shared-package extraction.

# Acceptance criteria

- [ ] `cd superapp/apps/focal/server && make verify` is green (ruff + mypy + pytest); any `uv.lock`
      change is committed.
- [ ] The `work_time_sphere` CHECK constraint is removed from `app/models/projects.py` **and** a matching
      agent-authored `drop_constraint` migration is committed (documented exception — see scope) and applied
      via `alembic upgrade head`, so DB-backed tests run against the dropped schema and `alembic check`
      shows no model/migration drift.
- [ ] Create with a **missing** `parentProjectId` and create with **another user's** `parentProjectId`
      return the identical typed error (`parent_project_not_found`, 400) — nothing distinguishes the two
      (no existence leak) (tested).
- [ ] CRUD over `spheres` and `projects` (incl. `/root`, `/:id/products`) works end-to-end at the
      `routes.json` paths, tenant-scoped to `sub`; a second user cannot read or mutate the first user's
      rows; responses are camelCase matching the legacy shape (contract test).
- [ ] Sphere **create** rejects an exact-duplicate and a fuzzy-similar (≥0.75) name with the typed error
      (code + `error.details.similar_names`); sphere **update** applies the same checks **excluding the
      current sphere** (re-saving its own name succeeds; colliding with another's is rejected) — tested.
- [ ] Deleting a sphere deletes, in one transaction, all of that owner's projects whose `sphere ==
      sphere.name`, then the sphere; child products of those projects are also removed via the parent
      cascade even when their own `sphere` differs; another tenant's same-named sphere and projects are
      untouched (tested).
- [ ] Renaming a sphere does not change the `sphere` value stored on existing projects (no rename-cascade,
      matching legacy) (tested).
- [ ] Deleting a project returns the legacy success shape and `not_found` for missing/non-owned; deleting
      a parent project cascades to its child products (`ON DELETE CASCADE`) (tested).
- [ ] A request carrying a body/query `userId` different from the JWT `sub` is served against `sub`'s data
      only (client-supplied `userId` ignored, never trusted) (tested).
- [ ] A non-work-time project created with `parent_type="budget"` and no supplied position receives the
      legacy-computed `position_x`/`position_y` (`routes.ts:3666`-`3679`) (tested).
- [ ] `project_type` is constrained to `{"mission", "provision"}`, default `"provision"`; an out-of-enum
      value is rejected with a typed `AppError`; the value persists + round-trips (tested).
- [ ] Work-time **create-coercion**: creating with `is_work_time=true` + a non-null `sphere` stores
      `sphere` null; `is_work_time=false` keeps the submitted sphere (tested).
- [ ] Work-time **update-preservation**: updating an existing project to `is_work_time=true` does **not**
      clear its `sphere` (now allowed since the constraint is relaxed); omitted fields keep existing values
      (tested).
- [ ] Project **create** with `parentProjectId` validates parent ownership by `sub` (missing/non-owned →
      typed `AppError`, no existence leak) and fills `projectType`/`sphere`/`isWorkTime`/`color` as
      body-value-else-parent-else-default; project **update** does not change `parent_project_id` (tested).
- [ ] Every business-logic error path raises a typed `AppError` (`{error:{code,message}}`), never a raw
      `HTTPException`; no PII in logs (verified by code review + a grep that no token/email/name is logged
      on error paths; the slice adds no new logging of request/user data).
- [ ] No route/service for any out-of-scope domain (incl. `move`/`move-preview`) is added.

# Verification commands

```sh
# local-first backing services (Postgres + Redis)
docker compose -f superapp/apps/focal/docker-compose.yml up -d

cd superapp/apps/focal/server
uv sync --frozen
uv run alembic upgrade head    # applies the committed work_time_sphere DROP migration
make verify
uv run alembic check           # no drift between models and committed migrations
```
