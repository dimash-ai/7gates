# Codex Review Verdict

Score: 8.5 / 10
Status: BLOCKED

## Reason
The task is well scoped and test-oriented, but one sphere duplicate/fuzzy rule conflicts with the stated legacy-contract source. That can produce a passing implementation that is observably different from legacy behavior.

## Must Fix
- `.ai/tasks/focal-spheres-projects.md:54`-`.ai/tasks/focal-spheres-projects.md:57`: the task says an exact case-insensitive sphere-name match is the duplicate path, but the binding legacy contract only checks duplicate names case-sensitively (`focal/server/storage.ts:5837`-`focal/server/storage.ts:5842`) and `findSimilar` filters same-lowercase names out of fuzzy matches (`focal/server/utils/fuzzy.ts:75`-`focal/server/utils/fuzzy.ts:78`). Clarify whether rejecting case-only variants is an intentional contract change, or align the task with legacy.

## Should Consider
- `.ai/tasks/focal-spheres-projects.md:69`-`.ai/tasks/focal-spheres-projects.md:72`: spell out exact default values for inherited project fields like `isWorkTime` and `color` instead of relying on "the default."
- `.ai/tasks/focal-spheres-projects.md:80`: clarify whether `/api/projects/:id/products` returns `not_found` or an empty list when the parent project is missing or non-owned.

## Tests Reviewed
Inspected `.ai/tasks/focal-spheres-projects.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and referenced legacy sphere/project/fuzzy source lines. No runtime tests were run; task-definition review only.

## Release Risk
Medium
