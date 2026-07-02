# Problem

The new app's **AI-chat page** (`features/aichat/AIChatPage.tsx`, 398 lines) is functionally complete
on the new stack — it drives the real `api/aichat.ts` SSE stream, the clarify-draft → create-event
flow, per-user localStorage history, and `VoiceInput` — but it wears a **different layout** from the
proven old-focal screen the epic binds to. This slice re-skins it to **exact parity with
`apps/old-focal/client/src/pages/AIChat.tsx`** (the live `focal.allosta.com/ai-chat`), changing
**presentation only**.

Concretely, comparing the two files:

| Aspect | old-focal `AIChat.tsx` (target) | new `AIChatPage.tsx` (current) |
|---|---|---|
| Frame | `flex flex-col h-full overflow-hidden`; a `<header>` (border-b) then a flex-1 region; the `Card` is `h-full flex flex-col` inside `max-w-3xl mx-auto` | `<main class="min-h-screen ...">`; `Card` with a `max-h-[60vh]` scroll region |
| Header | `SidebarToggle` + bold `text-2xl md:text-3xl` title + help tooltip; **desktop one row / mobile two rows**; red-outline **"Очистить чат"** (`Trash2`, `text-red-600 border-red-300`) | title + subtitle `<p>` + a `text-destructive` clear button; no sidebar trigger, no help, single layout |
| Assistant text | `react-markdown` in `prose prose-sm dark:prose-invert` (lists/links/emphasis) | custom `renderSegments`/`parseInline` — **bold + italic only**, no lists/links |
| Cards | event/task cards with a left date/time panel, past/completed green + line-through states, project/product/activity/location chips | already has `EventCardList`/`TaskCardList` (`MessageCards.tsx`) — needs styling tuned to old-focal |
| Input | `Mic`/`MicOff` toggle + `Input` + **icon-only `Send`** | `VoiceInput` + `Input` + a **text "Send"** button |
| Bubbles | avatars; **mobile-only inline avatar + "Вы"/"ИИ‑помощник" label** inside the bubble | avatars + an always-shown top label line |

The behavior layer is already correct and **must not change** — `sendChatMessage` (SSE + non-stream),
`clearConversation`, `createEvent`, the draft/clarify state machine, history persistence, and voice
all stay. This is a pure visual re-skin over working wiring.

# Assumptions

- **[confirmed — user/epic]** Binding visual contract = old-focal `pages/AIChat.tsx`, exact, light +
  dark, reproduced on the new stack (not copied). Source-of-truth + stack rules are settled in
  `.ai/think/focal-redesign-pages.md`.
- **[confirmed — inspection]** The new `features/aichat` is functional over the real API: `AIChatPage`
  calls `sendChatMessage`/`clearConversation` (`api/aichat.ts`), `createEvent` (`api/events.ts`), and
  the `aichat.ts` helpers (`loadHistory`/`saveHistory`, `draftToEventCreate`, `parseInline`,
  `hasEventCards`/`hasTaskCards`); `MessageCards.tsx` + `VoiceInput.tsx` exist. → re-skin, not rebuild.
- **[confirmed — inspection]** old-focal renders assistant Markdown via `react-markdown` in a
  `prose prose-sm dark:prose-invert` container (AIChat.tsx:728-730). The new app deliberately avoids a
  markdown dep (custom `parseInline`, bold/italic only). → reaching old-focal parity for help answers
  (which contain lists/links) is the **one real fork** (Options below).
- **[confirmed — slice 0]** The shell exposes the SidebarTrigger/PageHeader pattern used by the prior
  page slices (tags/heatmap rendered the trigger via `useSidebarOptional` + a bespoke header to keep
  the AI-assistant top-bar button). This slice reuses that, not a new shell.
- **[confirmed — fs]** Worktree `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat`
  (branch `feat/focal-redesign-aichat`) is off slice-0 `afaaeba`, so old-focal's theme tokens are
  already present (no token work here).
- **[unverified — settle at design gate]** whether the new app has `@tailwindcss/typography` (the
  `prose` classes) available, or whether prose styling must be hand-rolled; the exact `MessageCards`
  delta vs old-focal's card markup; whether old-focal's `aiChat.*` strings are already mirrored under
  the new app's i18n keys or need adding (ru + en). None blocks the framing.

