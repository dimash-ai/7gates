# Goal

Port the last two agent read endpoints (Phase 8, slice B3 of the `foc_` agent API), reusing the shipped
foundation: `GET /api/ai-agent/v1/goals` (goals:read) and `GET /api/ai-agent/v1/time-budgets`
(budgets:read). With these, every legacy agent `/v1` **data** endpoint except the iCal feed is ported.
Legacy: `ai-agent.ts:864-905`.

# Scope

- **`app/schemas/agent_api.py`** (modify) — add:
  - `AgentGoalRead` (camelCase out): `id, title, description, status, progress, parent_goal_id` —
    **never** `user_id`/audit timestamps. `GoalsEnvelope {ok, data: list[AgentGoalRead]}`.
  - `AgentProjectBudgetRead`: `id, name, project_type, sphere, status, is_work_time,
    allocated_work_hours, allocated_hours, gives_energy`. `TimeBudgetsEnvelope {ok, data:
    list[AgentProjectBudgetRead]}`.
- **`app/services/agent_data.py`** (modify) — extend `AgentDataService`:
  - `list_goals(user_id)` — `select(Goal)` where `user_id ==`, ordered by `status`, then `title`;
    return `list[AgentGoalRead]`.
  - `list_time_budgets(user_id)` — `select(Project)` where `user_id ==` **and `status == "active"`**,
    ordered by `name`; return `list[AgentProjectBudgetRead]`. (The "time-budgets" agent view is the set
    of **active projects** with their allocation fields — the legacy reads the `projects` table here,
    **not** the `time_budget_*` tables.)
- **`app/api/agent_data.py`** (modify) — module singletons `_goals_read = require_scope("goals:read")`,
  `_budgets_read = require_scope("budgets:read")`:
  - `GET /goals` (`Depends(_goals_read)`) → `GoalsEnvelope`.
  - `GET /time-budgets` (`Depends(_budgets_read)`) → `TimeBudgetsEnvelope`.
  - No query params (both are plain tenant-scoped lists).
- **Tests** (`tests/test_agent_goals_budgets_db.py`).

# Decisions (design rulings to confirm at Gate 1)

- **Reuses the slice-B1/B2 foundation** — `get_agent_principal` / `require_scope` / `AgentApiError`
  ({ok:false,error}) / `get_agent_session` / the `{ok,data}` envelope. New scopes exercised:
  `goals:read`, `budgets:read`.
- **`/v1/time-budgets` is projects-based by design** — it returns the caller's **active** projects (the
  legacy agent contract); non-active projects are excluded. It deliberately does **not** read the
  `time_budget_settings`/`category`/`item` tables (those back the user-facing `/api/time-budgets`
  surface, already shipped).
- **Projections** omit `user_id` + audit timestamps; tenant = the token's `user_id`. No schema change,
  no query params.

# Out of scope

- The iCal feed (`/v1/calendar.ics`); webhooks; per-token rate-limiting; `ai_agent_logs`; the FastMCP
  adapter; React UI; ETL.

# Acceptance criteria

- [ ] `GET /v1/goals` returns the caller's goals as `{ok, data}` ordered by `status` then `title`; the
      item carries only the agent fields (no `userId`/audit timestamps); a token without `goals:read` →
      403; tenant-isolated (never another user's goals).
- [ ] `GET /v1/time-budgets` returns only the caller's **active** projects (a non-active project is
      excluded) as `{ok, data}` ordered by `name`, with the 9-field projection; a token without
      `budgets:read` → 403; tenant-isolated.
- [ ] `make verify` green; no migration (additive code only).

# Verification commands

```sh
make verify
```
