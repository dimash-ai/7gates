# Summary
Implement slice 12 as a client-only parity port: add the missing typed AI client wrappers, then build the global assistant provider/widget, clarification dialog, browser voice control, TTS read-back, and calendar voice navigation against the existing backend. The standalone `/aichat` page stays; `PageToolbar` opens the global widget everywhere except `/aichat`. No backend routes, schemas, migrations, or AI data-scope changes are part of this slice.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/client/src/api/aichat.ts` | Add wrappers/types for `recommended-questions`, `question-stats`, `help`, `clarify-event`, `clarify-task`, `detect-intent`; add a generic widget chat sender; make conversation clear accept a scoped conversation id while preserving `/aichat` defaults. | The backend routes already exist, but the client only wraps `/chat` and `/conversation` today. |
| `superapp/apps/focal/client/src/api/aichat.test.ts` | Extend fetch/SSE tests for every new wrapper and the scoped clear variant. | Proves exact request paths, methods, query/body shape, auth/SSE handling, and no backend assumptions. |
| `superapp/apps/focal/client/src/features/aichat/speech.ts` | Extract the `SpeechRecognition` constructor/minimal typings from `VoiceInput`; add small TTS helper around `speechSynthesis`. | Reuse existing browser SpeechRecognition plumbing and add browser-only TTS without infra. |
| `superapp/apps/focal/client/src/features/aichat/VoiceInput.tsx` | Import the shared speech constructor; keep page behavior unchanged. | Prevents two divergent SpeechRecognition implementations. |
| `superapp/apps/focal/client/src/features/aichat/useVoiceNavigation.ts` | Port/adapt old-focal voice navigation parser for date/view commands. | Required for continuous voice navigation parity. |
| `superapp/apps/focal/client/src/features/aichat/useVoiceNavigation.test.ts` | Port focused parser tests, especially invalid dates/leap-year behavior and view commands. | Proves command parsing is deterministic and date-safe. |
| `superapp/apps/focal/client/src/features/aichat/validateClarifyResult.ts` | Port old-focal clarify response validation. | Prevents a malformed loose `unknown` backend response from hanging/crashing the dialog. |
| `superapp/apps/focal/client/src/features/aichat/validateClarifyResult.test.ts` | Port validation tests for complete/asking/malformed event/task responses. | Proves clarify rejection is caught before UI mutation. |
| `superapp/apps/focal/client/src/features/aichat/AIAssistantContext.tsx` | New provider for `isOpen`, persisted open state, current assistant `viewType`, and optional calendar voice-nav registration. | Matches old provider while fitting the new feature folder. |
| `superapp/apps/focal/client/src/features/aichat/AIAssistantWidget.tsx` | New global widget: tab context, recommended questions, transcript, SSE chat, scoped clear, question stats, and clarify launch. | Restores old-focal global assistant behavior. |
| `superapp/apps/focal/client/src/features/aichat/AIAssistantWidget.test.tsx` | Widget tests for toolbar-opened chat, recommendations/fallback, SSE interruption, clear failure, and scoped payloads. | Proves the global widget works independently from `/aichat`. |
| `superapp/apps/focal/client/src/features/aichat/AIClarificationDialog.tsx` | New voice/text clarify-create dialog using `detectIntent`, `clarifyEvent`, `clarifyTask`, TTS read-back, and existing `createEvent`/`createTask`. | Restores voice/text create flow without backend work. |
| `superapp/apps/focal/client/src/features/aichat/AIClarificationDialog.test.tsx` | Dialog state-machine tests for event/task completion, TTS unavailable, denied mic, rejected clarify response, and close cleanup. | Proves the risky voice/TTS/create paths. |
| `superapp/apps/focal/client/src/features/aichat/VoiceControl.tsx` | New continuous voice UI using shared SpeechRecognition, `useVoiceNavigation`, and clarify handoff. | Restores old-focal continuous voice mode. |
| `superapp/apps/focal/client/src/features/aichat/VoiceControl.test.tsx` | Tests for unsupported/denied/offline voice, continuous restart, command handoff, and navigation callbacks. | Proves text fallback and voice failure modes. |
| `superapp/apps/focal/client/src/features/aichat/aichat.ts` | Add widget transcript keys/helpers and shared draft-to-task/event helpers only where existing helpers do not cover widget needs. | Keeps storage and payload shaping consistent with the current `/aichat` page. |
| `superapp/apps/focal/client/src/features/aichat/MessageCards.tsx` | Reuse/export as needed; no visual rewrite. | Widget should render structured event/task results the same way as `/aichat`. |
| `superapp/apps/focal/client/src/features/aichat/index.ts` | Export the new provider/widget/dialog/voice pieces needed by app shell and tests. | Keeps imports local to the feature boundary. |
| `superapp/apps/focal/client/src/features/calendar/CalendarPage.tsx` | Register current calendar `anchor`/`view` callbacks with `AIAssistantContext`; map voice views (`3day` -> backend `week` for assistant context). | Lets global voice navigation change the visible calendar without refactoring calendar state. |
| `superapp/apps/focal/client/src/components/PageToolbar.tsx` | Replace sparkles navigation with `setIsOpen(true)` from the assistant context; keep button hidden on `/aichat`. | The toolbar entry must open the widget, not route away. |
| `superapp/apps/focal/client/src/components/PageToolbar.test.tsx` | Update the AI button test to assert context open instead of `/aichat` navigation. | Locks the new toolbar behavior. |
| `superapp/apps/focal/client/src/components/AppShell.tsx` | Mount `AIAssistantWidget` inside the authenticated shell, outside the scrollable route content. | Makes the widget global on authed pages. |
| `superapp/apps/focal/client/src/components/AppShell.test.tsx` | Mock/assert the widget mount without disturbing existing sidebar tests. | Prevents shell regressions. |
| `superapp/apps/focal/client/src/App.tsx` | Wrap authenticated `AppShell` with `AIAssistantProvider`. | Provides toolbar/widget state only inside the auth gate. |
| `superapp/apps/focal/client/src/App.test.tsx` | Adjust mocks if needed so routing tests still isolate pages. | Keeps existing router coverage green after provider insertion. |
| `superapp/apps/focal/client/src/i18n/locales/en.json` | Add every new assistant/widget/voice/clarify string. | English parity. |
| `superapp/apps/focal/client/src/i18n/locales/ru.json` | Add matching Russian strings. | Russian parity and existing default-language behavior. |

# Implementation slices

1. **API contracts and safe helpers**
   Add the missing `api/aichat.ts` wrappers with explicit response interfaces because OpenAPI returns several AI responses as `unknown`/loose records:
   - `getRecommendedQuestions({ tabId, viewType, limit? }): Promise<{ questions: string[] }>` -> `GET /api/ai/recommended-questions` with query `{ tabId, viewType, limit }`.
   - `recordQuestionStat({ tabId, viewType, question }): Promise<void>` -> `POST /api/ai/question-stats`.
   - `sendAssistantChatMessage({ message, currentEvent, tabId, viewType, userToday, displayTimezone }, callbacks, signal?)` -> `POST /api/ai/chat` via `apiFetchSse` with `stream: true`.
   - `sendHelpMessage({ message, displayTimezone }, callbacks, signal?)` -> `POST /api/ai/help` via `apiFetchSse` with `stream: true`.
   - `clarifyEvent({ voiceInput, conversationHistory?, currentEvent?, userContext?, userToday? }): Promise<ClarifyEventResponse>` -> `POST /api/ai/clarify-event`.
   - `clarifyTask({ voiceInput, conversationHistory?, currentTask?, userContext?, userToday? }): Promise<ClarifyTaskResponse>` -> `POST /api/ai/clarify-task`.
   - `detectIntent({ voiceInput }): Promise<{ intent: "event" | "task"; confidence: number; taskScore: number; eventScore: number }>` -> `POST /api/ai/detect-intent`.
   - `clearConversation({ conversationId, resetType? } = { conversationId: "ai-chat" }): Promise<void>` -> `DELETE /api/ai/conversation` query params; keep existing callers working.
   Also port `validateClarifyResult`, `useVoiceNavigation`, and extract shared speech helpers. No UI changes in this slice.

2. **Provider, toolbar, and mounted widget shell**
   Add `AIAssistantProvider` under the authenticated `CalendarFilterProvider`/`TimezoneProvider` tree, mount `AIAssistantWidget` in `AppShell`, and change `PageToolbar` to open context state instead of navigating. The widget initially supports open/close, persisted open state, current tab id from `useLocation`, localized tab labels, welcome text, and hides itself on `/aichat`. Calendar registers its current view/date callbacks with the provider; no calendar data/query refactor.

3. **Widget chat parity**
   Fill in the widget body: recommended questions with client fallbacks when the query fails, a widget-local transcript keyed by tab/view, scoped server conversation reset on tab/view changes, `sendAssistantChatMessage`/`sendHelpMessage` streaming, structured event/task cards via existing `MessageCards`, question-stat logging after relevant successful replies, clear conversation with local state preserved if server clear fails, and no `userId` threading beyond existing backend contracts. Use `currentCalendarId` only for existing create/read APIs where the current client already supports it; AI data-owner scoping stays deferred.

4. **Clarify-create dialog and TTS**
   Add `AIClarificationDialog` that accepts text or voice input, calls `detectIntent`, then loops through `clarifyEvent` or `clarifyTask`. It validates every clarify response before merging, speaks each clarifying question with `speechSynthesis`, auto re-listens only when voice mode is on, cancels recognition/TTS/fetch timers on close, and creates through existing `createEvent(..., currentCalendarId)` / `createTask(..., currentCalendarId)`. Query invalidations use existing keys (`events`, `tasks`, `projects`, `activities` where relevant). TTS absence never blocks visual/text flow.

5. **Continuous voice and voice navigation**
   Add `VoiceControl` using the shared SpeechRecognition helper: single-shot command mode, continuous mode with one active recognition session, explicit stop, no-speech retry only in continuous mode, permission/offline/start-failure notices, and command examples. Creation commands hand off to `AIClarificationDialog`; navigation commands use `useVoiceNavigation` and the provider-registered calendar callbacks when the calendar page is active. Outside calendar, creation still works and navigation examples are hidden/disabled.

6. **I18n, contention reconciliation, and final checks**
   Add ru/en strings for all new visible states. Reconcile live slice 11 contention deliberately: `App.tsx`, `AppShell.tsx`, and both locale JSON files are shared with the offline/PWA slice, so whoever merges second must rebase and keep both global mounts/strings. Run the focused tests after each slice and the full client verification at the end.

# Tests

- `api/aichat.test.ts`: proves each new wrapper uses the exact backend method/path/query/body, `apiFetchSse` preserves deltas/done/errors for `/chat` and `/help`, scoped `clearConversation` keeps the old `/aichat` default, and interrupted streams surface `ApiError.code === "stream_interrupted"`.
- `validateClarifyResult.test.ts`: proves malformed clarify responses are rejected before rendering/merging, and valid complete/asking event/task responses pass.
- `useVoiceNavigation.test.ts`: proves ru/en navigation commands map to date/view callbacks, invalid dates return failure, and leap-day behavior is deterministic.
- `VoiceControl.test.tsx`: proves voice unsupported/denied/offline/start-failed states show localized notices, continuous mode restarts safely, manual stop cancels restart, create commands call the handoff, and navigation commands call registered callbacks.
- `AIClarificationDialog.test.tsx`: proves event and task clarify loops call the right wrappers, TTS speaks questions when available, TTS unavailable still displays the question and allows text reply, `clarify_rejected` leaves the dialog open with an error, and completed flows call `createEvent`/`createTask` with `currentCalendarId`.
- `AIAssistantWidget.test.tsx`: proves PageToolbar opens the widget, `/aichat` hides it, recommended questions render/fallback, SSE deltas update the assistant message, `sse_interrupted` preserves partial text with a warning, clear failure preserves transcript, and successful clear resets local/server state.
- `PageToolbar.test.tsx`: updates the former navigation assertion to prove the sparkles button opens context and still hides on `/aichat`; theme/language/timezone controls remain unaffected.
- `AppShell.test.tsx` / `App.test.tsx`: prove the widget is mounted only under authenticated shell/provider and public/legal routes stay outside the assistant provider.
- `CalendarPage.test.tsx` focused additions: prove calendar view changes update assistant context and voice navigation callbacks can set anchor/view without breaking existing keyboard/view tests.
- Final commands:
  - `cd superapp/apps/focal/client && pnpm lint`
  - `cd superapp/apps/focal/client && pnpm typecheck`
  - `cd superapp/apps/focal/client && pnpm test:run`
  - `cd superapp/apps/focal/client && pnpm build`
  - `cd superapp/apps/focal/client && pnpm lint:i18n`

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `voice_unsupported` | No `window.SpeechRecognition` or `window.webkitSpeechRecognition` constructor | `VoiceControl` / `AIClarificationDialog` before starting recognition | Localized "voice input is not supported"; text input stays enabled. |
| `voice_denied` | SpeechRecognition `onerror` with `not-allowed` | Shared voice error mapper in `VoiceControl` / `AIClarificationDialog` | Localized "allow microphone access"; continuous mode turns off; text path unaffected. |
| `voice_no_mic` | SpeechRecognition `onerror` with `audio-capture` | Shared voice error mapper | Localized "microphone not found/unavailable"; text path unaffected. |
| `voice_network_or_offline` | `navigator.onLine === false` before start or SpeechRecognition `network` | Voice start guard / recognition error handler | Localized no-connection voice notice; typed assistant still works. |
| `voice_start_failed` | `recognition.start()` throws or start watchdog fires | Voice start retry/watchdog | Localized start-failed/mic-not-responding notice; recognition ref is cleared. |
| `tts_unavailable` | No `window.speechSynthesis` or no `SpeechSynthesisUtterance` | TTS helper before `speak()` | No error banner; the question remains visible and the user can answer by text or mic. |
| `tts_stalled` | `speechSynthesis` never calls `onend`/`onerror` | TTS watchdog | TTS is cancelled; dialog clears speaking state and, if voice mode remains on, re-listens. |
| `sse_interrupted` | `ApiError(0, "stream_interrupted", ...)` from `apiFetchSse` after partial deltas | Widget stream `onError` callback | Partial assistant answer remains with localized interrupted warning; input re-enables. |
| `ai_admission_rejected` | `ApiError` from `/chat` or `/help` before stream starts, e.g. quota/rate/config | Widget send `catch` | Assistant placeholder becomes the backend message or generic localized error. |
| `recommended_questions_failed` | `ApiError`/network from `getRecommendedQuestions` | React Query error path in widget | Curated client fallback questions for the current tab/view. |
| `question_stat_failed` | `recordQuestionStat` rejects | Fire-and-forget `catch` in widget | Nothing; answer stays visible and recommendations may not reorder. |
| `conversation_clear_failed` | `clearConversation` rejects | Widget clear handler | Transcript is kept; localized clear-failed notice. |
| `clarify_rejected` | `ApiError` from `detectIntent`/`clarifyEvent`/`clarifyTask`, or validation error from `validateClarifyResult` | `AIClarificationDialog.processTurn` catch | Dialog stays open with localized retry/error text; no event/task is created. |
| `clarify_closed_mid_request` | Abort/close while a clarify request or delayed TTS/mic timer is pending | Dialog cleanup effects and open refs | No late state update; dialog closes cleanly. |
| `create_event_failed` | `createEvent` rejects | Clarify completion mutation error handler | Localized create-event failure; completed draft remains available for retry/typing. |
| `create_task_failed` | `createTask` rejects | Clarify completion mutation error handler | Localized create-task failure; completed draft remains available for retry/typing. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** — Minimum viable parity is client assembly over existing backend routes. The plan does not touch server code, OpenAI orchestration, auth, migrations, or AI data-owner scoping. The `/aichat` page remains intact; the widget adds the missing global surface.
- **Architecture** — API access stays in `api/aichat.ts`; global UI state is isolated in `features/aichat/AIAssistantContext.tsx`; voice helpers are shared instead of duplicated; calendar voice navigation registers callbacks without moving calendar state into global context.
- **Design** — Widget uses the existing dialog/card primitives, existing `MessageCards`, localized empty/loading/error states, keyboard-submit input, accessible icon buttons, and hides itself on `/aichat` to avoid two assistant surfaces at once.
- **DevEx** — Wrapper names match backend route names, loose backend responses get explicit client interfaces plus validation, and tests pin the wire contracts. Slice 11 shared-file contention is called out before implementation.

# Risks & migrations

- No database migrations, backend routes, OpenAPI regeneration, env vars, or infra changes.
- Main risk is browser Speech API variability. Rescue is explicit unsupported/denied/offline/start-failed states and text fallback.
- Main merge risk is slice 11 contention on `App.tsx`, `AppShell.tsx`, `en.json`, and `ru.json`. Rollback is removing the provider/widget mount and toolbar context usage while leaving API wrappers/tests harmless.
- AI assistant-mode data-scoping remains deferred to 12b; this slice must not silently add `userId` scoping or backend ownership behavior.

# Scope check

- [x] Matches the task's Scope and Out of scope
- [x] Small enough to review in one sitting if implemented in the slices above
- [x] Size smell addressed: the file count is high because parity spans global mount + widget + voice + tests, but each slice is independently reviewable and client-only

# Out of scope

- Backend changes, new AI routes, OpenAI prompt/orchestration changes, migrations, env/config, or OpenAPI regeneration.
- AI assistant-mode data-scoping (`calendarId` / owner threading into AI read context); this is deferred to 12b and the IDOR is already fixed.
- Whisper, server-side TTS, `services/chat`, or any non-browser voice infrastructure.
- Removing or redesigning the standalone `/aichat` page.
- Auth, landing, dashboard, offline queue/PWA behavior, and slice 11 implementation work beyond merge reconciliation.
