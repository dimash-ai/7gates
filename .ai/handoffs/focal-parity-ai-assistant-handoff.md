# Stage
3-gate flow, Gate C (verify) — SHIP. Feature: `focal-parity-ai-assistant` (parity epic slice 12), branch `feat/focal-parity-ai-assistant` → base `feature/focal-migration`.

# What changed
Brings the global, page-aware **AI assistant** to the new Focal client at parity with old-focal — entirely client-side (no server changes). Built across six slices (B1–B6) plus three verification-driven concurrency hardenings: client API wrappers + pure voice/clarify helpers (B1); assistant provider, toolbar entry, mounted floating widget (B2); widget chat — recommended questions, streaming SSE answers, event/task cards, per-page scoped clear (B3); voice clarify-create dialog with spoken read-back (B4); continuous voice control + calendar voice-navigation + the calendar registering its view/date for voice + view-aware assistant context (B5); i18n sweep, offline coexistence, and `viewType` wiring with tests (B6). Gate C added a TTS-stall watchdog, cross-turn voice read-back invalidation, and in-flight-reply cancellation on page/view change.

# Files touched
Client-only, under `apps/focal/client/src` (29 files, +5465/−81; zero files under `apps/focal/server`):
- `features/aichat/` — `AIAssistantContext.tsx`, `AIAssistantWidget.tsx`, `AIClarificationDialog.tsx`, `VoiceControl.tsx`, `speech.ts`, `useVoiceNavigation.ts`, `validateClarifyResult.ts`, `aichat.ts`, `api`/wrapper additions, + their `*.test.tsx`
- `features/calendar/CalendarPage.tsx` — registers voice-nav callbacks + mirrors the current view into the assistant context
- `App.tsx` / shell — mounts the provider under the auth gate
- `i18n/locales/en.json` + `ru.json` — additive assistant strings (ru/en parity)

# Tests run
```sh
pnpm typecheck   # PASS
pnpm lint        # PASS (335 files)
pnpm test:run    # PASS — 111 files / 1394 tests
pnpm build       # PASS (pre-existing large-chunk warning only)
```

# Verification output
```sh
# GPT Codex (verify, workspace-write) — APPROVED; three concurrency defects found across passes,
# each fixed back at gate B and re-verified, then a clean final pass.
# Opus release gate (fresh context) — APPROVED 9.5 / 10, Release Risk: Low.
# i18next-cli lint: 15 hardcoded-string issues, proven byte-identical on feature/focal-migration
# (unrelated files: integrations/dashboard/analytics/heatmap/landing) — none in slice-12 files.
```

# Still needs review
- AI data-scoping for shared-calendar assistant mode is intentionally **deferred to backend slice 12b** (this slice sends no `userId`/owner scoping; ownership stays JWT-based). The pre-existing `/api/ai/chat` IDOR was closed separately in the data-scope slice.
- Non-blocking polish noted by the release gate: a symmetric `stopAudio()` on the clarify completion path; two unused `ChatMessage` draft fields; a future widget code-split to keep `react-markdown` off the critical bundle.

# PR / release notes (for users)
You now have a built-in AI assistant throughout Focal:
- A floating assistant button on every page (hidden on the full-page AI chat). It suggests questions relevant to the page and view you're on, and keeps a separate conversation per page.
- Ask in plain language and get streaming answers, with your events and tasks shown as cards; clear a page's conversation anytime.
- Create by voice: say something like "meeting with Anna tomorrow at 10" or "add task buy milk" and the assistant confirms the details out loud, asks any follow-ups, and creates the event or task.
- Continuous voice mode, and on the calendar you can navigate by voice — "show next week", "go to Monday", "week view".
- Works without a microphone or speech support (type instead) and degrades gracefully when offline. Russian and English throughout.

(No secrets, tokens, keys, or PII in this text.)

# Status
CODEX VERIFY APPROVED → OPUS RELEASE GATE APPROVED (9.5). Cleared to ship.
