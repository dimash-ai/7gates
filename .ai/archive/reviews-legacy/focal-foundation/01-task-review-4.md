# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly measurable, but it repeatedly points Claude and verification commands at a non-existent `apps/focal/...` path while the actual project is under `superapp/apps/focal/...`. That makes the scope and success commands build/test-breaking unless the implementer silently corrects the task.

## Must Fix
- `.ai/tasks/focal-foundation.md:18`, `.ai/tasks/focal-foundation.md:23`, `.ai/tasks/focal-foundation.md:80`, `.ai/tasks/focal-foundation.md:118`, `.ai/tasks/focal-foundation.md:120`: paths use `apps/focal/...` / `apps/prima/...`, but `test -d apps/focal` fails and `test -d superapp/apps/focal/server` succeeds. Update task scope and verification commands to the canonical `superapp/apps/...` paths.

## Should Consider
- `.ai/tasks/focal-foundation.md:70`: separate Claude deliverables from developer-only Alembic verification more explicitly so acceptance cannot be read as requiring the agent to generate a baseline migration.
- `.ai/tasks/focal-foundation.md:31`: define the JWKS timeout bound or config name; "bounded path" is directionally clear but not fully measurable.
- `.ai/tasks/focal-foundation.md:33`: specify trailing-slash normalization for `SUPABASE_URL` to avoid silently rejecting valid issuers.

## Tests Reviewed
Inspected `.ai/tasks/focal-foundation.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`. Ran path checks confirming `apps/focal` is absent and `superapp/apps/focal/server` exists. No implementation tests run; task-definition review only.

## Release Risk
Medium
