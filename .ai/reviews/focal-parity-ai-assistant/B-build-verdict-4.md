# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.2 / 10
Status: BLOCKED

(build-slice 3 — widget chat parity, first pass)

## Reason
The core widget chat path is mostly implemented and covered, but the help-page widget path has a concrete runtime crash in the fallback questions flow, blocking the required help-tab behavior.

## Must Fix
- `aichat.ts` includes `help` in `FALLBACK_QUESTION_TABS`, so `fallbackQuestions()` requests `focal.app.assistantWidget.fallbackQuestions.help`, absent from both locales. With `returnObjects:true` a missing key returns the key string, so `recommendedQuestions` becomes a string and `AIAssistantWidget` crashes at `.map()` when opened on `/help` (before recs resolve / on failure). Add the missing help fallback (or route to default) + make `fallbackQuestions` non-array-safe, with a `/help` regression test.

## Should Consider
- Add widget tests for the `/help` send path (`sendHelpMessage`) and per-tab/view local transcript separation.

## Tests Reviewed
Inspected diff, status, `AIAssistantWidget.test.tsx`, `api/aichat.test.ts`. Local green reported (typecheck/lint/test:run=1251), not rerun.

## Release Risk
Medium
