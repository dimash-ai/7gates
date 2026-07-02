# Review Verdict

Reviewer: GPT Codex
Step: ship
Score: 8.4 / 10
Status: BLOCKED

## Reason
The diff is scoped to the frontend calendar slice, the security/secret scan found no leak, and the PR notes are user-facing. Release is blocked because a required visual verification is explicitly still pending, and one accepted old-focal/design interaction is not implemented.

## Must Fix
- `.ai/tasks/focal-redesign-calendars.md:59` requires light/dark screenshot verification against old-focal before release, but `.ai/handoffs/focal-redesign-calendars-handoff.md:65` says visual QA is still pending.
- `.ai/design/focal-redesign-calendars-design.md:40` specifies a collapsible multi-open card, and old-focal keeps independent section state at `superapp/apps/old-focal/client/src/pages/Calendars.tsx:210` / `:544`; the new card stored only one `openSection` at `apps/focal/client/src/features/calendars/CalendarsPage.tsx:315`, so opening one section closed the others.

## Should Consider
- Add direct coverage or recorded manual verification for the moved rename, delete, and owner participant-remove flows.
- `apps/focal/client/src/features/calendars/GoogleSyncPanel.tsx:39` still allows the Connect button to render during loading/error states.

## Tests Reviewed
Inspected `git diff afaaeba HEAD`, `git status`, `git diff --check`, task/plan/design/handoff, old-focal `Calendars.tsx`, changed source/tests/i18n, commit message, and secret/AI-attribution scan. Reviewed the recorded green typecheck/lint/376 tests/build output in the handoff.

## Release Risk
Medium

---
_Resolution (doer): the accordion is now independent multi-open (`open: {what, participants, google}`), matching old-focal + the design; GoogleSyncPanel loading/error/connected/connect are now exclusive states. Visual QA against old-focal (light+dark) requires an authed session and is the designated user step (per prior slices). Re-scored in 07-ship-verdict-2.md._