# Options considered

The layout/header/input/card work is mechanical matching. The **substantive fork is assistant-text
rendering** — how to reach old-focal's Markdown look:

| # | Option | Pros | Cons |
|---|--------|------|------|
| **A — Add `react-markdown` + a `prose` container (chosen)** | Exact parity with old-focal (lists, links, headings, emphasis in help answers render identically); old-focal already uses it, so the output matches 1:1. | Adds a runtime dep + needs a `prose` style source (the `@tailwindcss/typography` plugin or a small scoped style); slightly more bundle. |
| **B — Extend the existing `parseInline` parser** | No new dep; keeps the lightweight in-house renderer. | Re-implementing Markdown (lists/links/code) by hand is bug-prone and **won't** match old-focal exactly — defeats "exact parity"; more code to own/test than adopting the standard lib. |
| **C — Leave assistant text as bold/italic-only** | Zero work. | Visibly diverges from old-focal on any help answer with a list/link — fails the acceptance bar. Rejected. |

Everything else (full-height frame, two-row mobile header + SidebarTrigger + help + red clear button,
icon Send + Mic toggle, bubble/card styling, mobile inline label) is **direct structural matching**
against `AIChat.tsx`, no fork.

# Recommendation

**Option A — add `react-markdown` and render assistant text in a `prose prose-sm dark:prose-invert`
container**, matching old-focal exactly, plus the structural matching for header/layout/cards/input.
Rationale: the epic's bar is *exact* old-focal parity; help answers routinely contain lists/links that
B/C can't faithfully render, and old-focal itself uses `react-markdown`, so adopting it makes the
output identical with the least owned code. The dep is a standard UI renderer (not on the repo's
forbidden list). At the design gate, confirm the `prose` styling source — prefer `@tailwindcss/typography`
if present, else a small scoped prose stylesheet — and keep user messages as `whitespace-pre-wrap`
(old-focal does not markdown-render the user's own text).

**Plan shape (for gate 2):** one slice, surgical to `features/aichat/*` — (1) page frame + header via
the shell pattern; (2) bubbles + mobile inline label; (3) `MessageCards` styling to old-focal; (4)
assistant Markdown (react-markdown + prose); (5) input bar (Mic toggle + icon Send); (6) i18n ru+en +
`AIChatPage.test.tsx` updates. No API/streaming/logic edits.

# Out of scope

- Any change to `api/aichat.ts`, the SSE stream, `clearConversation`, `createEvent`, the draft/clarify
  state machine, history persistence, or the backend — behavior is preserved.
- Voice **backend** (Web Speech API parity already in `VoiceInput`).
- Route rename (`/aichat` vs old-focal `/ai-chat`) — a slice-0/shell concern.
- Other left-nav pages.

# Open questions

- **`prose` styling source** — is `@tailwindcss/typography` available in the new client, or do we
  hand-roll a scoped prose style to match `prose prose-sm dark:prose-invert`? Settle at the design gate.
- **i18n** — are old-focal's `aiChat.*` strings already mirrored under the new app's `focal.aichat.*`
  keys, or do welcome/clear/labels need adding (ru + en)? Settle at design/build.
- **`MessageCards` delta** — confirm the exact card markup gap vs old-focal (date panel widths,
  past/completed states, chip set) at the design gate; tune rather than rewrite.

# Success criteria

- [ ] AI-chat page matches old-focal `AIChat.tsx` in **light + dark** — full-height frame, two-row
      mobile header with SidebarTrigger + help + red clear button, bubbles + mobile inline label,
      old-focal event/task cards, **Markdown** assistant text, icon `Send` + `Mic` toggle — by
      screenshot.
- [ ] **Behavior unchanged**: SSE + non-stream send, clarify-draft → create-event, clear-chat, voice,
      per-user history; `AIChatPage.test.tsx` updated and green.
- [ ] `cd …/.worktrees/focal-redesign-aichat/apps/focal/client && pnpm lint && pnpm typecheck &&
      pnpm test:run && pnpm build` green; surgical diff to `features/aichat/*`; no API/backend change;
      i18next ru + en.
