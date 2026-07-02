# Review Verdict

Reviewer: Opus
Step: verify
Score: 9.5 / 10
Status: APPROVED

## Reason
The change is surgical and frontend-only (8 files under apps/focal/client, no schema/migration/server), every design acceptance criterion is met and genuinely covered by tests — including the subtle note-race (entriesReady + isEntryWriting serialization + post-write-refetch lock), calendarId threading, canEdit gating, future guard, delete-reject, and note injection-safety. GPT's verification is honest: its disclosed single-command `fetch failed` is a pnpm-wrapper artifact, and I independently re-ran all four checks green (typecheck/lint/test 80 files·947 tests/build).

## Must Fix
None

## Should Consider
- dnd-kit drag-reorder remains intentionally deferred (chevron reorder is at functional parity) — track it so the parity epic doesn't lose it.
- `categories.*`/`presets.*`/`entryStatus.*` are user-facing client constants whose membership must stay in sync with old-focal's set; no test pins the full list, so a future drift would be silent — low priority.

## Tests Reviewed
- HabitJournal.test.tsx (note-race serialize/refetch-lock, shared-calendar calendarId threading, future guard, read-only no-write, delete-reject keeps dialog open, note injection-safety, day-switch note refiling)
- HabitCreateDialog.test.tsx (create→createHabit, edit→updateHabit, projectId preload, project-fetch RBAC gate both directions)
- HabitsPage.test.tsx (edit-target wiring)
- Independently ran: pnpm typecheck (0), lint (0, 281 files), test:run (80 files / 947 tests), build (0); secret/PII + migration sweep (clean)

## Release Risk
Low
