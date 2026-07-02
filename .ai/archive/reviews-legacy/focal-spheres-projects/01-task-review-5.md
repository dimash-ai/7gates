# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly bounded, but its database migration handoff makes the acceptance criteria non-reproducible from committed code. It also leaves a key sphere-rename/project association edge case underspecified despite projects storing sphere by name.

## Must Fix
- `.ai/tasks/focal-spheres-projects.md:43`-`.ai/tasks/focal-spheres-projects.md:48` and `.ai/tasks/focal-spheres-projects.md:104`-`.ai/tasks/focal-spheres-projects.md:106`: the task requires the CHECK constraint to be dropped and DB-backed tests to run against that dropped schema, but also says the agent commits no migration file. A fresh DB upgraded from committed migrations can still retain the constraint, so `make verify` is not independently reproducible.
- `.ai/tasks/focal-spheres-projects.md:134`-`.ai/tasks/focal-spheres-projects.md:143`: the verification commands omit the required `alembic upgrade head` step even though the acceptance criteria depend on the developer-applied constraint drop.

## Should Consider
- `.ai/tasks/focal-spheres-projects.md:55`-`.ai/tasks/focal-spheres-projects.md:58`: clarify what happens when a sphere is renamed while projects still reference the old sphere name, and add an acceptance criterion/test for that behavior.
- `.ai/tasks/focal-spheres-projects.md:28`-`.ai/tasks/focal-spheres-projects.md:31`: clarify whether non-owned sphere/project read/update/delete returns the same `not_found` shape as missing resources, matching the no-existence-leak requirement already specified for `parentProjectId`.

## Tests Reviewed
Inspected `.ai/tasks/focal-spheres-projects.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`. No implementation tests run; task-definition review only.

## Release Risk
Medium
