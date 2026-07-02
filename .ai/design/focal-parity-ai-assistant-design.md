# Design: focal-parity-ai-assistant (slice 12 — global AI assistant + voice)

> 3-gate flow (gate A). Consolidates the already-approved 7-gate think (9.3) and plan (9.2) for this
> feature into one self-contained design; those docs (`.ai/think/…`, `.ai/plans/…`) are superseded by
> this for the build/verify gates.

## Problem & decision

The new Focal client has the `/aichat` page but is missing old-focal's **global AI assistant**: a
floating widget reachable from every page, recommended questions, the voice/text **clarify-create**
flow (ask → clarify → create event/task) with spoken read-back, continuous voice mode, and voice
navigation. The `PageToolbar` sparkles button just routes to `/aichat`. Audit graded this a major gap.

**Decision — variant A, client-only.** The backend already exposes every route the assistant needs
(`server/app/api/ai.py` + `ai_chat.py`: `/chat` SSE, `/recommended-questions`, `/question-stats`,
`/conversation`, `/clarify-event`, `/clarify-task`, `/detect-intent`, `/help`); the client
(`api/aichat.ts`) currently wraps only `/chat` (`sendChatMessage`) + `/conversation`
(`clearConversation`). So the slice is: **add thin typed wrappers for the other six routes, then
build the widget + clarification dialog + voice/TTS against existing endpoints** — no backend work.
Voice is the **browser Web Speech API** (focal constraint: no Whisper/TTS infra, no `services/chat`).

**Rejected:** (B) bundling AI assistant-mode data-scoping (threading calendar/owner into the AI read
context) — a backend domain redesign, not frontend-only; the IDOR it would ride on is already fixed
(slice 2b `resolve_ai_data_owner` + write-gate), so it is **deferred to slice 12b**. (C) verbatim
port of the old components — they sit on the legacy stack (`fetchWithAuth`, old contexts); adapt the
behavior onto the new typed `api/aichat.ts` + `apiFetchSse` + shell, preserve behavior not code.

## Assumptions & scope

- **(confirmed)** All 8 AI routes exist server-side; client wraps only `sendChatMessage` +
  `clearConversation` → **6 wrappers to add** (`recommended-questions`, `question-stats`,
  `clarify-event`, `clarify-task`, `detect-intent`, `help`).
- **(confirmed)** `SpeechRecognition` plumbing exists (`features/aichat/VoiceInput.tsx`); only
  `speechSynthesis` (TTS read-back) is net-new — a browser API, no infra.
- **(confirmed)** Reusable primitives exist: `apiFetchSse` (emits `stream_interrupted`),
  `MessageCards` (`EventCardList`/`TaskCardList`), `createEvent`/`createTask` (accept optional
  `calendarId`). old-focal `validateClarifyResult` + `useVoiceNavigation` are pure, portable modules.
- **(confirmed)** Slice 11 (offline/PWA) is live in `superapp-offline` and also mounts in
  `App.tsx`/`AppShell.tsx` and edits `i18n/{en,ru}.json` → **shared-file contention; whoever merges
  second rebases and keeps both global mounts + string blocks.**
- **Out of scope:** any backend change / new endpoint; AI assistant-mode data-scoping (→ 12b);
  Whisper / server TTS / `services/chat`; removing the `/aichat` page; auth/landing.
- **Open questions:** None blocking — the three contract nits the plan review raised are resolved in
  *Architecture & contracts* below.

## Success criteria

- [ ] A floating assistant widget is reachable on every authed page via the toolbar entry, opens with
      the current page as context, shows recommended questions, runs a chat turn over SSE, keeps a
      client-local transcript, and clears server-side conversation state — matching old-focal.
- [ ] Clarify-create (voice or text → `clarify-event`/`clarify-task` → confirm → created) works and
      reads the clarifying question aloud (TTS), degrading silently when `speechSynthesis` is absent.
- [ ] Continuous voice mode + voice navigation work and degrade gracefully when `SpeechRecognition`
      is unavailable/denied; the text path is unaffected; the `/aichat` page still works.
- [ ] `cd superapp-aichat/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run &&
      pnpm build` green; ru + en parity; **no backend change in the diff**.

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| 1 | API wrappers + pure helpers | `api/aichat.ts`(+test), `features/aichat/speech.ts`, `validateClarifyResult.ts`(+test), `useVoiceNavigation.ts`(+test); `VoiceInput.tsx` imports shared speech ctor | wrapper shape drifts from backend | each wrapper hits the exact method/path/query/body; SSE preserves delta/done/error incl. `stream_interrupted`; clarify validation rejects malformed; nav parser deterministic incl. invalid/leap dates |
| 2 | Provider + toolbar + mounted shell | `features/aichat/AIAssistantContext.tsx`, `components/{AppShell,PageToolbar}.tsx`(+tests), `App.tsx`(+test) | provider missing / widget mounts on public routes | toolbar opens widget (not navigate), hidden on `/aichat`; widget mounted only under the auth gate; routing tests still isolate pages |
| 3 | Widget chat parity | `features/aichat/{AIAssistantWidget,aichat,MessageCards,index}.tsx`(+widget test) | SSE interruption / recommended-q failure mid-chat | recommended-q render + client fallback on failure; SSE deltas update msg; `stream_interrupted` keeps partial + warning; clear-failure keeps transcript |
| 4 | Clarify-create dialog + TTS | `features/aichat/AIClarificationDialog.tsx`(+test) | TTS unavailable / clarify rejected / create fails | event+task clarify loops call right wrappers; TTS speaks when available, silent-degrades otherwise; `clarify_rejected` keeps dialog open, no entity; complete → `createEvent`/`createTask(..., currentCalendarId)` |
| 5 | Continuous voice + voice nav | `features/aichat/{VoiceControl}.tsx`(+test), `features/calendar/CalendarPage.tsx`(+focused test) | voice unsupported/denied/offline; restart loop | unsupported/denied/offline show localized notice + text path intact; continuous mode single session + safe restart; nav commands call registered calendar callbacks |
| 6 | i18n + slice-11 reconciliation + final checks | `i18n/locales/{en,ru}.json`; rebase reconcile of `App.tsx`/`AppShell.tsx` | ru/en key gap; lost global mount on rebase | `lint:i18n` clean ru+en; both offline + assistant mounts present post-rebase; full client checks green |

