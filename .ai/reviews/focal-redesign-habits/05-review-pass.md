# Review Verdict

Reviewer: GPT Codex
Step: review
Score: 7.8 / 10
Status: BLOCKED

## Reason
The change is mostly scoped and the chart/date/i18n work is generally sound, but the journal can mutate entries while the entry query is still loading or has failed. That creates a concrete silent data-corruption path: unknown existing statuses are treated as empty cells and a click can overwrite them.

## Must Fix
- `apps/focal/client/src/features/habits/HabitJournal.tsx:238` only gates the skeleton on `habits.isLoading`, while `statusOf` falls back to `"none"` when `entries.data` is unavailable at `HabitJournal.tsx:138`, and the cell buttons remain enabled except for future dates at `HabitJournal.tsx:281`. If `listEntries` is still loading or has failed, clicking a cell calls the mutation path at `HabitJournal.tsx:99` with `current: "none"` and sends `status: "yes"`, which can overwrite an existing `no`/`skip` entry that was not loaded. Disable entry cells or keep the journal in a loading/error-disabled state until entries are known, and cover that path with a test.

## Should Consider
- Surface or deliberately isolate the remaining swallowed query failures: `streaks.isError` falls back to zero at `HabitJournal.tsx:134`, `archived.isError` renders the empty archived state at `HabitJournal.tsx:366`, and `habitsQuery.isError` in charts is not distinguished from no habits at `HabitCharts.tsx:88`.

## Tests Reviewed
Inspected the commit diff, task/plan/design, changed tests, i18n parity, and old-focal references. Attempted focused `pnpm test:run`, but the read-only sandbox blocked pnpm with EPERM.

## Release Risk
High
