# Goal

Bring the new Focal client to **old-focal parity for the global AI assistant + voice** (parity
epic slice 12, **variant A — client-only**): a floating assistant widget reachable from every page,
recommended questions, the voice/text clarify-create flow with spoken read-back, continuous voice
mode, and voice navigation — wired to the Focal AI endpoints that **already exist** on the new
backend. No backend changes.

# Scope

- **Global floating `AIAssistantWidget`** mounted app-wide (inside the auth gate / `AppShell`):
  open/close, persisted open state, and the current page (tab) passed as context.
- **Per-page entry:** the `PageToolbar` sparkles button opens the widget (the standalone `/aichat`
  page stays — old-focal has both).
- **Recommended questions** (`GET /api/ai/recommended-questions`) + **question-stats**
  (`POST /api/ai/question-stats`); chat via the SSE `POST /api/ai/chat`; client-local transcript with
  server-side conversation clear (`DELETE /api/ai/conversation`).
- **`AIClarificationDialog`** — the clarify-event / clarify-task create flow
  (`POST /api/ai/clarify-event`, `/clarify-task`, `/detect-intent`) with **TTS read-back** of the
  clarifying question and graceful re-listen.
- **Voice** (browser Web Speech API only): continuous voice mode + voice navigation;
  `SpeechRecognition` plumbing already exists (`features/aichat/VoiceInput.tsx`), add
  `speechSynthesis` (TTS) read-back.
- ru + en i18n for every new string.

# Out of scope

- **AI assistant-mode data-scoping** (threading `calendarId` / owner into the AI read context) —
  **deferred to a separate backend slice 12b**. It was built then reverted in slice 2 as a
  domain-split single-context redesign; the IDOR is already fixed (slice 2b `resolve_ai_data_owner`
  + write-gate), so this is an enhancement, not required for widget parity.
- **No backend changes / no new endpoints** — every required AI route already exists
  (`server/app/api/ai.py` + `ai_chat.py`). Client work **includes adding thin typed wrappers** in
  `client/src/api/aichat.ts` for the routes not yet wrapped (`/recommended-questions`,
  `/question-stats`, `/clarify-event`, `/clarify-task`, `/detect-intent`, `/help`) — still client-only.
- **No Whisper/TTS infra, no `services/chat`** — browser Web Speech API only (focal migration
  constraint).
- Auth / landing (separate effort, own worktree).

# Acceptance criteria

- [ ] The floating widget is reachable on every authed page via the toolbar entry, opens with the
      current page as context, shows recommended questions, and runs a chat turn over SSE; the
      transcript is client-local (persisted client-side) and the server-side `/conversation` clear works.
- [ ] Clarify-create: voice or text → `clarify-event`/`clarify-task` → confirm → entity created; the
      clarifying question is read aloud (TTS) and degrades silently if `speechSynthesis` is absent.
- [ ] Continuous voice mode and voice navigation work and degrade gracefully when
      `SpeechRecognition` is unavailable or permission-denied (text path unaffected).
- [ ] `cd superapp-aichat/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run &&
      pnpm build` all green; ru + en parity; behaviour matches the old-focal widget.

# Verification commands

```sh
cd superapp-aichat/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```
