# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.2 / 10
Status: APPROVED

## Reason
The plan's central, highest-risk claim — that the six unwrapped AI routes need thin typed wrappers whose request/response shapes match the backend — is correct against `ai.py`/`ai_chat.py` for all eight wrappers (query vs body, camelCase aliases, return shapes). It is genuinely client-only, reuses existing primitives (`apiFetchSse`'s real `stream_interrupted`, `VoiceInput`'s `SpeechRecognition`, `MessageCards`, `createEvent(..., calendarId)`), names failure modes with concrete catch sites and user-visible results, keeps `/aichat`, and acknowledges the live slice-11 contention.

## Must Fix
None

## Should Consider
- View-enum reconciliation under-pinned: `useVoiceNavigation` returns view `"3days"`; the existing new-client `AIAssistantContext` precedent uses `day|week|month|year|default`; backend chat `viewType` is a free string. Plan writes mapping as `3day -> week` (typo for `3days`) and defers the three-enum mapping to design — call out the exact value + the three enums at the design gate.
- Help SSE `done` frame carries `{type, message, sources}` but not `answer` (only the non-streamed help/JSON path has `answer`); `sendHelpMessage` reuses `ChatStreamCallbacks` (`onDone` typed `ChatResponse`). Works (existing page reads only message/sources), but note `answer` isn't on streamed help.
- `recordQuestionStat` backend returns `{success: true}` (not `{ok}`); `Promise<void>` is correct, just discard the body explicitly like `clearConversation`.

## Tests Reviewed
Inspected (read-only, not executed): `api/aichat.test.ts`, `client.ts` `apiFetchSse` (confirmed `stream_interrupted`), `VoiceInput.tsx` + old `VoiceControl.tsx`/`AIClarificationDialog.tsx`/`validateClarifyResult.ts`, and confirmed `PageToolbar.test.tsx`/`AppShell.test.tsx`/`App.test.tsx`/`CalendarPage.test.tsx` exist.

## Release Risk
Low
