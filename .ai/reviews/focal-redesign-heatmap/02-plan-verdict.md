# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.2 / 10
Status: APPROVED

## Reason
This is a minimum-viable, surgical re-skin plan that correctly reuses the existing data path (`listEvents`/`getBudgetYear`/`listProjects`/`listSpheres`) and leaves `heatmap.ts` untouched. Every gate-1 Should-Consider is resolved against real source: exact `getHeatmapColor` literals match old-focal `Heatmap.tsx:182-194`; load thresholds are confirmed identical (`heatmap.ts:114-119` ≡ `Heatmap.tsx:167-179`) so no behavior change is needed; the no-budget warning (`Heatmap.tsx:578`/`:705`) is in scope with a named predicate. Failure modes are concrete, slices small and independently reviewable, and each test states what it proves. No Must Fix issue survived source validation.

## Must Fix
None

## Should Consider
- **No-budget warning predicate is partly unreachable under the typed contract.** `TimeBudgetYearRead.settings` is required and non-nullable (`openapi.d.ts:5024`), so a successful `getBudgetYear` response can never omit `settings`. Only reachable warning state is `budget.data === undefined` (query failed/not settled). Keep the predicate as `!budget.data?.settings`; don't write a test fabricating a type-valid success response with no `settings`.
- **`ui/multi-select.tsx` sits outside the heatmap feature folder** while the task scopes the diff to the heatmap feature. Justified (old-focal composes the shared `MultiSelect` at `Heatmap.tsx:33`; the new client has neither `ui/multi-select` nor `ui/command`) and kept generic + dependency-free + independently tested. Acceptable; keep it strictly generic.
- The plan silently (correctly) resolved the think's open i18n/token questions: targets `focal.heatmap.*` (not old-focal's `calendar.heatmap.*`) and literal colors over semantic tokens per the exact-parity task. State the namespace decision explicitly.

## Tests Reviewed
N/A (plan step). Reviewed the proposed test list for specificity — four `multi-select.test.tsx` + seven `HeatmapPage.test.tsx` cases each assert a distinct behavior; confirmed no existing `HeatmapPage.test.tsx` (only `heatmap.test.ts`, correctly held unchanged). Verification commands match the repo's Biome/Vitest tooling.

## Release Risk
Low
