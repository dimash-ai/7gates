# Codex Review Verdict

Score: 7.8 / 10
Status: BLOCKED

## Reason
The task is unusually detailed and has strong contract-test coverage goals, but it leaves two blocking ambiguities that could make the slice unreproducible or cause unintended destructive behavior. The acceptance criteria are mostly measurable once those are clarified.

## Must Fix
- `.ai/tasks/focal-spheres-projects.md:44-50` conflicts with `.ai/tasks/focal-spheres-projects.md:122-124`: the scope says the agent's deliverable is only the model edit plus exact `drop_constraint` op, while acceptance requires a committed and applied migration. Clarify whether Claude/agent must create and commit the migration file, or whether this task cannot be accepted until a separate developer-owned migration is present.
- `.ai/tasks/focal-spheres-projects.md:39`, `.ai/tasks/focal-spheres-projects.md:64-65`, and `.ai/tasks/focal-spheres-projects.md:134-135`: sphere deletion says to delete projects whose `sphere == sphere.name`, but the required project self-FK cascade can also delete child products whose own `sphere` differs from the deleted sphere. That destructive edge case needs explicit expected behavior and a test.

## Should Consider
- `.ai/tasks/focal-spheres-projects.md:87` and `.ai/tasks/focal-spheres-projects.md:138`: "legacy success shape" is not stated or line-cited. Include the exact response body for project delete.
- `.ai/tasks/focal-spheres-projects.md:154-155`: "no PII in logs" is good, but its verification path is unclear. State whether "no new logging of request/user data" plus grep/code review is sufficient.

## Tests Reviewed
Read `.ai/tasks/focal-spheres-projects.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`. No tests run; this was a task-definition review only.

## Release Risk
Medium
