# Codex Review Verdict

Score: 8.6 / 10
Status: BLOCKED

## Reason
The task is much tighter than prior rounds and covers the main contract, but two documented behaviors still lack verifiable acceptance coverage. Both are likely to slip through implementation despite being explicitly called out as contract behavior.

## Must Fix
- `.ai/tasks/focal-calendar-events.md:156`-`.ai/tasks/focal-calendar-events.md:158` specifies that over-length `status` values must return `validation_error`, but the tests/acceptance only cover null rejection and non-enum round-trip (`.ai/tasks/focal-calendar-events.md:245`-`.ai/tasks/focal-calendar-events.md:254`, `.ai/tasks/focal-calendar-events.md:306`-`.ai/tasks/focal-calendar-events.md:307`). Add an explicit create/patch test or acceptance bullet for `status` length `>20` returning the typed 422 envelope.
- `.ai/tasks/focal-calendar-events.md:79`-`.ai/tasks/focal-calendar-events.md:83` defines the intentional no-FK/stale-link behavior, but the acceptance criteria never require proving that deleted linked project/product/activity rows leave stale ids and enriched reads render orphaned without crashing (`.ai/tasks/focal-calendar-events.md:273`-`.ai/tasks/focal-calendar-events.md:315`). Add an explicit acceptance/test bullet for this deviation.

## Should Consider
- Add an explicit successful `DELETE /api/events/:id` assertion for `204 No Content`; `.ai/tasks/focal-calendar-events.md:184` defines it, but `.ai/tasks/focal-calendar-events.md:280` only says CRUD works.
- Clarify whether “server defaults” in `.ai/tasks/focal-calendar-events.md:42` and `.ai/tasks/focal-calendar-events.md:90` means actual PostgreSQL `server_default` or the existing ORM-side default convention.

## Tests Reviewed
Inspected `.ai/tasks/focal-calendar-events.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and cited legacy/context files. No tests run; this was a task-definition review only.

## Release Risk
Medium
