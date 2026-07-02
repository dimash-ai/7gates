# Stage

Stage 7: ship — the `focal-redesign-aichat` slice of the `focal-redesign-pages` epic (exact-old-focal
re-skin of the AI-chat page). Branch `feat/focal-redesign-aichat`, off the shell foundation `afaaeba`.

# What changed

Presentation-only re-skin of `features/aichat` to match old-focal `pages/AIChat.tsx`, over the
**existing** chat API / SSE / draft / history / voice wiring (no behavior or backend change):

- **Full-height layout** — the page is now a `flex flex-col h-full overflow-hidden` frame with a
  bespoke old-focal header (replacing the previous `min-h-screen` card).
- **Bespoke header matching old-focal** — desktop one-row (`text-2xl md:text-3xl` title) / mobile
  compact row (`text-lg`), each with the `SidebarTrigger` (via `useSidebarOptional`), a help tooltip,
  the shared `PageToolbar` (AI / theme / language), and the red **"Очистить чат"** clear button.
- **Message bubbles** — avatar circles, `flex-row-reverse` user turns, and the mobile-only inline
  avatar + "Вы"/"ИИ-помощник" label row.
- **Markdown assistant replies** — assistant text now renders through **`react-markdown`** in a scoped
  `.aichat-prose` style (lists / links / emphasis), matching old-focal; user turns stay plain text.
  Raw HTML and `javascript:` links are not rendered (no `rehype-raw`).
- **Structured event/task cards** (`MessageCards`) — old-focal styling with the left time panel,
  **past-event** and **completed-task** green/`CheckCircle2`/strikethrough states, and priority chips.
- **Icon-only input controls** — `Send` icon button + `Mic`/`MicOff` voice toggle (accessible names).
- Removed the now-orphan in-house `parseInline`/`InlineSegment` (react-markdown replaced its sole use).

A correctness fix found by the holistic review: the AI query payload sends absent `endTime`/`dueTime`
as **empty strings**; the card logic now uses truthy fallbacks (`event.endTime || event.startTime`
with a same-day no-time guard; `task.dueTime || '--:--'`) so an end-time-less event no longer renders
"past from midnight" and a due-time-less task shows `--:--`.

# Files touched

- `apps/focal/client/src/features/aichat/AIChatPage.tsx` — frame, bespoke header, bubbles, markdown, icon Send
- `apps/focal/client/src/features/aichat/MessageCards.tsx` — old-focal card states + empty-string time handling
- `apps/focal/client/src/features/aichat/VoiceInput.tsx` — icon-only Mic/MicOff button + aria labels
- `apps/focal/client/src/features/aichat/aichat.ts` — removed orphan `parseInline`/`InlineSegment`
- `apps/focal/client/src/features/aichat/AIChatPage.test.tsx` — header/markdown/SSE/abort/clear/create/voice/history tests
- `apps/focal/client/src/features/aichat/MessageCards.test.tsx` — **new**; card states incl. empty-string times
- `apps/focal/client/src/features/aichat/aichat.test.ts` — dropped the obsolete inline-parser tests
- `apps/focal/client/src/index.css` — scoped `.aichat-prose` block (no global-token change)
- `apps/focal/client/src/i18n/locales/{en,ru}.json` — added `focal.aichat.help`
- `apps/focal/client/package.json` + `pnpm-lock.yaml` — added `react-markdown@^10.1.0`

# Tests run

```sh
cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

# Verification output

```sh
LINT: PASS        (biome — 218 files, 0 errors)
TYPECHECK: PASS   (tsc -b, 0 errors)
TEST: PASS        Test Files  50 passed (50)
                  Tests      381 passed (381)
BUILD: PASS       (vite build)
```

# Still needs review

- **Visual QA is the remaining human gate** — light/dark, desktop + mobile, `/aichat` against
  old-focal `AIChat.tsx` (header, full-height card, bubbles, markdown, event/task cards incl.
  past/completed states, icon Send + Mic). Not producible in CI; run on a local authed client.
- The `voice.offline` guard (`VoiceInput.tsx`, `!navigator.onLine → notice`) has no test (its notice
  mechanism is covered by the unsupported/denied tests) — a one-case follow-up if desired.
- Pre-existing, out of scope: `PageToolbar` hides the AI-button label below `sm` without an
  `aria-label` (a shell-level mobile-a11y nit, not introduced here).

# PR / release notes (for users — stage 5)

The Focal AI-chat page now matches the production Focal look: a full-height chat card with the
familiar header (sidebar toggle, title, help, and a red "Очистить чат" button), message bubbles with
avatars, and assistant answers rendered with proper formatting (lists, links, emphasis). Calendar/task
answers show the same compact cards as before, now with clear "done"/past styling, and the input bar
uses the compact mic + send icons. Everything works exactly as it did — only the appearance changed.
Available in both Russian and English, light and dark.

# Status

CODEX APPROVED (9.2) — final release gate cleared. Remaining before merge: human visual-parity QA
(light/dark, desktop + mobile) on a local authed client.
