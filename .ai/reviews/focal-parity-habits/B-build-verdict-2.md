# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.8 / 10
Status: BLOCKED

## Reason
The prior unloaded-entry note-loss fixes are present and the added regression tests cover those paths, but the implementation still leaves a concrete note/status race between the new note controls and the existing week-cell cycling path. Because the backend overwrites `note` with each upsert payload, a stale cell click can erase a note save that is still in flight.

## Must Fix
- `HabitJournal.tsx`: week cells remain enabled while an entry mutation is pending and still send the cached `entryOf(...).note`. Repro: type a note, click Save note, then click the same day cell before save/refetch completes; the cell upsert sends the old cached note and the backend conflict update overwrites the just-saved note. Add a shared in-flight guard so every entry writer uses the latest note/status.

## Should Consider
- Explicit Yes/No/Skip/Erase and save-note controls do not apply the week cell's future-date guard, so a future week lets users create future habit entries through the panel even though future cells are disabled.

## Tests Reviewed
git diff/status/diff --check against feature/focal-migration; inspected `HabitJournal.test.tsx`, `HabitCreateDialog.test.tsx`, `HabitsPage.test.tsx`, and the Habits design.

## Release Risk
High
