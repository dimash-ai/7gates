# Review Verdict

Reviewer: Opus
Step: verify
Score: 9.5 / 10
Status: APPROVED

## Reason
The cumulative client-only change meets every acceptance criterion, and all gating checks were independently re-run green (1394 tests, typecheck, biome, build) with the 15 i18next issues proven byte-identical on the base branch. The three concurrency fixes are correct and covered by genuinely adversarial tests (stalled TTS with frozen timers, cross-turn stale-watchdog invalidation, abort-to-settle composer recovery), the backend contract matches all 8 wrappers, and there is zero server code, no secrets, and no `userId`/owner scoping (IDOR deferred to 12b as designed).

## Must Fix
None

## Should Consider
- `AIClarificationDialog.tsx` (isComplete branch) — `createMutation.mutate` runs without a `stopAudio()` immediately before it; symmetric teardown would be marginally cleaner (already neutralized in practice by the `stopAudio()` at `processTurn` top + `onSuccess` + `liveRef` guards). Non-blocking.
- `aichat.ts` `ChatMessage.eventData`/`isComplete` — declared on the transcript type but never read/written by the widget; minor dead surface from the draft model, safe to drop later.
- Build emits the pre-existing >500 kB `index`-chunk warning (present on base); the assistant adds `react-markdown` to the always-loaded shell — a future widget code-split would keep it off the critical bundle.

## Tests Reviewed
Re-ran `pnpm test:run` (111 files / 1394 passed), `pnpm typecheck`, `pnpm lint`, `pnpm build` — all green. Inspected the failure-path tests in `AIClarificationDialog.test.tsx` (TTS-stall watchdog, cross-turn invalidation, voice-off-before-settle, late-post-close no-op, closed-mid-request) and `AIAssistantWidget.test.tsx` (context-switch abort + send-recovery, Markdown XSS). Proved the i18next baseline on a read-only `feature/focal-migration` worktree (15 identical issues, none in slice files). Verified the backend route contract in `apps/focal/server/app/api/ai.py`/`ai_chat.py` against all 8 wrappers.

## Release Risk
Low

---

**Disposition:** APPROVED — release gate cleared. Gate A (design 9.4) · Gate B (build B1–B6 all ≥9.2, + 3 gate-C-found concurrency fixes) · Gate C (GPT verify APPROVED + Opus release gate 9.5). Proceed to Ship: handoff + PR into `feature/focal-migration`. The 3 Should-Considers are recorded as non-blocking follow-ups.
