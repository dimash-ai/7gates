# Codex Review Verdict

Score: 9.4 / 10
Status: APPROVED

## Reason
The task definition is scoped, internally consistent, and the round-11 `ForeignKey(..., ondelete="SET NULL")` contract is clearly reflected in model scope and acceptance criteria. The retained service-layer owned-link validation and orphaned-read behavior are explicit and measurable.

## Must Fix
None

## Should Consider
- `.ai/tasks/focal-calendar-events.md:332-334` directly tests project deletion and states product/activity use the same rule; consider adding a migration/schema assertion for all three FK `ON DELETE SET NULL` clauses so the new contract is fully verified without relying on review alone.

## Tests Reviewed
Inspected `.ai/tasks/focal-calendar-events.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, `superapp/apps/focal/server/app/models/tasks.py`, and legacy `focal/shared/schema.ts`. No executable tests run; this was a task-definition review.

## Release Risk
Low
