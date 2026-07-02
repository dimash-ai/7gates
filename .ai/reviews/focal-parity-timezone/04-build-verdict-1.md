# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.6 / 10
Status: BLOCKED

## Reason
The foundation is mostly scoped correctly and has useful DST/unit coverage, but the first AI-chat consumer does not actually render selected-display-timezone event cards correctly. There are also concrete display-date and invalid-timezone fallback gaps against the slice acceptance criteria.

## Must Fix
- `apps/focal/server/app/ai/entity_handlers.py:239` returns event card `date`/`startTime`/`endTime` directly from stored event fields, while `apps/focal/client/src/features/aichat/MessageCards.tsx:22` assumes card times already arrive converted to `displayTimezone`; `apps/focal/client/src/features/aichat/AIChatPage.tsx:375` renders cards instead of the converted Markdown. Selected timezone users will see raw event-zone times in AI cards.
- `apps/focal/client/src/features/aichat/AIChatPage.tsx:158` sends `userToday: todayIsoDate()`, and `apps/focal/client/src/features/aichat/aichat.ts:76` computes that date in the browser/system timezone instead of the selected display timezone. The backend uses this as `safe_today` at `apps/focal/server/app/api/ai_chat.py:212`, so "today/tomorrow" AI queries can target the wrong day near timezone boundaries.
- `apps/focal/client/src/hooks/use-timezone.tsx:77` accepts any saved `focal-display-timezone` value without validation, despite the plan/design requiring invalid saved IANA values to fall back to the browser/default zone. That invalid value is then sent to chat at `apps/focal/client/src/features/aichat/AIChatPage.tsx:159` and used for chat-created event timezone stamping at `apps/focal/client/src/features/aichat/AIChatPage.tsx:117`.

## Should Consider
- Add focused tests for an AI event crossing date/time when converted into the selected display timezone, and for invalid saved timezone fallback in `TimezoneProvider`.

## Tests Reviewed
`git -C superapp-timezone --no-pager diff feature/focal-migration`; `git -C superapp-timezone status`; inspected timezone, provider, AIChatPage, and MessageCards tests. Local green checks were reported but not rerun.

## Release Risk
Medium

---
_Resolution (build doer): #1 — the structured AI event cards are converted server-side only for the text summary, not the card array; rather than pull a backend card-builder change into this frontend slice, MessageCards is reverted to baseline (no "already converted" assumption) and AI-card time conversion is deferred to a flagged follow-up slice (backend `entity_handlers` card builder). The slice's AI consumer is narrowed to what the server already converts: the assistant's text answers, "today" resolution, and chat-created-event zone stamping. #2 and #3 fixed in-slice._