## Architecture & contracts

API access stays in `api/aichat.ts`; global UI state isolated in `features/aichat/AIAssistantContext.tsx`
(`isOpen` + persisted open + current `tabId`/`viewType` + optional calendar voice-nav callback
registration); voice helpers shared in `speech.ts` (no duplicate `SpeechRecognition`); the widget
reuses `MessageCards`, `apiFetchSse`, and `createEvent`/`createTask`. The `/aichat` page is unchanged.

| entity / interface | change | notes |
|--------------------|--------|-------|
| `getRecommendedQuestions({tabId,viewType,limit?})→{questions:string[]}` | add | `GET /api/ai/recommended-questions` (query) |
| `recordQuestionStat({tabId,viewType,question})→void` | add | `POST /api/ai/question-stats`; **discard body** (`{success:true}`), fire-and-forget |
| `sendAssistantChatMessage(body,callbacks,signal?)` | add | `POST /api/ai/chat` via `apiFetchSse`, `stream:true` |
| `sendHelpMessage(body,callbacks,signal?)` | add | `POST /api/ai/help` via `apiFetchSse`; **streamed `done` carries `{type,message,sources}` only — no `answer`** (answer is on the non-streamed JSON path); reuse `ChatStreamCallbacks` reading message/sources |
| `clarifyEvent/clarifyTask(input)→Clarify*Response` | add | `POST /api/ai/clarify-event` / `-task`; responses validated by `validateClarifyResult` before any UI merge |
| `detectIntent({voiceInput})→{intent,confidence,taskScore,eventScore}` | add | `POST /api/ai/detect-intent` |
| `clearConversation({conversationId,resetType?})` | modify | accept scoped id; **keep existing `'ai-chat'` default** so `/aichat` callers are unchanged |
| `AIAssistantContext` | add | provider under `CalendarFilterProvider`/`TimezoneProvider`, inside the auth gate |
| view enums | reconcile | THREE distinct: voice-nav returns `'3days'` (`useVoiceNavigation`), the calendar view enum, and the backend chat `viewType` (free string). Map voice `'3days'`→calendar `'3day'` view and send a normalized `viewType` string to the assistant context; do not conflate them |
| Data model | none | no tables/migrations; transcript is client-local storage; only `DELETE /conversation` is server-side |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — ask | toolbar opens widget, user sends | widget → `sendAssistantChatMessage` (SSE) | streamed answer + structured cards; question-stat logged |
| happy — voice create | mic → detect-intent → clarify loop → confirm | `AIClarificationDialog` | event/task created via `createEvent`/`createTask(...,currentCalendarId)`; queries invalidated |
| `stream_interrupted` | SSE drops before `done` | widget `onError` | partial answer kept + localized "interrupted"; input re-enables |
| `recommended_questions_failed` | query rejects | widget React-Query error path | curated client fallback questions for the tab/view |
| `conversation_clear_failed` | `clearConversation` rejects | widget clear handler | transcript kept + localized notice |
| `voice_unsupported` / `voice_denied` / `voice_offline` | no `SpeechRecognition` / `not-allowed` / `network` | shared voice error mapper | localized notice; continuous mode off; **text path unaffected** |
| `tts_unavailable` / `tts_stalled` | no `speechSynthesis` / no `onend` | TTS helper + watchdog | no banner; question stays visible; (if voice on) re-listen |
| `clarify_rejected` | ApiError or `validateClarifyResult` fail | dialog `processTurn` catch | dialog stays open + retry text; **no entity created** |
| `create_event/task_failed` | create rejects | completion mutation `onError` | localized failure; completed draft kept for retry |

## Test strategy, security & rollback

- **Test strategy:** unit (pure) — wrapper wire-contracts (path/method/query/body + SSE
  delta/done/error/`stream_interrupted`), `validateClarifyResult`, `useVoiceNavigation` (ru/en
  commands, invalid/leap dates); component — widget (toolbar-open, recommended/fallback, SSE
  interrupt, clear-fail), clarify dialog (event/task loops, TTS available/absent, rejected, create),
  `VoiceControl` (unsupported/denied/offline, continuous restart, command/nav handoff), `PageToolbar`
  (opens widget, hidden on `/aichat`), `AppShell`/`App` (mount only under auth gate). "Verified" =
  `lint`+`typecheck`+`test:run`+`build`+`lint:i18n` green.
- **Security:** no new endpoints; **client scoping is not security** — backend RBAC/`resolve_ai_data_owner`
  remain authoritative; this slice must **not** silently add `userId`/owner scoping (that's 12b). No
  secrets; voice/TTS are local browser APIs (mic permission is the browser's).
- **Rollback:** remove the provider + widget mount + toolbar context use; the added API wrappers/pure
  helpers are harmless if unused. No migration. PR base `feature/focal-migration`.
