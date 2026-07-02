# Review Verdict

Reviewer: Opus
Step: review
Score: 8.7 / 10
Status: BLOCKED

## Reason
GPT correctly validated that the original nested-radix dismiss bug is real and the fix (`onFocusOutside` preventDefault + the `!pendingOp` `onOpenChange` guard + the new cancel test) is correct and complete — verified green (50 tests pass, tsc exit 0). But GPT's clean "Must Fix: None / Should Consider: None" verdict overlooked a plan-mandated test: plan line 89 requires asserting **create/update** sends `completed`, yet only the create-side mark-done test exists, leaving the new update-side `completed` path (`CalendarPage.tsx:103`) untested — and GPT's Reason affirmatively vouched for "mark-done mapping" matching requirements without catching this.

## Must Fix
- GPT missed a plan-required test for new, untested behavior. The plan (`focal-redesign-calendar-popover-plan.md:89`) mandates mark-done coverage on **both** create and update; the doer added only the create-side test (`CalendarPage.test.tsx:156-170`) and no update-side assertion that toggling done on an existing event sends `completed` in the PATCH (`CalendarPage.tsx` `updatePatch` → `if (dirty.has('completed')) patch.completed = draft.completed`). GPT itself flagged "update-side mark-done" in its BLOCKED pass (`05-review-pass.md`) but dropped it on re-run as if satisfied — it is not.

## Should Consider
- The `['products', draft.projectId]` cache key is shared with `TimeBudgetsPage` using the identical `listProducts(projectId)` queryFn + `Product[]` shape — correct cache reuse, not a collision.
- `op.event.occurrenceDate ?? op.event.date` correctly reads the enriched `occurrenceDate` and improves on the old `event.date`; type-safe.
- Link-clearing on edit does mark dirty (clearing the project calls `onPatch({projectId,productId,activityId: null})` → all three added to the dirty Set → `null` reaches the patch); dirty Set resets on every open; the virtual anchor reads live. No defect.

## Tests Reviewed
Inspected the full slice diff, `EventPopover.tsx`, `RecurringScopeDialog.tsx`, `CalendarPage.tsx`, `CalendarPage.test.tsx`, `EventBlock.tsx`, `api/events.ts`, `openapi.d.ts`. Ran `pnpm exec vitest run src/features/calendar` → 6 files / 50 tests pass; `tsc` exit 0. Cross-checked plan/design test sections against the implemented tests.

## Release Risk
Low
