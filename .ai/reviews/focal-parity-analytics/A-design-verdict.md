# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.3 / 10
Status: BLOCKED

## Reason
The “no compute changes needed” claim checks out: the mission, spheres, projects, and products modules already expose the budget/plan/fact/percent/deficit/isWork/totals inputs needed for the proposed insights and summaries. The design is otherwise surgical and reuse-first, but two concrete interface/i18n contract errors would likely produce a broken implementation or missing translation fallback.

## Must Fix
- `.ai/design/focal-parity-analytics-design.md:38` points implementers to `features/dashboard/dashboardExport.ts`, but that file does not exist in `superapp-slice9`; `triggerDownload` is actually exported from `superapp-slice9/apps/focal/client/src/features/dashboard/dashboard.ts:198`. Fix the reusable export contract/path before build.
- `.ai/design/focal-parity-analytics-design.md:85` and `.ai/design/focal-parity-analytics-design.md:116` require reusing `common.total`, but the new app locale files do not define a `common` namespace (`rg -n '"common"\\s*:' superapp-slice9/apps/focal/client/src/i18n/locales/{en,ru}.json` returned no matches). The existing total labels are under `translation.focal.budgets.total` at `en.json:337` and `ru.json:341`, so the design must name the real key or add a mirrored analytics key.

## Should Consider
- Make the export/collapse state transition explicit: save the collapse map, force sections expanded, wait for React to commit/paint, run export, then restore in `finally`.
- Clarify Spheres summary coloring: signed `planVsBudget` / `factVsPlan` deltas should use positive/negative coloring; the `>=75` threshold applies to completion percent.

## Tests Reviewed
N/A (design review; no tests run)

## Release Risk
Medium
