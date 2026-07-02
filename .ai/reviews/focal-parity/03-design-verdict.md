# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.1 / 10
Status: BLOCKED

## Reason
The design is broadly aligned with the epic plan and has the right shared-provider architecture, but two core shared-calendar state contracts are underspecified or incorrect enough to risk implementing non-parity behavior in the foundation slice.

## Must Fix
- `.ai/design/focal-parity-design.md:74-79` defines permissions solely from `currentCalendarRole`, while main calendar is represented as `currentCalendarId: null` / role `null`; old-focal grants main-calendar users full `canEdit`, `canViewOtherPages`, `canManageCalendars`, and current-user `dataOwnerId` in that state. Add the explicit main-calendar override required by `.ai/plans/focal-parity-plan.md:87-92`.
- `.ai/design/focal-parity-design.md:63` says absent `focal_current_calendar_id` means “first entry,” but the approved plan requires first-login auto-select only for `isOnlyParticipant` users. Specify that guard so ordinary users do not auto-select an arbitrary shared calendar instead of main.

## Should Consider
- `.ai/design/focal-parity-design.md:95-99` should mention current recurrence exception fields when deciding whether event custom recurrence really needs a backend handoff, matching `.ai/plans/focal-parity-plan.md:127-132`.

## Tests Reviewed
N/A

## Release Risk
Medium
