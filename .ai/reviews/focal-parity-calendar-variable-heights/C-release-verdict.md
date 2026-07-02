# Review Verdict

Reviewer: Opus
Step: ship
Score: 9.4 / 10
Status: APPROVED

## Reason
Independently recomputed the variable-height geometry: timeToY/yToMinutes are exact inverses (max round-trip error 0 min across the day at 15-min steps), boundary + clamp values match geometry.test.ts, every former HOUR_HEIGHT site in TimeGrid is routed through the module (HOUR_HEIGHT fully retired), the off-hour min-height floor (12px for a 30-min block) matches lanes.ts's shared MIN_DISPLAY_MINUTES reservation so adjacent off-hour events can't overlap, and the 23:59 backend cap is preserved via formatMinutes. The recomputed drag/resize test numbers (11:00→14:00) faithfully reflect the compression (spot-check yToMinutes(530)=842.5→snap 840=14:00 reproduced exactly). Scope is 6 files all under features/calendar/, no secrets/PII/any, no new user-facing strings.

## Must Fix
None

## Should Consider
- `dates.ts:offsetToMinutes` is now orphaned from production (TimeGrid was its only caller; yToMinutes supersedes it). Leaving pre-existing code is the surgical call, but worth a follow-up cleanup PR.
- `EventBlock` live-resize preview floors height at 8px independent of the minute-space floor — cosmetic-only (the committed value snaps correctly via yToMinutes), not a regression.

## Release Risk
Low

---
Gate A (design) APPROVED 9.3 · Gate B (build) APPROVED 9.2 · Gate C (verify, GPT) APPROVED 9.4 · Release (Opus) APPROVED 9.4.
Rebased onto origin/feature/focal-migration d54f288; full suite green (1610 tests, 132 files), typecheck 0, lint clean (377 files), build OK.
