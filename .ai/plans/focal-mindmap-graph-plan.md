# Summary

Implement the `focal-mindmap-graph` backend slice on the existing scaffold (the `mindmap_nodes` /
`mindmap_edges` models already landed in `focal-foundation`; the error envelope + `get_current_user_id`
landed in earlier slices; `app/api/tasks.py`+`app/services/tasks.py` are the router→service→async-repo +
partial-merge (`exclude_unset`) + opaque-`:id` patterns to mirror). Four independently-green slices:
**(1) identity migration + schemas** — change the PK to composite `(user_id, id)` on both models, the
agent-authored PK migration, and the node/edge Pydantic schemas; **(2) edges vertical** — list / upsert
(style-only conflict, dangling allowed) / delete; **(3) nodes vertical** — list / get / partial-merge
upsert / atomic batch / delete; **(4) init aggregate** — `GET /api/mindmap/init`. Every endpoint is
tenant-scoped to the JWT `sub`, treats `:id` as an opaque string, and raises only typed `AppError`.
Task: [focal-mindmap-graph.md](../tasks/focal-mindmap-graph.md). Binding contract: legacy
`focal/server/{routes,storage}.ts` + `contract-freeze/`.

## Decisions (design + resolving Gate-1 carryovers)

- **Composite primary key `(user_id, id)` (the load-bearing decision).** MindMap node/edge ids are shared
  client strings (`"mission"`, `"life-goal"`, …) — the same id appears on every user's canvas. The
  foundation shipped a **single-column `id` PK**, which can't host two users' `"mission"` nodes. Change both
  models to a composite PK via an explicit **`PrimaryKeyConstraint("user_id", "id")` in `__table_args__`** —
  NOT just two `primary_key=True` columns: the model declares `id` *before* `user_id`, so column-order would
  yield `(id, user_id)` and conflict with the migration; the explicit constraint pins the order `(user_id,
  id)` (and drop the `primary_key=True` from the `id` column). The client `id` stays an unbounded `String`;
  per-user uniqueness comes from the composite key. This replaces the legacy `userId::id` string-munging
  (`buildMindmapScopedId`) — no scoped-id code.
- **Agent-authored migration (documented exception, Gate-1 ruling).** Autogenerate doesn't reliably emit a
  PK swap, so the agent writes + commits it: for each table
  `op.drop_constraint(op.f("pk_mindmap_nodes"),"mindmap_nodes",schema="focal",type_="primary")` then
  `op.create_primary_key(op.f("pk_mindmap_nodes"),"mindmap_nodes",["user_id","id"],schema="focal")` — use
  `op.f(...)` for the names (naming-convention-safe, matching the check-drop migration), verified against the
  baseline (`pk_mindmap_nodes` / `pk_mindmap_edges`). The **`downgrade` raises** (`raise
  NotImplementedError(...)`) — reverting to a single-column PK is unsafe once per-user duplicate ids exist;
  documented in the migration body. Applied via `alembic upgrade head` so `make verify` + `alembic check` run
  against the composite PK.
- **No new error code.** Reuse `NotFoundError` (404) and `ValidationError` (422) + the existing handlers.
  Mapping: a `GET`/`DELETE` on a missing-or-non-owned `(sub, id)` → `not_found`; a missing edge
  `sourceNodeId`/`targetNodeId`, a batch node without `id`, an over-limit `fullDescription` (>2500) or
  `sourceNodeId`/`targetNodeId` (>100), or a non-array `nodes` → `validation_error` (via the
  `RequestValidationError` handler for Pydantic errors, or an explicit `ValidationError` in the service).
- **Opaque `:id`.** Path params are `str` (never coerced), so unknown ids never produce FastAPI's
  path-validation 422. `GET`/`DELETE` on an unknown id → typed `not_found`; **`PUT`/batch are upserts** that
  create/update the caller's own `(sub, id)` row (never 404 on a new id). A body that also carries `id`
  defers to the path `:id`.
- **Node upsert = partial-merge via `model_fields_set`** (mirrors the tasks PATCH): only keys the client
  sent are written; unset keys keep their value. `nodeData`, when provided, **replaces** the full JSON
  document (whole-field write, not deep-merge). Defaults `position_x/y=0` on insert.
