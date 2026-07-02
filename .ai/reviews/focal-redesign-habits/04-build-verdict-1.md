# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.6 / 10
Status: BLOCKED

## Reason
Scoped correctly and charts/API mostly match the design, but it regresses core journal behavior: successful journal mutations no longer invalidate/refetch the habits query family, and the create payload default color changed.

## Must Fix
- `HabitJournal.tsx` wires mutations to `onSuccess`, but `HabitsPage.tsx:37` `onMutationSuccess` only clears the error and never invalidates `['habits']` — so `none→yes→no→skip→none` can't work past the first click and archive/reorder/delete leave stale UI.
- `HabitCreateDialog.tsx` changed the default create `color` to `#22c55e`; the base inline form used `#3b82f6`, so a default create is no longer byte-identical.

## Should Consider
- Add assertions that successful journal mutations invalidate/refetch.

## Resolution
Both fixed: `onMutationSuccess` now `void invalidate()`s; `DEFAULT_COLOR` restored to `#3b82f6`; added a test asserting a journal mutation invalidates. (A proactively-found month-bucket overflow was also fixed — see verdict-2 context.) Re-reviewed → verdict-2/-3.

## Release Risk
High
