# Summary

Implement `focal-agent-tasks` (Phase 8, slice B2): the agent **tasks** endpoints on the existing
`/api/ai-agent/v1` router — `GET /tasks` (tasks:read, filtered by status/due/tz) and `PATCH
/tasks/{id}/complete` (tasks:write, idempotent). Reuses the slice-B1 foundation
(`get_agent_principal`/`require_scope`/`AgentApiError`/`get_agent_session`/`_resolve_timezone`). No
schema change. Task: [focal-agent-tasks.md](../tasks/focal-agent-tasks.md). Legacy: `ai-agent.ts:781-862`.

## Decisions (design + the Gate-1 rulings)

- **`app/schemas/agent_api.py`** (modify) — add `AgentTaskRead` (`BaseModel` + `from_attributes`,
  `to_camel` alias generator): `id, title, description, due_date, due_time, priority, status, completed,
  completed_at, tags, project_id, product_id` (camelCase out; nullable mirrors the model; **omits**
  `user_id` + audit timestamps). Add `TasksEnvelope {ok, data: list[AgentTaskRead]}` and `OkEnvelope
  {ok: bool = True}` (the bare success body for completion).
- **`app/services/agent_data.py`** (modify) — extend `AgentDataService`:
  - `list_tasks(user_id, status, due_before: date | None)` — `select(Task)` where `user_id == ` and
    `status == status`; when `due_before` is given, also `Task.due_date <= due_before`; order by
    `due_date`; return `[AgentTaskRead.model_validate(row) …]`.
  - `complete_task(user_id, task_id) -> bool` — the idempotent flip, returning **whether the task exists
    for this user** (the router maps False → 404, so the service stays free of web errors, like the
    events methods): `update(Task).where(id ==, user_id ==, Task.completed.is_(False)).values(
    status="completed", completed=True, completed_at=utcnow()).returning(Task.id)` with
    `execution_options(synchronize_session=False)`. If a row was flipped → `commit()` + return True.
    Else `select(Task.id).where(id ==, user_id ==)` — found (already completed) → True (idempotent,
    no write); none → False.
- **`app/api/agent_data.py`** (modify) — module singletons `_tasks_read = require_scope("tasks:read")`,
  `_tasks_write = require_scope("tasks:write")`; `_VALID_TASK_STATUSES = ("pending", "in_progress",
  "completed", "cancelled")`:
  - `GET /tasks` (`Depends(_tasks_read)`) — `_resolve_timezone(tz)` first (bad tz → 400, even when `due`
    is absent, matching the legacy); `status` (default `pending`) not in the set → 400; `due_before =
    today-in-tz if due == "today" else None` (any other `due` value applies no filter); returns
    `TasksEnvelope`.
  - `PATCH /tasks/{task_id}/complete` (`Depends(_tasks_write)`) — `if not await service.complete_task(...)
    : raise AgentApiError("Task not found", status_code=404)` (**`status_code` is keyword-only** on
    `AppError.__init__`; a positional arg would `TypeError`); returns `OkEnvelope` (whether
    just-completed or already-completed — idempotent).
- **Idempotency** — only a `completed IS false` row is flipped, so `completed_at` is never overwritten
  and a future completion webhook (deferred slice) fires once. The completion **webhook is deferred**.
- **Tenant** = the token's `user_id` on both endpoints. Manual validation → `AgentApiError` (not
  Pydantic 422). No migration.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/schemas/agent_api.py` | modify | `AgentTaskRead`, `TasksEnvelope`, `OkEnvelope` |
| `app/services/agent_data.py` | modify | `list_tasks`, `complete_task` |
| `app/api/agent_data.py` | modify | the two `/tasks` routes + status validation |
| `tests/test_agent_tasks_db.py` | add | filters, idempotent complete, scope, tenant, 404 |

# Implementation slices

1. **Schemas + service.** *Verify:* imports + ruff/mypy.
2. **Router.** *Verify:* `make verify`.
3. **Tests.** *Verify:* full `make verify` green.

# Tests (`tests/test_agent_tasks_db.py`, DB-backed; seeds tokens + tasks)

- **list default/status:** default `status=pending` returns only the caller's pending tasks ordered by
  `due_date`; `status=in_progress` filters; an unknown status → 400.
- **due filter:** `due=today` returns only `due_date <= today-in-tz`; `due=tomorrow` (any non-`today`)
  applies **no** filter (returns the unfiltered set); an invalid `tz` → 400.
- **projection:** exact agent key-set — no `userId`, `createdAt`/`updatedAt`.
- **scope:** a token without `tasks:read` → 403 on GET; without `tasks:write` → 403 on PATCH.
- **complete:** a pending task → 200 `{ok:true}` and the row is `completed=true`/`status=completed`/
  `completed_at` set; a **second** call → 200 `{ok:true}` with `completed_at` unchanged (idempotent).
- **complete 404:** a missing id → 404; another user's task → 404 (and it stays incomplete).
- **tenant:** user-A's token never lists or completes user-B's tasks.

# Error & rescue map

| failure | error | response |
|---------|-------|----------|
| unknown status / invalid tz | `AgentApiError` | 400 `{ok:false,error}` |
| token lacks `tasks:read` / `tasks:write` | `AgentApiError` (from `require_scope`) | 403 |
| complete a missing / other-user task | `AgentApiError` | 404 |

# Risks

- **Idempotency** — the atomicity lives in the **single** `UPDATE … WHERE completed IS false` statement:
  at most one caller flips the row (and sets `completed_at` once); any later/concurrent caller matches 0
  rows, falls to the existence check, and returns `{ok:true}` with no write. The serial repeat-call test
  exercises exactly that no-flip path (the same branch a concurrent loser takes) — it asserts
  idempotency of the contract, not literal concurrency.
- **`completed IS NULL` is out of scope** — `completed` defaults to `False` and the app never writes
  NULL, so a NULL-completed row is not an app-producible state. Matching the legacy `= false` guard, such
  a row is treated as already-completed (the existence check returns it → `{ok:true}`, no flip); it is
  not specially handled.
- **No Pydantic coercion** — `status`/`tz`/`due` are `str`; all validation is manual → no 422 leaks the
  agent envelope.
- **No migration / no behavior change** to existing endpoints — additive only.

# Scope check

- [x] Matches the task (tasks read + complete; goals/time-budgets/webhook deferred).
- [x] Reviewable in one pass — two service methods + two routes + schemas + tests; reuses B1.
- [x] Size smell: small, no new module, no schema change.

# Out of scope

The completion webhook (`notifyAgent`); `/v1/goals` + `/v1/time-budgets` (slice B3); rate-limiting;
`ai_agent_logs`; iCal; FastMCP; React UI; ETL.