- **Edge upsert = create-or-style-only-conflict.** `sourceNodeId`/`targetNodeId` are **required on every
  `PUT`** (the legacy route validates them before storage, `routes.ts:4529`-`4531`; missing →
  `validation_error`). On create they're stored; on an existing `(sub, id)` only the style fields update
  (`source_handle`,`target_handle`,`edge_type`,`stroke_color`,`stroke_width`,`stroke_dasharray`,`has_arrow`,
  `updated_at`) and the **stored source/target are preserved** (the required body source/target do not
  overwrite — faithful to the legacy conflict set). **Dangling edges allowed** (no FK; a referenced node need not exist).
- **Batch = atomic.** `POST /api/mindmap-nodes/batch` applies all node partial-merges in **one transaction**
  (improvement over the legacy per-node `Promise.all`); returns one row per input item in input order; empty
  `nodes` → `[]`; a node without `id` → `validation_error`; duplicate ids → last-wins; a bad entry rolls back
  the whole batch.
- **`init`** returns `{ projects, activities, edges, nodes }` for `sub`: projects (query `focal.projects`
  scoped to `sub`), nodes + edges (this slice), **`activities: []`** (Phase-4 placeholder). The legacy 5-min
  in-process cache is **not** ported; `noCache` is accepted and ignored. List/init order is intentionally
  unspecified (legacy applies none).
- **No goals REST CRUD** (none in the source). **RLS out of scope** (no `focal.*` policy yet; tenant
  isolation is app-layer, natural via the composite PK, and tested; RLS lands in the dedicated step).
- **Node delete leaves incident edges** (no FK — they remain, now dangling). **DB-backed service, no
  in-memory fallback** (the composite-PK upsert + transactional batch are DB-semantic).
