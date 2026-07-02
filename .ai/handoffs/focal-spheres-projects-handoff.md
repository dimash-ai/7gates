# Stage

Gate 5 — final release review for `focal-spheres-projects`
([task](../tasks/focal-spheres-projects.md) · [plan](../plans/focal-spheres-projects-plan.md)).
Cumulative change: the spheres + projects backend vertical on `feature/focal-migration`, commits
`42d912d..b159be7` (four gated slices + a migration-fix/coverage pass). All four slices cleared
`/gate-code` (9.2 / 9.2 / 9.4 / 9.6); tests cleared `/gate-test` (9.3).

# What changed

Phase-1 (MindMap planning core) backend, built **self-contained** in `apps/focal/server` (no shared
`shared/python` / `@allosta/*` — consistent with the plan-v4 self-contained decision), in four
independently-reviewed slices plus a hardening pass:

1. **Shared primitives** — the `findSimilar` fuzzy matcher (`app/domain/similar.py`, a faithful port
   of legacy `utils/fuzzy.ts`), the typed `AppError` envelope (optional `details` + a
   `RequestValidationError` handler so malformed input also returns `{error:{code,message,details}}`),
   and camelCase Pydantic v2 schemas for spheres/projects.
2. **Spheres vertical** — `life_spheres` CRUD: case-sensitive duplicate + fuzzy-similar (≥0.75) name
   rejection (excluding self on update), and the destructive **owner-scoped delete-cascade** (deletes
   the owner's projects matching by `sphere` name + their child products via the FK, one transaction).
3. **Projects vertical** — project/product CRUD: create (parent-ownership with no existence leak +
   `body ?? parent ?? default` inheritance + sphere coerced to null on work-time + budget position
   auto-compute), update (preserves the sphere, never reparents), delete (cascades to child products);
   plus the **`work_time_sphere` CHECK-drop migration** (relaxed to match legacy update-preserve).
4. **Project reads** — `GET /api/projects`, `/api/projects/root`, `/api/projects/{id}/products`
   (legacy tenant filter + `sort_order` ordering; `/root` declared before `/{id}`), + API contract tests.

Cross-cutting: every endpoint is tenant-scoped to the JWT `sub` (any client-supplied `userId` in body
or query is ignored), business errors are typed `AppError` (never raw `HTTPException`), responses are
camelCase, and behavior is reverse-engineered from legacy `routes.ts` / `storage.ts`.

# Files touched

~16 files under `apps/focal/server/`. New: `app/domain/similar.py`, `app/schemas/spheres.py`,
`app/schemas/projects.py`, `app/services/spheres.py`, `app/services/projects.py`, `app/api/spheres.py`,
`app/api/projects.py`, `alembic/versions/…drop_work_time_sphere_check.py`, `tests/test_similar.py`,
`tests/test_schemas.py`, `tests/test_errors.py`, `tests/test_spheres_db.py`, `tests/test_projects_db.py`,
`tests/test_contracts.py`, `tests/test_migration.py`. Modified: `app/errors.py`, `app/main.py`,
`app/models/projects.py` (CHECK removed), `tests/test_models_db.py` (constraint test flipped).

# Tests run

```sh
cd superapp/apps/focal/server && make verify   # docker compose up + ruff + ruff format --check + mypy app + pytest
```

# Verification output

```
All checks passed!                              # ruff check + ruff format --check
Success: no issues found in 39 source files     # mypy app
======================= 167 passed, 2 warnings in ~10s =========================
```

(The 2 warnings are a pre-existing Starlette/httpx deprecation and a pyjwt short-HMAC-key note from an
auth negative test — neither is a failure.) The hand-authored CHECK-drop migration is exercised offline
by `tests/test_migration.py` (`alembic upgrade/downgrade --sql`), which asserts the exact
`DROP/ADD CONSTRAINT ck_projects_work_time_sphere` SQL.

# Still needs review / deferred

- **Frontend deferred** — the React `features/` (xyflow MindMap, Tasks, Tags) ship in a follow-on
  frontend slice once the client toolchain/shell is runnable; the backend exposes `/openapi.json` for
  that slice's `gen:api`.
- **`/api/projects/:id/move` + `/move-preview` deferred** — the legacy `moveProject` cascade reaches
  tasks / calendar_events / bookings (later slices / Phase 2), so it can't be built faithfully yet.
- **Agent-authored migration** — the `work_time_sphere` CHECK-drop is hand-written (a documented
  exception, since Alembic autogenerate can't detect a named CHECK drop); the developer/CI runs
  `alembic upgrade head` against the alembic-managed DB.
- **Tenant scoping is intentionally stricter than legacy** — legacy fetched spheres/projects by id
  only; the task mandates tenant isolation, so a non-owned row reads as `not_found` (or `[]` for
  `/products`, matching legacy's user-filtered query).

# PR / release notes (for reviewers)

**Focal: life spheres + project/product tree on the superapp FastAPI stack.**

Ports Focal's planning core — life spheres and the project/product hierarchy — into
`apps/focal/server` as tenant-scoped, typed, camelCase FastAPI endpoints faithful to the legacy
Express app: sphere CRUD (with duplicate/fuzzy-name guards and the destructive sphere-delete cascade),
project/product CRUD (parent inheritance, work-time sphere coercion on create vs preservation on
update, position auto-compute, delete-cascade to products), and the read endpoints (list / root /
products). Relaxes the work-time/sphere DB constraint to match legacy (via a reviewed migration). The
React UI and the `move` operation are deferred to later slices. `make verify` is green (167 tests,
incl. DB-backed + migration-SQL tests). No secrets, tokens, or PII appear in this change.

# Status

CODEX APPROVED (9.2 / 10) — final gate cleared for release. All gates ≥ 9.0:
task 9.2 · plan 9.3 · code 9.2 / 9.2 / 9.4 / 9.6 · test 9.3 · final 9.2.
Committed on `feature/focal-migration` (not pushed). Non-blocking follow-ups: tenant-filtered SELECTs
in the services (defense-in-depth alignment with the root tenant-query policy — behavior is already
correct + tested), and capturing an online `alembic upgrade head` / `alembic check` transcript at
deploy (the migration is offline-tested in `test_migration.py`).
