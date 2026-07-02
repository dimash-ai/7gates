# Review Verdict

Reviewer: Opus
Step: ship
Score: 9.4 / 10
Status: APPROVED

## Reason
Every acceptance criterion is met and verified against the actual source: the panel read is gated on `canViewOtherPages` and the convert on `canCreateTasks` (both confirmed as defence-in-depth over the server's `data_owner_dep(OTHER_PAGES, read/write)` role sets), the create-then-delete partial-failure contract dual-invalidates and keeps the real task, optimistic rollback fires only on create-fail, the wide window is correct against the server's date-window + always-undated query, and the double-fire/delete-during-convert guards all hold — each backed by a focused test. Pure frontend, no migration, no secrets, strict TS, full ru+en i18n.

## Must Fix
None

## Should Consider
- `ru.json` `focal.calendar.taskPanel.active` is a single form (`"{{count}} активных"`); for count=1 Russian would idiomatically read "1 активная". Non-blocking copy nuance — it matches the codebase's existing `{{count}} active`/`активных` pattern and the test only asserts the resolved string, so behavior is correct.
- The convert's `onError`/`onSuccess` partially duplicate `closePopover`'s teardown (the partial-failure branch inlines `setPopover/setDraft/setDirty/setParticipants` instead of reusing a helper, since it must set its own banner). Readability-only; the explicit form is defensible.

## Release Risk
Low

---
Gate A (design) APPROVED 9.1 · Gate B (build) APPROVED 9.2 · Gate C (verify, GPT) APPROVED 9.3 · Release (Opus) APPROVED 9.4.
Rebased onto origin/feature/focal-migration fe3d181 (after #116 aichat + #117 PWA landed); full suite green (1564 tests, 129 files), typecheck 0, lint clean (368 files), build OK.
