# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.4 / 10
Status: BLOCKED

## Reason
The slice is mostly scoped correctly and covers the main create/edit, confirm-delete, i18n, and calendar threading paths. It still has concrete note data-loss paths in the journal, which blocks the build gate.

## Must Fix
- `HabitJournal.tsx` cycles week cells via `upsertEntry` without the existing `note`; the backend conflict update overwrites `note`, so cycling a day that has a note silently clears it.
- `noteDraft` is seeded only on expand; date changes do not refresh it, so `saveNote` writes a stale draft to the newly selected date (overwrites/misfiles per-day notes).
- The explicit status/note controls are enabled even when entries are not loaded, so an action can write `note: null`/`status: 'skip'` over an existing-but-unloaded entry.

## Should Consider
- Add dialog coverage for selecting a real `projectId` and the `canViewOtherPages` project-list gate.

## Tests Reviewed
Inspected `HabitJournal.test.tsx` and `HabitsPage.test.tsx`; ran git diff/status/diff --check against feature/focal-migration.

## Release Risk
High
