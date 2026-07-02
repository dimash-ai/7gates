# Summary

Implement `focal-agent-goals-budgets` (Phase 8, slice B3): the last two agent read endpoints on the
existing `/api/ai-agent/v1` router — `GET /goals` (goals:read) and `GET /time-budgets` (budgets:read,
**active projects**). Reuses the B1/B2 foundation; no query params, no schema change. Task:
[focal-agent-goals-budgets.md](../tasks/focal-agent-goals-budgets.md). Legacy: `ai-agent.ts:864-905`.

## Decisions (design + the Gate-1 ruling)

- **`app/schemas/agent_api.py`** (modify) — add (each `BaseModel` + `from_attributes`, `to_camel`):
  - `AgentGoalRead`: `id, title, description, status, progress, parent_goal_id`. `GoalsEnvelope {ok,
    data: list[AgentGoalRead]}`.
  - `AgentProjectBudgetRead`: `id, name, project_type, sphere, status, is_work_time,
    allocated_work_hours, allocated_hours, gives_energy`. `TimeBudgetsEnvelope {ok, data:
    list[AgentProjectBudgetRead]}`.
  - Both omit `user_id` + audit timestamps; nullability mirrors the models.
- **`app/services/agent_data.py`** (modify) — extend `AgentDataService`:
  - `list_goals(user_id)` — `select(Goal).where(Goal.user_id ==).order_by(Goal.status, Goal.title)` →
    `[AgentGoalRead.model_validate(row) …]`.
  - `list_time_budgets(user_id)` — `select(Project).where(Project.user_id ==, Project.status ==
    "active").order_by(Project.name)` → `[AgentProjectBudgetRead.model_validate(row) …]`. The agent
    "time-budgets" view is the **active projects** set (legacy contract), not the `time_budget_*` tables.
- **`app/api/agent_data.py`** (modify) — module singletons `_goals_read = require_scope("goals:read")`,
  `_budgets_read = require_scope("budgets:read")`:
  - `GET /goals` (`Depends(_goals_read)`) → `GoalsEnvelope(data=…)`.
  - `GET /time-budgets` (`Depends(_budgets_read)`) → `TimeBudgetsEnvelope(data=…)`.
  - No query params; tenant = the token's `user_id`.

# Files to change

| path | change | why |
|------|--------|-----|
| `app/schemas/agent_api.py` | modify | `AgentGoalRead`, `AgentProjectBudgetRead`, two envelopes |
| `app/services/agent_data.py` | modify | `list_goals`, `list_time_budgets` |
| `app/api/agent_data.py` | modify | the two GET routes + scope singletons |
| `tests/test_agent_goals_budgets_db.py` | add | order, projection, scope, tenant, active-only |

# Implementation slices

1. **Schemas + service.** *Verify:* imports + ruff/mypy.
2. **Router.** *Verify:* `make verify`.
3. **Tests.** *Verify:* full `make verify` green.

# Tests (`tests/test_agent_goals_budgets_db.py`, DB-backed; seeds tokens + goals + projects)

- **goals order:** seed goals with mixed status/title; assert `{ok,data}` ordered by `status` then
  `title`; the item key-set is exactly the agent fields (no `userId`/`createdAt`/`updatedAt`).
- **goals scope/tenant:** a token without `goals:read` → 403; user-A's token never returns user-B's goals.
- **time-budgets active-only + order:** seed two **active** projects with out-of-order names (e.g.
  "Beta" then "Alpha") plus a **non-active** project; assert only the two active ones are returned,
  sorted by `name` (`["Alpha", "Beta"]`), with the exact 9-field projection (no `userId`/audit ts).
- **time-budgets scope/tenant:** a token without `budgets:read` → 403; tenant-isolated.

# Error & rescue map

| failure | error | response |
|---------|-------|----------|
| token lacks `goals:read` / `budgets:read` | `AgentApiError` (from `require_scope`) | 403 `{ok:false,error}` |
| no/expired/unknown token | `AgentApiError` (from `get_agent_principal`) | 401 |

# Risks

- **`/time-budgets` source** — reads `projects` (active), not `time_budget_*`; pinned by the
  active-only + projection tests. Faithful to the legacy agent contract.
- **No query params / no migration / no behavior change** to existing endpoints — additive only.

# Scope check

- [x] Matches the task (goals + active-projects budgets; iCal/webhooks/rate-limit/logs deferred).
- [x] Reviewable in one pass — two tiny service methods + two routes + schemas + tests; reuses B1/B2.
- [x] Size smell: minimal, no new module, no schema change.

# Out of scope

The iCal feed (`/v1/calendar.ics`); webhooks; rate-limiting; `ai_agent_logs`; FastMCP; React UI; ETL.
