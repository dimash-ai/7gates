# Goal

Port the agent **tasks** data endpoints (Phase 8, slice B2 of the `foc_` agent API), reusing the
auth/scope/envelope foundation already shipped: `GET /api/ai-agent/v1/tasks` (tasks:read, filtered) and
`PATCH /api/ai-agent/v1/tasks/{id}/complete` (tasks:write, idempotent). Legacy: `ai-agent.ts:781-862`.

# Scope

- **`app/schemas/agent_api.py`** (modify) — add `AgentTaskRead` (the agent-facing task projection,
  camelCase out): `id, title, description, due_date, due_time, priority, status, completed,
  completed_at, tags, project_id, product_id` — **never** `user_id` or the audit timestamps. Add
  `TasksEnvelope {ok, data: list[AgentTaskRead]}` and `OkEnvelope {ok}` (the bare success body for the
  complete action).
- **`app/services/agent_data.py`** (modify) — extend `AgentDataService`:
  - `list_tasks(user_id, status, due_before)` — select the user's tasks where `status == status`
    (and, when `due_before` is given, `due_date <= due_before`), ordered by `due_date`; return
    `list[AgentTaskRead]`.
  - `complete_task(user_id, task_id) -> bool` — **idempotent**: `UPDATE tasks SET status='completed',
    completed=true, completed_at=utcnow() WHERE id = + user_id = + completed IS false RETURNING id`. If
    a row was flipped → return True (it was just completed). If not → look the task up: missing/other
    user → raise `NotFoundError`-equivalent (`AgentApiError 404`); already-completed → return False
    (still a 200 `{ok:true}`, the legacy idempotency contract). The completion **webhook notify is
    deferred** to the webhook slice.
- **`app/api/agent_data.py`** (modify) — two routes on the existing `/api/ai-agent/v1` router (module
  scope singletons `_tasks_read = require_scope("tasks:read")`, `_tasks_write =
  require_scope("tasks:write")` to keep the factory call out of a default):
  - `GET /tasks` — `tz` (default `Asia/Almaty`, validated → 400 via the existing `_resolve_timezone`);
    `status` (default `pending`, must be one of `pending, in_progress, completed, cancelled`, else
    400); `due` — when `due == "today"`, filter `due_date <= today-in-tz`. Returns `TasksEnvelope`.
  - `PATCH /tasks/{task_id}/complete` — completes the task; missing/cross-tenant → 404; returns
    `OkEnvelope` (whether just-completed or already-completed — idempotent).
- **Tests** (`tests/test_agent_tasks_db.py`).

# Decisions (design rulings to confirm at Gate 1)

- **Reuses the slice-B1 foundation** — `get_agent_principal` / `require_scope` / `AgentApiError`
  (`{ok:false,error}`) / `get_agent_session`. No new auth surface; the only new scopes exercised are
  `tasks:read` and `tasks:write`.
- **`VALID_TASK_STATUSES = ("pending","in_progress","completed","cancelled")`**; an unknown `status` →
  400 in the agent envelope. Default `pending`. `due=today` is the only supported `due` value (any
  other value is ignored, matching the legacy — only `today` triggers the filter).
- **Idempotent completion** — only a not-yet-completed row is flipped (so `completed_at` is never
  overwritten and a future webhook fires once); a repeat call returns `{ok:true}` without change. A
  missing or other-user task → 404. Manual validation → `AgentApiError`, not Pydantic 422.
- **Projection** omits `user_id` + audit timestamps; tenant = the token's `user_id`. No schema change.

# Out of scope

- The completion **webhook** (`notifyAgent` → the webhook slice); `/v1/goals` + `/v1/time-budgets`
  (slice B3); per-token rate-limiting; `ai_agent_logs`; iCal; the FastMCP adapter; React UI; ETL.

# Acceptance criteria

- [ ] `GET /v1/tasks` defaults to `status=pending` and returns only the caller's pending tasks ordered
      by `due_date`; `status=in_progress` filters to those; an unknown status → 400; `due=today` filters
      to `due_date <= today-in-tz` while any **other** `due` value (or none) applies no date filter; an
      invalid `tz` → 400. The item carries only the agent fields (no `userId`/audit timestamps); a token
      without `tasks:read` → 403.
- [ ] `PATCH /v1/tasks/{id}/complete` flips a pending task to `completed=true`/`status=completed` with
      `completed_at` set and returns `{ok:true}`; a **second** call is idempotent (`{ok:true}`,
      `completed_at` unchanged); a missing or other-user id → 404; a token without `tasks:write` → 403.
- [ ] Tenant isolation on both endpoints; `make verify` green; no migration (additive code only).

# Verification commands

```sh
make verify
```
