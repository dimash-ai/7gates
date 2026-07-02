# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.0 / 10
Status: BLOCKED

(build-slice 6 — i18n sweep + slice-11 reconciliation, first pass)

## Reason
The i18n and offline/PWA coexistence claims hold (`focal.aichat` 44/44 en/ru; fallback arrays present in both locales; the offline badge is inline; assistant SSE sends are not queued). But the viewType carry-over is not closed in production: the new widget test proves the consumer sends a manually-set context value, yet no production code calls `setViewType`, so calendar sessions still send `viewType: 'default'`.

## Must Fix
- `CalendarPage.tsx`: wire `setViewType` from `useAIAssistant()` and sync it from the calendar `view` state — production has no writer for the assistant context `viewType`.
- `AIAssistantWidget.test.tsx`: supplement the synthetic `ViewTypeSetter` coverage with production-path coverage exercising CalendarPage updating the assistant context.

## Should Consider
- Add a `focal.app.assistantWidget.fallbackQuestions.*` en/ru parity guard.

## Tests Reviewed
Inspected `git diff HEAD~1 HEAD`, `AIAssistantWidget.test.tsx`, locale parity via script, assistant widget/API/offline-queue sources, `OfflineIndicator.tsx`, and calendar view wiring.

## Release Risk
Medium

---

**Disposition:** Confirmed against source — `viewType`/`setViewType` exist (B2) and are threaded into sends (B3), but no production writer existed, so the descriptor was always `default`. Verified old-focal parity: `pages/Calendar.tsx` maps `view === "3days" ? "week" : view` in a `useEffect`. Fix wired in `CalendarPage.tsx` (view→descriptor effect, `3day`→`week`, reset to `default` on unmount) + production-path tests in `CalendarPage.test.tsx`. Re-review in `B-build-verdict-11.md`.
