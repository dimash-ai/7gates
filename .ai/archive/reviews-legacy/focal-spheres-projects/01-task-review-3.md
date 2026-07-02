# Codex Review Verdict

Score: 7.4 / 10
Status: BLOCKED

## Reason
The task is mostly scoped and test-oriented, but it has blocking contradictions that would make the acceptance criteria impossible or unfaithful to the cited legacy contract. It also includes a destructive verification command that can discard unrelated work.

## Must Fix
- `.ai/tasks/focal-spheres-projects.md:57` and `.ai/tasks/focal-spheres-projects.md:106` require preserving a non-null `sphere` when `is_work_time=true`, but the baseline it builds on enforces `CheckConstraint("NOT is_work_time OR sphere IS NULL")` in `superapp/apps/focal/server/app/models/projects.py:11` and the migration at `superapp/apps/focal/server/alembic/versions/2026_06_02_1521-25938473715d_focal_baseline.py:161`. The task must say whether to remove/relax that constraint and how to handle migration drift.
- `.ai/tasks/focal-spheres-projects.md:51` says products inherit parent fields, but the cited legacy route lets request values override inherited values at `focal/server/routes.ts:3656` and `focal/server/routes.ts:3659`. Clarify whether body overrides are preserved or forced inheritance is intentional.
- `.ai/tasks/focal-spheres-projects.md:128` instructs `git checkout -- superapp/apps/focal/server/alembic/versions`, which can discard unrelated uncommitted migration work. Replace it with cleanup of only the generated revision file after identifying it.

## Should Consider
- `.ai/tasks/focal-spheres-projects.md:25` and `.ai/tasks/focal-spheres-projects.md:97` do not pin the exact JSON location for `similar_names`; specify whether it is `error.details.similar_names` or another field.
- `.ai/tasks/focal-spheres-projects.md:14` and `.ai/tasks/focal-spheres-projects.md:91` reference `contract-freeze/*.json`, but the files are under `superapp/apps/focal/docs/contract-freeze/`; use exact paths.

## Tests Reviewed
Read `.ai/tasks/focal-spheres-projects.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, cited legacy routes, current project model, baseline migration, and contract-freeze inventories. No tests run; this was a read-only task-definition review.

## Release Risk
High
