# Summary

Implement the `focal-spheres-projects` backend slice on the existing scaffold (the `life_spheres` and
`projects` models already landed in `focal-foundation`; `app/api/tags.py` + `app/services/tags.py` are the
router→service→async-repo pattern to mirror). Four independently-green slices: **(1) shared primitives** —
Pydantic v2 schemas (legacy camelCase aliases, both directions), this slice's typed `AppError` subclasses,
and a ported `findSimilar` fuzzy helper with unit tests; **(2) spheres vertical** — `life_spheres` CRUD with
case-sensitive duplicate + fuzzy-similar rejection and the destructive owner-scoped delete-cascade; **(3)
projects core** — drop the `work_time_sphere` CHECK constraint (model edit + agent-authored migration, per
the Gate-1 decision) then project create/update/delete/get with inherit/coerce/preserve + the `project_type`
invariant; **(4) project reads** — `/`, `/root`, `/:id/products` with legacy ordering + the camelCase
contract tests. Every endpoint is tenant-scoped to the JWT `sub`, ignores any client-supplied `userId`, and
raises only typed `AppError`. `move`/`move-preview` stays deferred (its cascade reaches tasks/events/bookings).
Task: [focal-spheres-projects.md](../tasks/focal-spheres-projects.md). Binding contract: legacy
`focal/server/{routes,storage}.ts` + `contract-freeze/`.

## Decisions (design + resolving Gate-1 carryovers)

- **Typed error envelope (one `AppError` subclass per code), mapped by the existing single handler:**
  `not_found`→404; `duplicate_sphere_name`→400; `similar_sphere_name`→400 with `error.details.similar_names`;
  `parent_project_not_found`→400 (**identical for missing vs non-owned** — no existence leak);
  `invalid_project_type`→422; `validation_error`→422. **Two app changes are required** (today the handler
  returns only `{code,message}` — `errors.py:49` — and only `AppError` is registered — `main.py:25`): (a)
  add an optional `details: dict` to the `AppError` base and include it in the handler response when present
  (carries `similar_names`); (b) register a `RequestValidationError` handler returning
  `{error:{code:"validation_error",message,details}}` (422) so malformed input still uses the envelope
  (this also standardizes 422 bodies for existing routes like `tags` — intentional shared envelope; current
  tags tests assert status, not body).
  **`invalid_project_type` is raised in the service** (validate `project_type ∈ {mission,provision}` →
  `InvalidProjectTypeError`), **not** via a bare Pydantic `Literal` (which would 422 as generic
  `validation_error` before the service runs); the schema accepts `project_type: str`.