- **Tenancy via the composite key.** Every read/upsert/delete filters on `(user_id == sub, id == :id)`; a
  body/query `userId` is dropped at the schema boundary; unknown body fields ignored (`extra="ignore"`).

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/server/app/models/mindmap.py` | modify | `MindmapNode` + `MindmapEdge`: composite PK via `PrimaryKeyConstraint("user_id","id")` in `__table_args__` (pins `(user_id, id)` order); drop the single-col `primary_key=True` on `id`; keep no edge↔node FK, `source/target_node_id` `varchar(100)`, style defaults |
| `superapp/apps/focal/server/alembic/versions/<rev>_mindmap_composite_pk.py` | add | **agent-authored**: drop `pk_mindmap_nodes`/`pk_mindmap_edges`, create composite PK `(user_id, id)` on both; `downgrade` raises (irreversible) |
| `superapp/apps/focal/server/app/schemas/mindmap.py` | add | `NodeUpsert` (partial, `model_fields_set`), `NodeRead`, `EdgeUpsert` (source/target required + style defaults), `EdgeRead`, `BatchNodes`, `InitRead` (camelCase aliases, `populate_by_name`, `extra="ignore"`; `fullDescription`/`source/targetNodeId` length validators) |
| `superapp/apps/focal/server/app/services/mindmap.py` | add | DB-backed service: node list/get/upsert/batch/delete, edge list/upsert/delete, init aggregate; `_require_node`/`_require_edge` by `(sub, id)` |
| `superapp/apps/focal/server/app/api/mindmap.py` | add | routers for `/api/mindmap/init`, `/api/mindmap-nodes*`, `/api/mindmap-edges*`; opaque `str` ids |
| `superapp/apps/focal/server/app/main.py` | modify | include the mindmap router(s) |
| `superapp/apps/focal/server/tests/test_mindmap_db.py` | add | DB: composite-PK isolation, node/edge upsert + partial-merge, batch, init, tenant, opaque id, dangling edges, node-delete-leaves-edges |
| `superapp/apps/focal/server/tests/test_models_db.py` | modify | its `MindmapNode` scalar lookup `session.get(MindmapNode, "nj")` (`:282`) breaks under a composite PK — update to the composite identity `(user_id, id)` |
| `superapp/apps/focal/server/tests/test_migration.py` | modify | pin the PK swap with offline SQL assertions (`make verify` uses `create_all`, not migrations — `test_migration.py:1`-`6`); the existing helper assumes upgrade success, so assert **upgrade** yields the composite PK and that the **downgrade raises** (irreversible) |
| `superapp/apps/focal/server/tests/test_contracts.py` | modify | pin node/edge camelCase shapes + the init aggregate shape |

# Implementation slices

Each slice is independently reviewable (gate-code → fix loop) and leaves `make verify` green.

1. **Identity migration + schemas (no endpoints).** Change both models to a composite PK via
   `PrimaryKeyConstraint("user_id","id")` in `__table_args__` (drop `primary_key=True` from `id`); write +
   commit the agent-authored PK migration (drop `pk_mindmap_{nodes,edges}` → composite `(user_id, id)`;
   `downgrade` raises); `alembic upgrade head`; confirm `alembic check` clean. **Update the now-broken
   `MindmapNode` scalar lookup in `tests/test_models_db.py:282` to the composite identity**, and **pin the PK
   swap with offline SQL assertions in `tests/test_migration.py`**. Add `app/schemas/mindmap.py` (camelCase
   aliases + `populate_by_name` + `extra="ignore"`; `fullDescription` ≤ 2500 and `source/targetNodeId` ≤ 100
   validators; node partial fields all-optional). *Verify:* `make verify` + `alembic check` green; schemas
   round-trip camelCase↔snake.
2. **Edges vertical.** `app/services/mindmap.py` (edge part) + `app/api/mindmap.py` (edge routes):
   `GET /api/mindmap-edges`, `PUT /api/mindmap-edges/{id}` (source/target **required on every PUT**; create,
   or style-only conflict update preserving the stored source/target; dangling allowed), `DELETE` (204,
   scoped). *Verify:*
   edge tests green incl. conflict-preserves-source/target + dangling + tenant isolation.
3. **Nodes vertical.** Node service + routes: `GET /api/mindmap-nodes`, `GET /{id}`, `PUT /{id}`
   (partial-merge; `nodeData` replace; `fullDescription` limit), `POST /api/mindmap-nodes/batch` (atomic,
   order, empty→[], missing-id→422, dup last-wins), `DELETE /{id}` (204, scoped, leaves edges). *Verify:*
   node + batch tests green; partial-merge proven.
4. **Init aggregate.** `GET /api/mindmap/init` → `{projects, activities:[], edges, nodes}` for `sub`;
   `noCache` accepted+ignored. Include the router in `main.py` (if not already). Extend `test_contracts.py`.
   *Verify:* `make verify` + `alembic check` green end-to-end.

# Tests

- **Composite-PK isolation** (DB): user-a and user-b each create a node **and** an edge with the same `id`
  (e.g. `"mission"`) — both succeed, no collision, each sees only its own. *Proves the headline fix.*
- **Edge upsert** (DB): create; a conflict `PUT` updates style fields and **preserves the stored**
  `sourceNodeId`/`targetNodeId` even when the body sends different ones; **every PUT requires `sourceNodeId`/
  `targetNodeId`** (missing on create OR conflict → `validation_error`); a **dangling** edge (no such node) is
  accepted; over-100 source/target → `validation_error`. Edge list/delete (204).
- **Node upsert** (DB): create with defaults `position_x/y=0`; **partial-merge** — a `PUT` sending only
  `positionX/Y` preserves existing `label`/`nodeData`; `nodeData` provided **replaces** the doc;
  `fullDescription` > 2500 → `validation_error`. Node list/get/delete.
- **Batch** (DB): one row per input in order; empty `nodes` → `[]`; **missing or non-array `nodes` →
  `validation_error`**; a node without `id` → `validation_error`; duplicate ids → last-wins **and the repeated
  output rows both reflect the final merged state**; a bad entry rolls back the whole batch (atomic).
- **Tenant isolation (tightened)** (DB): a second user's `GET`/`DELETE` of the first's id → `not_found` (no
  leak; the delete the legacy left unscoped is now checked); a second user's `PUT` to a shared id updates only
  its own `(sub, id)` row, leaving the first user's untouched.
- **Opaque id** (DB): unknown/malformed `:id` on `GET`/`DELETE` → typed `not_found` (404), never 422; `PUT`
  to a new id upserts.
- **Ignored client identity** (DB): a body/query `userId` ≠ `sub` operates on `sub`'s data only; an unknown
  body field is ignored (`extra="ignore"`); a `PUT` whose body `id` differs from the path `:id` defers to the
  path (the path id wins).
- **Node delete leaves edges** (DB): deleting a node does not remove incident edges (they remain, dangling).
- **init** (DB): returns `{projects, activities:[], edges, nodes}` for `sub`; `noCache` ignored; a second
  user sees only their own.
- **Contracts** (`test_contracts.py`): node/edge responses camelCase; the init aggregate shape.
- **No-PII / typed-error sweep** (review + grep): no raw `HTTPException`; no token/email logged.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| Node/edge missing or non-owned on `GET`/`DELETE` (incl. unknown/malformed `:id`) | `NotFoundError("not_found")` | service (`(sub,id)` lookup) → handler | 404 `{error:{code:"not_found",…}}` |
| Edge create missing `sourceNodeId`/`targetNodeId`; batch node without `id`; non-array `nodes`; bad field type | `RequestValidationError` / `ValidationError("validation_error")` | schema / service → handlers | 422 `{error:{code:"validation_error",…}}` |
| `fullDescription` > 2500, or `source/targetNodeId` > 100 | `ValidationError("validation_error")` | schema validator | 422 |
| Body carries `userId`/unknown fields | ignored (`extra="ignore"`) | schema boundary | no effect; tenant is `sub` |
| Batch mid-item failure | exception → transaction rollback | service (`async with` txn) | 422/500 typed; no partial batch applied |

# Review lenses (pre-answer)

- **Scope / strategy.** Minimum viable: reuses the shipped models + error envelope + the tasks router/
  service/partial-merge patterns; adds one composite-PK migration, one schema module, one service, one
  router, and tests. No new error code, no new abstraction. Goals CRUD, the React canvas, activities-in-init,
  the init cache, and RLS stay deferred (homes named). The PK migration has an explicitly irreversible
  downgrade (documented) — the only non-additive change.
- **Architecture.** router→service→async SQLAlchemy (mirrors `tasks.py`); one tenant dependency (`sub`);
  composite-PK lookups `(sub, id)`; partial-merge via `model_fields_set`; every unhappy path a typed
  `AppError`; the batch runs in one transaction.
- **Completeness.** Composite-PK multi-tenant identity, node partial-merge vs `nodeData` replace, edge
  style-only conflict preserving source/target, dangling edges, batch atomicity + edge-cases, opaque-id
  envelope, node-delete-leaves-edges, init `activities:[]`/no-cache — all enumerated + each mapped to a test.
- **Tests & verification.** Each acceptance criterion maps to a named DB test; `make verify` (local Docker
  PG) + `alembic upgrade head` + `alembic check` all green; the migration is applied so tests run on the
  composite PK.

# Risks & migrations

- **Composite-PK migration (schema change, agent-authored).** Drop single-col PK → composite `(user_id, id)`
  on both tables; verified constraint names `pk_mindmap_nodes`/`pk_mindmap_edges`. Risk: existing rows must
  not violate the new PK — they won't (the foundation tables are empty pre-prod; dev is reset in tests).
  **Downgrade is intentionally irreversible (`raise`)** — a single-col PK can't be restored once per-user
  duplicate ids exist; documented in the migration body. `alembic check` guards model↔migration drift.
- **No other schema change.** Only the PK; columns/indexes unchanged. The `focal`-scoped Alembic filter keeps
  autogenerate off other schemas.
- **Dangling edges by design** (no FK) — a stale edge referencing a deleted node is allowed (faithful);
  tested, not a bug.
- **Shared-DB safety.** Tenancy via the composite key + `sub` filter on every query.

# Scope check

- [x] Matches the task's Scope and Out of scope (mindmap nodes/edges + init only; goals CRUD, the React
      canvas, activities-in-init, the init cache, RLS, `foc_`/AI, ETL, shared-package extraction stay out).
- [x] Small enough to review per slice — 4 sequenced, each green + independently gate-coded.
- [x] Size smell: no new error code, no new abstraction; the one migration is the agreed PK exception.

# Out of scope

- The Goals / MindMap React canvas (`@xyflow/react`); goals REST CRUD (none in source); `activities` in
  init (Phase 4); the 5-min in-process init cache; the `userId::id` scoped-id string scheme (replaced by the
  composite PK); RLS policies; calendar/CRM/Google/habits/dashboard/push (Phases 2–5); `foc_`/AI (Phases 7–8);
  real-data ETL (§6); `shared/python` extraction.
