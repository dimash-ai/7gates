# PR — focal-tasks-tags (tasks vertical + tags reconcile)

**Title:** `feat(focal): tasks vertical + tags reconcile — date-window list, enrichment, multi-factor priority, completion transition`

Behavior is reverse-engineered from the standalone Focal app (`focal/server/{routes,storage}.ts`,
`focal/server/utils/functions.ts`) and rebuilt idiomatically on FastAPI.

## Summary

Re-platforms Focal's **tasks** domain (`/api/tasks`) onto the FastAPI backend and **reconciles the
already-shipped `/api/tags`** (the `task_tags` master list) to full legacy parity. Backend-only;
tenant-scoped to the JWT `sub`; typed `AppError` envelope throughout; faithful to the legacy contract
with three **documented, intended tightenings** (below). No schema change, no migration.

## What changed

**New (app):**
- `app/domain/daterange.py` — `get_date_range` (strict `YYYY-MM-DD`; missing/malformed → current month).
- `app/domain/completion.py` — `transition_completed_at` (set on `false→true`, clear on `true→false`, else no-op).
- `app/domain/priority.py` — pure scoring: `priority_to_score`, `urgency_score`, `max_hierarchy_priority`,
  `priority_score` (`0.4·mission + 0.3·hierarchy + 0.2·urgency + 0.1·energy`; levels 0.6/0.3).
- `app/schemas/tasks.py` — `TaskCreate`/`TaskUpdate`/`TaskRead`/`EnrichedTaskRead` (camelCase aliases,
  `extra="ignore"`, strict date/time validators, null-vs-omitted via `model_fields_set`).
- `app/services/tasks.py` — DB-backed service: date-window enriched list, get, create, partial update,
  delete; `_hierarchy_context` (product→parent fallback; sphere only when non-work-time), nullish-coalescing
  priority, `_require_owned_link` (project/product/activity owned by `sub`), completion transition.
- `app/api/tasks.py` — thin router; opaque `str` `:id` (→ typed 404, never FastAPI 422).

**Modified (app):**
- `app/errors.py` — add `RelatedRecordNotFoundError` (400).
- `app/deps.py` — add `current_utc_date()` (injectable clock).
- `app/schemas/tags.py` — `color` required + non-blank; explicit-null rejection on PATCH.
- `app/api/tags.py` — POST returns 200 (legacy parity).
- `app/main.py` — include the tasks router.

**Tests:** new `test_{daterange,completion,priority,tasks_db}.py`; extended `test_{tags,tags_db,contracts}.py`.

## Tightenings vs. legacy (intended, documented in the task)

1. **Tenant scoping** of the by-id endpoints and all links to `sub` (legacy fetched/linked by id with no
   ownership check — a latent cross-tenant bug); the enrichment join resolves only the caller's own projects.
2. **`completed: null` is a no-op** (legacy spread would write `NULL`, risking a stale `completed_at`).
3. **Malformed query/`dueDate` → current-month fallback / `validation_error`** (legacy would 500 on a bad
   query date). Activity priority term = `0` until the Phase-4 activities vertical (documented deferral).

## Tests + verification

`make verify` → **ruff ✓ · ruff format ✓ · mypy ✓ (45 files) · pytest 263 passed**; then
`alembic upgrade head` (clean) + `alembic check` → **No new upgrade operations detected**.

## Risks / rollback

- **No schema/migration change** (the `tasks`/`task_tags` models already exist from `focal-foundation`),
  so `alembic check` is clean and rollback is a plain revert — nothing to un-migrate.
- Routers/schemas are additive; the only behavior change to an existing surface is `/api/tags` POST `201→200`
  (parity-correct; pinned by a contract test).
- AI/`foc_`, `taskSort` (client-side), the activities vertical, RLS, and the React UI remain out of scope
  (their homes are named in the task's Out-of-scope).
