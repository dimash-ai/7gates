# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.4 / 10
Status: APPROVED

(Approved on the 3rd pass. Pass 1 = 8.7 BLOCKED — priority formula `priorityLevel ?? priority ?? medium` diverged from old-focal's `priorityLevel ?? medium`. Pass 2 = 8.9 BLOCKED — the revision pinned the count-badge to all-status counts (`tasks.length`) where old-focal is incomplete-only. Pass 3 below = APPROVED.)

## Reason
The count-badge is now pinned to old-focal's exact incomplete-only semantics (`Tasks.tsx:988-990`): `totalActive = tasks.filter(t => !t.completed).length`, `filteredActive = filtered.filter(t => !t.completed).length`, `{filteredActive} of {totalActive}` vs `{filteredActive} active`, with an explicit ban on `tasks.length`/all-status counts in the badge and a test that asserts the numbers (`2 of 5`, `5 active`). All three prior fixes survive (priority `priorityLevel ?? 'medium'`; empty-state `tasks.length === 0` matching `Tasks.tsx:1438`; `projectType: string | null` compared directly), and the revision is plan-only with no new divergence or scope creep.

## Must Fix
None.

## Should Consider
- The count-badge test should assert the resolved i18n value (or a regex on the numbers), not the hardcoded English literal `"2 of 5"`, since RU renders `2 из 5`.
- Keep the badge denominator on the raw unfiltered `tasks` query (old-focal compares filtered-incomplete to total-incomplete) — don't let the builder "simplify" `tasks` to `filtered`.

## Tests Reviewed
N/A (plan step). Cross-checked the badge math, empty-state, and priority normalization against `apps/old-focal/.../Tasks.tsx:905-906`, `:987-991`, `:1438`; confirmed the test list asserts badge numbers, orphan/priority filtering, grouping, row affordances, and CRUD payloads.

## Release Risk
Low
