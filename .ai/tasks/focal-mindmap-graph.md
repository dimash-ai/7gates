# Goal

Port Focal's **MindMap graph backend** — the custom node/edge graph that the *Goals* canvas renders,
plus the `/api/mindmap/init` aggregate — from the standalone Express/Drizzle app onto the Focal FastAPI
backend, faithful to the legacy contract. After this slice, the MindMap nodes/edges and the init payload
are reachable as tenant-scoped, typed FastAPI endpoints the existing client can call unchanged.

Third and last of the slices the former `focal-mindmap-core` was split into for Phase 1 of
[superapp/apps/focal/docs/MIGRATION_PLAN.md](../../superapp/apps/focal/docs/MIGRATION_PLAN.md) §9
(after `focal-spheres-projects` and `focal-tasks-tags`). Builds on the approved `focal-foundation`
(the `mindmap_nodes` / `mindmap_edges` / `goals` models already landed there) and `focal-spheres-projects`
(the `init` aggregate includes the user's projects).

> **Binding contract = the legacy source** (`focal/server/routes.ts` + `focal/server/storage.ts` +
> `focal/shared/schema.ts`); cited line numbers are the authority.
> `superapp/apps/focal/docs/contract-freeze/` is the path/column inventory. Behavior is reverse-engineered
> and **rebuilt idiomatically (router → service → async SQLAlchemy repo), not transliterated** — but must
> match observably (contract tests).

> **Backend-only slice.** No React `features/` UI — the **Goals MindMap canvas (`@xyflow/react`) is a
> later frontend slice**. Responses **preserve the legacy camelCase field names** (`positionX`,
> `positionY`, `sourceNodeId`, `targetNodeId`, `sourceHandle`, `edgeType`, `strokeColor`, `hasArrow`,
> `fullDescription`, `customColor`, `nodeData`, …) via Pydantic `by_alias`; request bodies **accept** those
> aliases (`populate_by_name`) and **ignore unknown fields** (`extra="ignore"`). Paths are relative to the
> pipeline root; service at `superapp/apps/focal/server`, legacy read-only at `focal/`.

> **No goals REST CRUD — by design.** The legacy app exposes **no `/api/goals*` endpoints** (verified:
> none registered in `routes.ts`); goals are read-only via the AI/agent surfaces (`/v1/goals`, Phases 7–8).
> The `goals` model already exists from foundation. **This slice adds no goals routes.** "Goals" is the
> *page* that renders this MindMap.

> **Identity & tenant model — the load-bearing decision.** MindMap node/edge ids are **shared
> client-supplied strings** (e.g. `"life-goal"`, `"mission"`, `"budget"`, `"e-goal-mission"`) — the *same*
> id appears on **every** user's canvas. The legacy gave each user their own copy via a `userId::id`
> scoped-id prefix (`buildMindmapScopedId`, `storage.ts:180`). The new contract instead uses a **composite
> primary key `(user_id, id)`** on both tables — idiomatic, no string-munging, and the client id is unique
> *within a user*. This is a **schema change** (foundation shipped a single-column `id` PK), so it carries a
> model PK change **+ an agent-authored migration** (see Scope). Every read/upsert/delete is scoped to the
> JWT `sub` (the composite PK makes the lookup `(sub, id)` natural); this also fixes the legacy's **unscoped**
> `DELETE /api/mindmap-nodes/:id` (`routes.ts:4705`, no ownership check). Client-supplied `userId` is ignored.

> **Error envelope (this slice's contract):** every business error is a typed `AppError` subclass mapped to
> `{error:{code,message}}` (no raw `HTTPException`). `not_found` (404) for a **`GET` or `DELETE`** on a
> node/edge that is missing **or** owned by another user (an unknown/malformed `:id` included — the path
> param is an opaque `str`, never coerced, so it never produces FastAPI's `422`). A **`PUT`/batch upsert
> never 404s on an unknown id** — it creates the caller's own `(sub, id)` row. `validation_error` (422) for
> a missing required field (edge `sourceNodeId`/`targetNodeId`, a batch node without `id`), an over-limit
> `fullDescription` (> 2500) or `sourceNodeId`/`targetNodeId` (> 100).

# Scope

**Domain models + the identity migration**

- `mindmap_nodes` and `mindmap_edges` landed in `focal-foundation` (`app/models/mindmap.py`) with a
  **single-column `id` PK**. **Change the PK to composite `(user_id, id)`** on both models (`user_id` and
  `id` both `primary_key=True`; `id` is the client-supplied string, an **unbounded `String`** — a long
  node/edge id is valid, not an error). Keep: **no DB FK between edges and nodes** (edges reference node ids
  as plain `varchar(100)` — only those two fields are length-capped, faithful); the style defaults
  (`source_handle="bottom"`, `target_handle="top"`, `edge_type="default"`, `stroke_color="#3b82f6"`,
  `stroke_width=2`, `has_arrow=true`; node `position_x/y=0`).
- **Agent-authored migration (documented exception).** Alembic autogenerate doesn't reliably emit a PK
  swap, so — as with the `focal-spheres-projects` CHECK-drop — the agent **writes & commits** the migration:
  for each table, drop the single-column PK and create the composite PK (e.g.
  `op.drop_constraint("pk_mindmap_nodes", "mindmap_nodes", schema="focal", type_="primary")` then
  `op.create_primary_key("pk_mindmap_nodes", "mindmap_nodes", ["user_id","id"], schema="focal")`; same for
  `mindmap_edges`), with an **explicitly irreversible `downgrade` that `raise`s** — reverting to a
  single-column `id` PK is unsafe once per-user duplicate ids exist, so the migration documents this rather
  than promising a lossy revert. **Confirm the actual PK constraint name from the foundation baseline
  migration first** (the naming convention yields `pk_<table>`, but verify before the `drop_constraint`). Applied via `alembic upgrade head` so `make verify` + `alembic check`
  run against the new PK.
- **RLS is out of scope** (align with the other Phase-1 slices): no `focal.*` table carries a policy yet;
  tenant isolation is enforced at the **app layer** (every query filtered by `sub`, natural with the composite
  PK) and tested; RLS lands later in a dedicated enablement step.

**Init — `GET /api/mindmap/init`** (`routes.ts:4470`-`4509`)

- Returns the canvas's initial aggregate for the user: `{ projects, activities, edges, nodes }`. `projects`
  (from `focal-spheres-projects`), `nodes` + `edges` (this slice).
- **`activities` is not yet ported (Phase 4)** → return **`activities: []`** for now (documented; Phase 4 fills it).
- **The 5-min in-process `mindmapCache` is NOT ported** — single-process hack; return the live aggregate. The
  `noCache` query param is accepted and ignored. (A Redis cache can be added later if a hot path demands it.)

**Edges — `/api/mindmap-edges`, `/api/mindmap-edges/:id`**

- **List — `GET /api/mindmap-edges`** (`routes.ts:4511`): the user's edges.
- **Upsert — `PUT /api/mindmap-edges/:id`** (`routes.ts:4526`, storage `upsertMindmapEdge`,
  `storage.ts:5923`): require `sourceNodeId` + `targetNodeId` (missing → `validation_error`); apply the style
  defaults for omitted fields; **on `(sub, id)` conflict, update the style fields only** (`source_handle`,
  `target_handle`, `edge_type`, `stroke_color`, `stroke_width`, `stroke_dasharray`, `has_arrow`, `updated_at`)
  — `sourceNodeId`/`targetNodeId` are set on insert and **not changed** on a conflict update (faithful).
  `sourceNodeId`/`targetNodeId` are `≤ 100` chars (the column cap; over-limit → `validation_error`).
  **Dangling edges are allowed** — the legacy does **not** verify that `sourceNodeId`/`targetNodeId` exist (no
  FK); a referenced node need not exist (faithful). Scoped to `sub`.
- **Delete — `DELETE /api/mindmap-edges/:id`** (`routes.ts:4564`): `204 No Content`; scoped to `sub`
  (`not_found` if missing/non-owned).

**Nodes — `/api/mindmap-nodes`, `/api/mindmap-nodes/:id`, `/api/mindmap-nodes/batch`**

- **List — `GET /api/mindmap-nodes`** (`routes.ts:4584`): the user's nodes.
- **Get — `GET /api/mindmap-nodes/:id`** (`routes.ts:4599`): single node; `not_found` if missing/non-owned.
- **Upsert — `PUT /api/mindmap-nodes/:id`** (`routes.ts:4618`, storage `upsertMindmapNode`,
  `storage.ts:6000`): **partial-merge update** — only fields explicitly provided are written; unset fields
  keep their existing values (`storage.ts:6020`). Editable: `positionX`, `positionY`, `width`, `height`,
  `label`, `description`, `fullDescription` (**≤ 2500 chars — over-limit → `validation_error`**),
  `customColor`, `nodeData` (JSONB, e.g. budget nodes `{currency,totalValue,value}`) — **`nodeData`, when
  provided, replaces the full document** (whole-field write, not a deep-merge). Defaults `position_x/y=0`
  on insert. Scoped to `sub`.
- **Batch upsert — `POST /api/mindmap-nodes/batch`** (`routes.ts:4660`): body `{ nodes: [...] }`, each node
  partial-merged, **applied atomically in one transaction** (a documented improvement over the legacy's
  per-node `Promise.all`); returns **one row per input item, in input order** (a duplicated id yields the
  final-state row repeated). **Empty `nodes` → `[]`**; a node **without `id` → `validation_error`**;
  **duplicate ids within one batch → last-wins** (applied in order); a missing/non-array `nodes` or a bad
  field type → `validation_error` (the request-validation handler maps Pydantic errors to the envelope). A
  body `id` on `PUT` defers to the path. Scoped to `sub`.
- **Delete — `DELETE /api/mindmap-nodes/:id`** (`routes.ts:4705`): `204 No Content`; **scoped to `sub`**
  (tightened — legacy had no ownership check). Deleting a node does **not** remove incident edges (no FK —
  they remain, now dangling, consistent with dangling-edges-allowed).

**Cross-cutting**

- Every endpoint tenant-scoped to `sub` (`get_current_user_id`); no cross-tenant access. Every `:id` path
  param is an **opaque `str`** (never coerced → never a framework `422`): `GET`/`DELETE` on an
  unknown-or-non-owned id → typed `not_found` (404), while `PUT`/batch are **upserts** that create/update the
  caller's own `(sub, id)` row (no 404 on a new id). A body that also carries `id` **defers to the path `:id`**.
  Client-supplied `userId` ignored. Async; SQLAlchemy 2.0 + Pydantic v2. List/get/init return the legacy
  array/object camelCase shapes; **list/init order is intentionally unspecified** (the legacy applies none —
  tests assert membership, not order). Partial-merge upsert semantics are preserved exactly — pinned by contract tests.

**Tests** (vs local Docker Postgres)

- **Composite-PK isolation (the headline fix):** two different users each create a node **and** an edge with
  the *same* id (e.g. `"mission"`) — both succeed and don't collide; each sees only their own.
- Edge upsert (create; on `(sub,id)` conflict, **style-only** update with `sourceNodeId`/`targetNodeId`
  **preserved** — a conflict `PUT` changing them leaves them unchanged; **dangling edge accepted**; missing
  `sourceNodeId`/`targetNodeId` → `validation_error`); edge list/delete.
- Node upsert **create** vs **partial-merge** (a `PUT` sending only `positionX/Y` must not null
  `label`/`nodeData`); `fullDescription` > 2500 → `validation_error`; node list/get/delete.
- **Batch**: input order, partial-merge, **empty `nodes` → `[]`**, a node without `id` → `validation_error`,
  duplicate ids → last-wins, and atomicity (a bad entry rolls back the whole batch).
- **Tenant isolation (tightened):** a second user's `GET`/`DELETE` of the first user's id → `not_found` (no
  leak, incl. the delete the legacy left unscoped); a second user's `PUT` to a **shared** id (e.g. `"mission"`)
  creates/updates only its **own** `(sub, id)` row and leaves the first user's row untouched.
- **Opaque id**: unknown/malformed `:id` on a node/edge `GET` or `DELETE` → typed `not_found` (404); a `PUT`
  to a new id upserts (creates), not 404.
- **init**: aggregate returns the user's `projects` + `nodes` + `edges`, with `activities: []`; `noCache` ignored.
- Contract tests pin the camelCase node/edge shapes + the error envelope.

# Out of scope

- **The Goals / MindMap React canvas (`@xyflow/react`)** — a later frontend slice; this is backend-only.
- **Goals REST CRUD** — none exists in the source; the `goals` model is already present, no routes here.
- **`activities` in the init payload** — returns `[]` until Phase 4 ports activities.
- **The 5-min in-process init cache** — not ported; live aggregate instead.
- **The `userId::id` scoped-id string scheme** — replaced by the composite PK `(user_id, id)` (the migration
  for that PK change **is** in scope here).
- **RLS policies** — the dedicated enablement step. **React frontend**; calendar/CRM/Google/habits/dashboard/
  push (Phases 2–5); `foc_`/AI (Phases 7–8); ETL (§6); shared-package extraction.

# Acceptance criteria

- [ ] `cd superapp/apps/focal/server && make verify` is green (ruff + mypy + pytest); any `uv.lock` change is
      committed; `uv run alembic check` shows no model/migration drift (incl. the composite-PK migration).
- [ ] **Composite PK `(user_id, id)`** on `mindmap_nodes` + `mindmap_edges`: two different users each create a
      node and an edge with the **same** `id` (e.g. `"mission"`) with no collision, each scoped to itself; the
      **agent-authored PK migration** (drop single-col PK → create composite PK, both tables, with an
      **irreversible downgrade that raises**) is committed and applied, and `alembic check` is clean (tested).
- [ ] Node + edge CRUD works at the `routes.json` paths (`GET /api/mindmap-nodes`,
      `GET/PUT/DELETE /api/mindmap-nodes/:id`, `POST /api/mindmap-nodes/batch`, `GET /api/mindmap-edges`,
      `PUT/DELETE /api/mindmap-edges/:id`), tenant-scoped; responses camelCase matching the legacy shape (contract test).
- [ ] **Node upsert is partial-merge:** a `PUT`/batch entry sending only `positionX`/`positionY` updates those
      and **preserves** existing `label`/`description`/`fullDescription`/`customColor`/`nodeData` (tested).
- [ ] **Edge upsert** creates on a new `(sub,id)` and on conflict updates **style fields only** —
      `sourceNodeId`/`targetNodeId` are **preserved** (a conflict `PUT` changing them leaves them unchanged);
      both required on create (missing → `validation_error`); a **dangling** edge (referenced node absent) is
      accepted (tested).
- [ ] **`fullDescription` > 2500 chars**, or `sourceNodeId`/`targetNodeId` **> 100 chars**, →
      `validation_error` (422) (tested).
- [ ] **Batch**: returns one row per input item in input order, each partial-merged; **empty `nodes` → `[]`**;
      a node without `id` → `validation_error`; duplicate ids → last-wins; a bad entry rolls back the whole
      batch (tested).
- [ ] **Tenant isolation (tightened):** a second user's `GET`/`DELETE` of the first user's id → `not_found`
      (no leak; `DELETE` is ownership-checked, which the legacy was not); a second user's `PUT` to a shared id
      updates only its own `(sub, id)` row, leaving the first user's untouched (tested).
- [ ] **`GET /api/mindmap/init`** returns `{ projects, activities, edges, nodes }` for `sub`, with projects +
      nodes + edges populated and `activities: []`; `noCache` accepted and ignored (tested).
- [ ] An unknown/malformed `:id` on a node/edge `GET` or `DELETE` yields the typed `not_found` (404)
      envelope, never a framework `422`; a `PUT` to a new id upserts (creates) instead of 404ing (tested).
- [ ] A body/query `userId` ≠ `sub` is served against `sub`'s data only, and any other unknown body field is
      ignored (`extra="ignore"`) (tested).
- [ ] Every business-logic error path raises a typed `AppError` (`{error:{code,message}}`), never a raw
      `HTTPException`; no PII logged on error paths (review + grep).
- [ ] No `/api/goals` route/service, no React canvas, no out-of-scope domain is added.

# Verification commands

```sh
# focal's documented local-first exception (apps/focal/CLAUDE.md): Postgres + Redis via compose
docker compose -f superapp/apps/focal/docker-compose.yml up -d

cd superapp/apps/focal/server
uv sync --frozen
uv run alembic upgrade head     # applies the committed composite-PK migration
make verify
uv run alembic check            # no drift between models and committed migrations
```
