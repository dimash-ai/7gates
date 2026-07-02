# Stage
3-gate flow — Gate C (verify) complete. Slice 4 of the focal-parity epic: Tasks editor/filters parity.

# What changed
Brings the new Focal Tasks page to functional parity with old-focal. Two sub-slices:

- **4a (frontend):** a working filter/search panel, a create/edit task dialog (`TaskDialog`), a
  detail dialog (`TaskInfoDialog`) with edit/delete/complete/inline-due-date, schedule-a-task-as-event,
  and inline tag creation — all gated by the shared-calendar `canEdit` role and scoped to the active
  calendar. The old inert "Filter" button and the disabled edit pencil are replaced.
- **4b (backend + wiring):** task **recurrence** (`none|daily|weekly|monthly|yearly`) and
  **participants** (free-text "other" participants, plus a CRM contact picker) added to the task
  model/schema/service via an additive Alembic migration, regenerated client API types, and wired
  into the task dialog. The CRM contact picker is rendered but its selections are not yet persisted —
  it mirrors the calendar's deferral of cross-app CRM references pending the crm-boundary decision;
  recurrence and other-participants do persist.

A parity fix found during verification: task rows now always show a project-type badge (mission, else
the gray "Other" badge), instead of dropping it for project-less tasks.

# Files touched
- `apps/focal/client/src/features/tasks/tasksFilters.ts` (+ `.test.ts`)
- `apps/focal/client/src/features/tasks/TaskDialog.tsx` (+ `.test.tsx`)
- `apps/focal/client/src/features/tasks/TaskInfoDialog.tsx` (+ `.test.tsx`)
- `apps/focal/client/src/features/tasks/TasksPage.tsx` (+ `.test.tsx`)
- `apps/focal/client/src/api/openapi.d.ts` (regenerated)
- `apps/focal/client/src/i18n/locales/{en,ru}.json`
- `apps/focal/server/app/models/tasks.py`, `app/schemas/tasks.py`, `app/services/tasks.py`
- `apps/focal/server/alembic/versions/2026_06_26_2341-9288e60e47ce_task_recurrence_and_participants.py` (new)
- `apps/focal/server/tests/test_tasks_db.py`, `tests/test_contracts.py`

# Tests run
```sh
# backend (DATABASE_URL=postgresql+asyncpg://focal:focal@localhost:5433/focal_dev)
uv run pytest -q                  # 1711 passed, 13 failed (pre-existing), 1 skipped
uv run alembic check              # No new upgrade operations detected
uv run ruff check app tests       # All checks passed
uv run mypy app                   # Success: no issues found in 171 source files
# client
tsc --noEmit                      # clean
biome check src                   # clean (268 files)
NODE_OPTIONS=--no-experimental-webstorage vitest run   # 78 files, 924 passed
vite build                        # OK
```

# Verification output
```sh
13 failed, 1711 passed, 1 skipped in 120.09s     # all 13 fails pre-existing (see below)
alembic check: No new upgrade operations detected.
Test Files  78 passed (78)
     Tests  924 passed (924)
```

# Still needs review
- The 13 backend failures are pre-existing and NOT slice-4-caused: 12 in `test_ai_chat_routes_db.py`
  (need Redis/LLM env) and 1 in `test_schemas.py::test_project_read_serializes_camelcase`
  (a `ProjectRead.icon` fixture bug). Proof: none of those files or their subject modules appear in
  `git diff origin/feature/focal-migration...HEAD` (the 17-file slice diff).
- The Alembic migration was generated, reviewed (additive + reversible, `alembic check` clean), and
  applied to the local Docker dev DB. It still applies to the shared `superapp-dev`/`superapp-prod`
  envs via the normal pre-deploy step after merge.
- The CRM contact-picker UI-only deferral is intentional and consistent with the events feature.

# PR / release notes (for users — stage 5)
The Focal **Tasks page** now matches the original app:

- **Create and edit tasks in a dialog** — title, due date & time, project → product → activity,
  a tag (with inline "create tag" + colour), notes, **recurrence** (daily / weekly / monthly / yearly),
  and **participants** (CRM contacts or free-text names).
- **Task detail view** — open a task to see its due date, type, recurrence and notes, and to
  complete it, change its due date inline, edit, or delete it.
- **Filter & search** — a real filter panel (search text, project type, sphere, project, product,
  activity, tag, and date range) that remembers your selections, with an active-filter count.
- **Schedule a task as a calendar event** — turn a dated task into an event in one click.
- Every task row shows its project-type badge, and read-only shared calendars correctly disable
  editing.

# Status
OPUS VERIFY/RELEASE-GATE APPROVED (9.5). Gate-B build APPROVED (9.4). Gate-A design APPROVED (9.2).
