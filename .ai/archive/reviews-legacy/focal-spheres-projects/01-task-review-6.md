# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The task is tightly scoped and has strong acceptance criteria for tenant isolation, typed errors, and work-time behavior. It still contains a concrete legacy-contract mismatch in the sphere fuzzy/normalization requirement, which can make implementation and tests pass while diverging from the cited source.

## Must Fix
- `.ai/tasks/focal-spheres-projects.md:53`-`.ai/tasks/focal-spheres-projects.md:55` says to port legacy `findSimilar` "including its case/whitespace normalization" and test case/whitespace variants, but the cited legacy utility only lowercases during Levenshtein (`focal/server/utils/fuzzy.ts:10`-`focal/server/utils/fuzzy.ts:12`) and does not trim/collapse whitespace; it also filters out same-lowercase values (`focal/server/utils/fuzzy.ts:75`-`focal/server/utils/fuzzy.ts:78`). Clarify the exact intended behavior, or explicitly mark whitespace/case normalization as an intentional contract change.

## Should Consider
- `.ai/tasks/focal-spheres-projects.md:63` and `.ai/tasks/focal-spheres-projects.md:113` bring project CRUD/`/api/projects/:id` into scope, but delete semantics are not pinned. Add expected delete response shape and coverage for deleting a parent with products, especially because `.ai/tasks/focal-spheres-projects.md:37`-`.ai/tasks/focal-spheres-projects.md:39` requires `ON DELETE CASCADE`.
- `.ai/tasks/focal-spheres-projects.md:43`-`.ai/tasks/focal-spheres-projects.md:48` is mostly reproducible now, but it still mixes "agent provides" with "developer-authored" migration ownership. A one-line owner/timing note would prevent plan-stage churn.

## Tests Reviewed
Read `.ai/tasks/focal-spheres-projects.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, relevant legacy routes/storage/fuzzy utility, and contract-freeze route/table inventories. No runtime tests were run; this was a read-only task-definition review.

## Release Risk
Medium
