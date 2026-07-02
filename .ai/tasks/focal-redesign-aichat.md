# Goal

Re-skin the new Focal app's **AI-chat page** (`superapp/apps/focal/client/src/features/aichat`) to
**exact visual parity with old-focal `pages/AIChat.tsx`**, over the app's **existing** aichat API +
streaming. A slice of the `focal-redesign-pages` epic (binding source = `apps/old-focal`; see
`.ai/think/focal-redesign-pages.md`). **Re-skin only — no behavior/API change.**

> **Binding visual contract** = `superapp/apps/old-focal/client/src/pages/AIChat.tsx` (+ the chat
> message/card styling it inlines; live `focal.allosta.com/ai-chat` is this screen). **Re-skin
> subject** = `features/aichat/{AIChatPage,MessageCards,VoiceInput}.tsx`. **Behavior/data base** =
> the existing `api/aichat.ts` (`sendChatMessage` SSE, `clearConversation`), `api/events.ts`
> `createEvent`, and the `aichat.ts` helpers (history, draft, parsing) — all unchanged.

> **Reproduce, don't copy.** old-focal is React18 + Tailwind3 + `react-markdown`; the new app is
> React19 + Tailwind4 + shadcn. Match the look on the new stack. Built in the worktree
> `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat` (branch
> `feat/focal-redesign-aichat`, off slice-0 shell `afaaeba`).

# Scope

- **Header → old-focal**: SidebarTrigger + page title (bold, `text-2xl md:text-3xl`) + help tooltip;
  **desktop one row / mobile two rows**; a red-outline **"Очистить чат"** button with `Trash2`
  (old-focal's `text-red-600 border-red-300 hover:bg-red-50`), via the shell's PageHeader /
  `useSidebarOptional` pattern established in slice 0 (as tags/heatmap did) so the AI-assistant
  top-bar button is preserved.
- **Full-height layout** — `flex flex-col h-full overflow-hidden`, centered `max-w-3xl mx-auto`, a
  `Card` that fills height (`h-full flex flex-col`) with a `CardHeader` (`Bot` + assistant title) and
  a scrollable message region; replaces the current `min-h-screen` / `max-h-[60vh]` framing.
- **Message bubbles** — user/assistant avatar circles (`bg-primary` / `bg-muted`), bubble colours,
  and the **mobile inline avatar + "Вы" / "ИИ-помощник" label** row.
- **Assistant text** — render to old-focal's `prose prose-sm dark:prose-invert` Markdown look
  (lists/emphasis/links in help answers). Decide react-markdown vs extending the existing inline
  parser at the design gate (see Open questions).
- **Structured event/task cards** — match old-focal's `MessageCards` styling: left date/time panel,
  past/completed (green, line-through) states, project/product/activity/location chips.
- **Input bar** — `Mic`/`MicOff` toggle (existing `VoiceInput`) + `Input` + an **icon-only `Send`**
  button (old-focal), replacing the text "Send" button.
- **i18n** ru + en (reuse old-focal's `aiChat.*` copy via the new app's keys); **light + dark**.

# Out of scope

- **Any change to the aichat API, SSE streaming, draft/clarify logic, history persistence, or the
  backend** — re-skin over the existing wiring; behavior preserved.
- Voice **backend** (browser Web Speech API parity already lives in `VoiceInput`).
- Route changes (the new app serves `/aichat`; old-focal's `/ai-chat` rename is a slice-0/shell
  concern, not this page).
- Other left-nav pages (their own slices).

# Acceptance criteria

- [ ] `cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client && pnpm
      lint && pnpm typecheck && pnpm test:run && pnpm build` all green, with the page's tests updated.
- [ ] The AI-chat page visually matches old-focal `AIChat.tsx` in **light and dark** — header
      (desktop one-row / mobile two-rows), full-height card, bubbles, structured cards, Markdown
      assistant text, icon Send + Mic — verified by screenshot against old-focal.
- [ ] **Behavior preserved**: send (SSE stream + non-stream), clarify-draft create-event button,
      clear-chat, voice input, per-user history — no regressions in `AIChatPage.test.tsx`.
- [ ] No API/streaming/backend change; no hardcoded strings (i18next ru + en); surgical diff tracing
      to this task.

# Verification commands

```sh
cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```
