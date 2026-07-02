# Review Verdict

Reviewer: GPT Codex
Step: review
Score: 8.4 / 10
Status: BLOCKED

## Reason
The change is scoped to the AI-chat reskin and largely preserves the existing API/streaming wiring, with reasonable Markdown safety posture by using `react-markdown` without raw HTML plugins. It still mishandles the actual backend card payload shape for optional times, causing visible structured-card regressions that the new tests miss.

## Must Fix
- Normalize empty-string optional times from the AI query payload before card rendering. The backend emits absent `endTime` and `dueTime` as empty strings (`apps/focal/server/app/ai/entity_handlers.py:245`, `:277`), but the new card logic only falls back on nullish values (`apps/focal/client/src/features/aichat/MessageCards.tsx:30`, `:142`, `:150`). This makes same-day events without an end time render as past from midnight onward and renders tasks without a due time blank instead of old-focal's `--:--`; add tests with `endTime: ""` and `dueTime: ""`.

## Should Consider
- Add a focused Markdown safety regression test for raw HTML and `javascript:` links, since assistant/model output is now rendered through a Markdown component.
- Keep the light/dark desktop/mobile screenshot parity check as the Step-7 ship gate, especially for the duplicated header/toolbars and structured-card spacing.

## Tests Reviewed
Inspected `git diff`, `git status`, `AIChatPage.test.tsx`, `aichat.test.ts`, and untracked `MessageCards.test.tsx`; did not rerun the full suite in the read-only review sandbox.

## Release Risk
Medium