- **`findSimilar` is ported to `app/domain/similar.py`** (pure, unit-tested): case-insensitive Levenshtein
  similarity ≥ 0.75, **excluding any same-lowercase candidate** (that's the duplicate path) — faithful to
  `focal/server/utils/fuzzy.ts`, no whitespace normalization. The case-sensitive duplicate check is a plain
  `name == name` query (`getSphereByName`, `storage.ts:5837`), so a pure case-variant is allowed.
- **Tenancy:** the shared `get_current_user_id` dependency (`app/deps.py:6`, from `focal-foundation`) supplies `sub`; any
  body/query `userId` is dropped at the schema boundary (not a model field). Cross-row reads/writes are
  filtered by `user_id == sub`; a non-owned row reads as `not_found` (same as missing).
- **camelCase:** schemas use `ConfigDict(alias_generator=to_camel, populate_by_name=True)` so responses
  serialize camelCase (`by_alias`) and requests accept camelCase **and** snake_case.
- **Migration ownership (Gate-1 ruling):** the CHECK-drop is agent-authored + committed (documented
  exception, since autogenerate can't emit a named CHECK drop), reviewed at gate-code/gate-final.
- **DB-backed services (no in-memory fallback).** Unlike the tags demo scaffold (`app/api/tags.py:15`), the
  spheres/projects services require `DATABASE_URL` and add no in-memory repository — the behavior here
  (transactions, FK cascade, the dropped constraint) is DB-semantic and its tests run against local Docker PG.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/server/app/models/projects.py` | modify | remove `CheckConstraint("NOT is_work_time OR sphere IS NULL", name="work_time_sphere")` (decision: relax to match legacy); confirm `parent_project_id` self-FK (`ON DELETE CASCADE`) present |
| `superapp/apps/focal/server/app/models/life_spheres.py` | (verify) | reconcile columns vs `contract-freeze/tables.json`; no functional change expected |
| `superapp/apps/focal/server/alembic/versions/<rev>_drop_work_time_sphere_check.py` | add | **agent-authored** `op.drop_constraint("ck_projects_work_time_sphere","projects",schema="focal",type_="check")` (+ `upgrade`/`downgrade`) |
| `superapp/apps/focal/server/app/schemas/spheres.py` | add | sphere request/response models (camelCase aliases, `populate_by_name`) |
| `superapp/apps/focal/server/app/schemas/projects.py` | add | project request/response models (camelCase); `project_type` accepted as `str` (validated in the service → `invalid_project_type`, not a schema `Literal`) |
| `superapp/apps/focal/server/app/domain/similar.py` | add | ported `levenshtein`/`similarity`/`find_similar` (pure) |
| `superapp/apps/focal/server/app/services/spheres.py` | add | sphere CRUD + dup/fuzzy + owner-scoped delete-cascade (one transaction) |
| `superapp/apps/focal/server/app/services/projects.py` | add | project CRUD + create inherit/coerce/position + update preserve + `/root` + `/products` |
| `superapp/apps/focal/server/app/errors.py` | modify | add optional `details: dict` to the `AppError` base + the typed subclasses; the handler serializes `details` when present |
| `superapp/apps/focal/server/app/api/spheres.py` | add | thin `spheres` router |
| `superapp/apps/focal/server/app/api/projects.py` | add | thin `projects` router |
| `superapp/apps/focal/server/app/main.py` | modify | include the `spheres` + `projects` routers; register a `RequestValidationError` handler → `{error:{code:"validation_error",…}}` (422) |
| `superapp/apps/focal/server/tests/test_spheres.py` | add | unit (fuzzy/dup/self-exclusion) |
| `superapp/apps/focal/server/tests/test_spheres_db.py` | add | DB-backed CRUD + cascade + tenant tests |
| `superapp/apps/focal/server/tests/test_projects_db.py` | add | DB-backed CRUD + inherit/coerce/preserve + parent-ownership + delete-cascade + tenant |
| `superapp/apps/focal/server/tests/test_contracts.py` | add | camelCase shapes + error envelope + list ordering |
| `superapp/apps/focal/server/tests/test_models_db.py` | modify | its `work_time_sphere` `IntegrityError` test (`:245`) asserts the constraint being dropped — update/remove it (+ stale docstring) so `make verify` stays green |

# Implementation slices

Each slice is independently reviewable (gate-code → fix loop) and leaves `make verify` green.

1. **Shared primitives (no endpoints yet).** Add `app/domain/similar.py` (port `levenshtein`/`similarity`/
   `find_similar`, threshold default 0.75, exclude same-lowercase) + unit tests proving parity with
   `fuzzy.ts` (case-insensitive, ≥0.75, same-lowercase excluded, ordering by descending similarity). Add the
   typed `AppError` subclasses **+ the optional `details` field in `app/errors.py` and the
   `RequestValidationError` handler in `app/main.py`** (so `similar_names` serializes and malformed input →
   `validation_error`). Add `app/schemas/{spheres,projects}.py` (camelCase aliases + `populate_by_name`;
   `project_type` as `str`, validated in the service — **not** a bare `Literal`). *Verify:* unit tests green;
   schema round-trips camelCase↔snake.
2. **Spheres vertical.** `app/services/spheres.py` + `app/api/spheres.py`: list/get/create/update/delete over
   `life_spheres`, tenant-scoped to `sub`. Create rejects case-sensitive duplicate + fuzzy-similar (via the
   helper). Update applies the same checks **excluding the current sphere**. Delete runs one transaction:
   delete the owner's projects where `sphere == sphere.name` (child products fall via the `parent_project_id`
   cascade, even if their own sphere differs), then the sphere. Register the router. *Verify:* `test_spheres*`
   green incl. dup/fuzzy/self-exclusion + the destructive cascade + cross-tenant isolation.
3. **Projects core (constraint drop + mutations).** Remove the CHECK constraint from `projects.py`; add the
   agent-authored `drop_constraint` migration; `alembic upgrade head`; **update the now-stale
   `tests/test_models_db.py` test that currently expects the dropped invariant to raise `IntegrityError`**.
   `app/services/projects.py` +
   `app/api/projects.py`: create (parent looked up scoped to `sub` → `parent_project_not_found` identical for
   missing/non-owned; inherit `projectType`/`sphere`/`isWorkTime`/`color` as body??parent??default with
   defaults `provision`/`true`/`#3b82f6`; **coerce `sphere`→null when `is_work_time`**; auto-compute
   `position_x/y` for non-work-time `parent_type=="budget"` with no supplied position), update (partial;
   **preserve `sphere`**; never change `parent_project_id`), get-by-id, delete (returns `{"success": true}`;
   cascades to child products). `project_type` validated **in the service** → `invalid_project_type` (not a
   bare `Literal`). *Verify:* `test_projects_db` green; updated `test_models_db` green; `alembic check` no drift.
4. **Project reads + contracts.** `GET /api/projects` (list), `/api/projects/root`, `/api/projects/:id/products`
   (missing/non-owned parent → `not_found`), preserving legacy ordering. **Declare the static `/root` route
   before the dynamic `/{id}` route** so it isn't shadowed. Add `test_contracts.py` pinning the
   camelCase response shapes, the error envelope (incl. `error.details.similar_names`), the ignored-client-
   `userId`, and list ordering. *Verify:* `make verify` green end-to-end (`alembic upgrade head` first).

# Tests

- **Fuzzy unit** (`test_spheres.py`): `find_similar` flags ≥0.75 matches, excludes same-lowercase, orders by
  similarity desc. *Proves parity with `fuzzy.ts`.*
- **Sphere create/update names** (DB): exact case-sensitive duplicate → `duplicate_sphere_name`; near name →
  `similar_sphere_name` with `error.details.similar_names`; **case-only variant allowed**; update excluding
  self (re-saving own name OK; colliding with another rejected). *Proves the legacy name contract.*
- **Sphere delete-cascade** (DB, destructive): deletes the owner's matching projects + their child products
  (even when a product's own sphere differs) + the sphere, in one transaction; another tenant's same-named
  sphere/projects untouched. *Proves the destructive edge + tenant isolation.*
- **Sphere rename no-cascade** (DB): renaming a sphere does **not** change the `sphere` value stored on
  existing projects (legacy has no rename-cascade). *Proves rename leaves project references intact.*
- **Project work-time** (DB): create with `is_work_time=true`+sphere → stored null; create
  `is_work_time=false` keeps sphere; **update to `is_work_time=true` does not clear** an existing sphere
  (requires the dropped constraint). *Proves create-coerce vs update-preserve.*
- **Project parent** (DB): create with another user's `parentProjectId` → `parent_project_not_found`,
  identical to a missing id (no leak); product inherits parent fields; update never changes
  `parent_project_id`. *Proves ownership + inheritance.*
- **Project invariant / delete / reads** (DB): out-of-enum `project_type` → `invalid_project_type`; delete →
  `{"success":true}` + child products cascade; `/root` + `/:id/products` return legacy shapes/ordering.
- **Project budget position** (DB): a non-work-time project created with `parent_type="budget"` and no
  supplied position receives the legacy-computed `position_x`/`position_y`. *Proves position auto-compute parity.*
- **Contracts** (`test_contracts.py`): responses camelCase; a body/query `userId ≠ sub` operates on `sub`'s
  data only. *Proves client-compat + the never-trust-client-`userId` rule.*
- **No-PII / typed-error sweep** (code review + `grep`): confirm no raw `HTTPException` in business code and
  no token/`email`/name logged on any path — the legacy sphere-delete logs project names, so the port must
  not (log only `user_id`/ids). *Proves the AppError-only + no-PII acceptance criterion.*

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| Sphere/project not found, or owned by another user | `NotFoundError("not_found")` | service → AppError handler | 404 `{error:{code:"not_found",…}}` (identical for missing vs non-owned) |
| Sphere create/update exact duplicate (case-sensitive) | `DuplicateSphereNameError("duplicate_sphere_name")` | spheres service | 400 `{error:{code,message}}` |
| Sphere create/update fuzzy-similar name | `SimilarSphereNameError("similar_sphere_name")` | spheres service | 400 + `error.details.similar_names: [...]` |
| Project create parent missing **or** non-owned | `ParentProjectNotFoundError("parent_project_not_found")` | projects service | 400 (identical either way — no existence leak) |
| `project_type` out of `{mission,provision}` | `InvalidProjectTypeError("invalid_project_type")` | schema/service | 422 |
| Other bad input (missing required, bad types) | `ValidationError`→ `AppError("validation_error")` | request validation | 422 `{error:{code,message}}` |
| Sphere delete mid-transaction failure | exception → transaction rollback | spheres service (`async with` txn) | 500 typed AppError; no partial cascade |

# Review lenses (pre-answer)

- **Scope / strategy.** Minimum viable: reuses the shipped models + the tags router/service pattern; adds two
  verticals + one pure helper + one migration. No new service/abstraction. `move`/`move-preview` deferred
  (its cascade crosses out-of-slice tables) — keeps the slice self-contained. Reversible: routers are additive;
  the only schema change is the constraint **drop**, which has a `downgrade`.
- **Architecture.** router→service→async SQLAlchemy repo (mirrors `tags.py`); one tenant dependency (`sub`);
  every unhappy path is a typed `AppError` mapped by the existing single handler (error map above), never a
  raw `HTTPException`. The destructive sphere-delete and the FK product-cascade run inside one transaction.
- **Completeness.** Create vs update asymmetry (coerce vs preserve), parent-ownership no-leak, case-sensitive
  dup vs fuzzy, delete-cascade edge, ignored client `userId`, list ordering — all enumerated + tested.
  Position auto-compute for budget life-sphere creates is included (legacy parity).
- **Tests & verification.** Each acceptance criterion maps to a named test (above); DB-backed tests run under
  `make verify` (local Docker PG/Redis); `alembic upgrade head` applies the drop so update-preservation is
  proven against the real schema.

# Risks & migrations

- **CHECK-constraint drop (schema change, agent-authored migration).** `op.drop_constraint(...)` with a
  `downgrade` that re-adds it. Risk: existing rows already satisfy the constraint, so the drop is safe and
  non-destructive; `alembic check` guards model↔migration drift. Rollback: `downgrade` re-adds the constraint
  (only safe while no work-time row carries a sphere — acceptable pre-prod).
- **Destructive sphere-delete cascade.** Deleting a sphere deletes matching projects + their products. This is
  legacy behavior; it is owner-scoped and transaction-wrapped, with an explicit test asserting cross-tenant
  rows are untouched. No mitigation beyond faithful porting + the test.
- **Shared-DB safety.** No new schema/table; only a constraint drop scoped to `focal.projects`. The
  `focal`-scoped Alembic `_include_object` filter (`alembic/env.py:17`, from `focal-foundation`) keeps
  autogenerate off other schemas.
- **`move` deferral** is recorded (not dropped) — lands once tasks/calendar/bookings exist.
- **Planned test break (handled in-slice).** Dropping the constraint invalidates the existing
  `tests/test_models_db.py` `IntegrityError` assertion; slice 3 updates that test in the same change, so
  `make verify` stays green.

# Scope check

- [x] Matches the task's Scope and Out of scope (spheres + projects only; `move`/move-preview, tasks/tags,
      mindmap, calendar/CRM/etc. stay out; no frontend; no shared-package extraction).
- [x] Small enough to review in one sitting **per slice** — 4 sequenced, each green + independently gate-coded.
- [x] Size smell: no new service/abstraction; the one migration is the agreed exception, reviewed like code.

# Out of scope

- `/api/projects/:id/move` + `/move-preview` (deferred — cross-table cascade); tasks/tags/`task_tags`/
  `taskSort` and mindmap nodes/edges/init/batch (other Phase-1 slices); the React frontend; calendar/CRM/
  Google/habits/dashboard/push (Phases 2–5); `timezone`/`datePresetRange` + shared-calendar RBAC (Phase 2);
  `foc_`/AI (Phase 7); real-data ETL (§6); `shared/python` extraction.
