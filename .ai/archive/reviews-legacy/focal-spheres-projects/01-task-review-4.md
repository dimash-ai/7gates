# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The task is mostly well scoped and test-oriented, but two acceptance gaps make implementation and verification nondeterministic. The migration handoff is not independently verifiable, and several required typed error cases lack concrete contract expectations.

## Must Fix
- `.ai/tasks/focal-spheres-projects.md:36`-`.ai/tasks/focal-spheres-projects.md:42` and `.ai/tasks/focal-spheres-projects.md:94`-`.ai/tasks/focal-spheres-projects.md:95`: The slice requires removing the model CHECK while committing no migration, but `.ai/tasks/focal-spheres-projects.md:108`-`.ai/tasks/focal-spheres-projects.md:110` requires DB-backed update-preservation tests. Define the exact handoff artifact/state and how verification runs against a schema where `ck_projects_work_time_sphere` has actually been dropped.
- `.ai/tasks/focal-spheres-projects.md:24`-`.ai/tasks/focal-spheres-projects.md:27`, `.ai/tasks/focal-spheres-projects.md:55`-`.ai/tasks/focal-spheres-projects.md:57`, and `.ai/tasks/focal-spheres-projects.md:104`-`.ai/tasks/focal-spheres-projects.md:115`: The typed error contract only pins exact code/details for sphere duplicate/similar errors. Parent missing/non-owned, not-found, validation, and out-of-enum errors require `AppError` but do not specify status, code, message/detail shape, or whether missing vs non-owned responses must be identical.

## Should Consider
- `.ai/tasks/focal-spheres-projects.md:61`: "updates editable fields" does not enumerate the editable fields; list them or point to the exact schema.
- `.ai/tasks/focal-spheres-projects.md:46`-`.ai/tasks/focal-spheres-projects.md:49`: Fuzzy matching depends on legacy `findSimilar`; add normalization/case/whitespace expectations or require tests for them.

## Tests Reviewed
Inspected `.ai/tasks/focal-spheres-projects.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`. No tests run; read-only task-definition review only.

## Release Risk
Medium
