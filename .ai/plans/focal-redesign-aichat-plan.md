# Summary

Reskin the new Focal AI chat page in the `focal-redesign-aichat` worktree to match
`superapp/apps/old-focal/client/src/pages/AIChat.tsx`, while preserving the new app's existing
chat behavior: `sendChatMessage` SSE/non-stream replies, `clearConversation`, `createEvent`,
per-user localStorage history, draft clarification, and `VoiceInput`. The implementation should
replace only presentation: full-height frame, old-focal header, message bubbles, structured cards,
Markdown assistant text, and icon-only input controls.

The markdown decision from the approved think doc is binding: add `react-markdown` and render
assistant text through it. The new Tailwind 4 client does not currently include
`@tailwindcss/typography`, so match old-focal's `prose prose-sm dark:prose-invert` look with a
small scoped `.aichat-prose` style in `src/index.css` rather than adding a second typography
dependency.

# Files to change

| path | change | why |
|------|--------|-----|
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client/src/features/aichat/AIChatPage.tsx` | Replace the current `min-h-screen` layout with the old-focal full-height frame, local AI-chat header, old-focal message bubbles, ReactMarkdown assistant rendering, structured-card placement, create-event button placement, loading bubble, notice placement, and icon-only Send button. Keep all existing API/state handlers intact. | This is the binding page surface and the main visual mismatch. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client/src/features/aichat/MessageCards.tsx` | Tune event/task card classes to old-focal: left date/time panel widths, past/completed green treatment, line-through completed titles, priority colors, context chips, and mobile-safe spacing. Add only local presentation helpers such as `isPastEvent` if needed. | Structured query replies must match the old inline card styling while continuing to consume the current API payloads. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client/src/features/aichat/VoiceInput.tsx` | Keep speech-recognition logic unchanged, but render the control as an old-focal icon-only `Mic`/`MicOff` button with accessible labels. | The input bar must visually match old-focal without regressing voice behavior or tests. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client/src/features/aichat/aichat.ts` | Remove `InlineSegment` and `parseInline` only after ReactMarkdown replaces their sole production caller. Keep history, card-detection, draft mapping, and date helpers unchanged. | Prevent the reskin from leaving an orphan in-house markdown parser behind. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client/src/features/aichat/AIChatPage.test.tsx` | Update page tests for the new header, icon-only controls, Markdown rendering, structured-card placement, and preserved send/clear/create/voice behavior. | Current tests pin the text Send button and inline parser; they must prove parity without losing behavior coverage. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client/src/features/aichat/aichat.test.ts` | Remove inline parser tests when `parseInline` is removed; keep history, card-detection, and draft mapping tests unchanged. | The helper test suite should cover remaining helpers only. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client/src/features/aichat/MessageCards.test.tsx` | Add focused component tests for event/task card visual states: event chips, past event styling, completed task styling, priority chips, and date omission with `singleDate`. | Card parity is significant enough to test outside the full page. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client/src/i18n/locales/en.json` | Add missing `focal.aichat` strings for the help tooltip/accessible labels if not already covered; reuse existing title/assistant/clear/send/voice strings. | No new visible or accessible text should be hardcoded. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client/src/i18n/locales/ru.json` | Add the same `focal.aichat` keys in Russian, matching old-focal copy where it maps cleanly. | RU remains first-class and matches the binding screen. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client/src/index.css` | Add a tightly scoped `.aichat-prose` block for Markdown paragraphs, lists, links, emphasis, and dark-mode colors. Do not change global tokens. | The client lacks typography plugin support, but assistant Markdown must visually match old-focal's prose treatment. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client/package.json` | Add `react-markdown` as a client dependency. | Required by the approved think-doc recommendation for exact Markdown parity. |
| `/Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/pnpm-lock.yaml` | Update the lockfile through pnpm. | Keeps `pnpm install --frozen-lockfile` green after adding `react-markdown`. |

No change is planned for `src/api/aichat.ts`, `src/api/events.ts`, generated OpenAPI types,
backend code, routes, shell components, or shared UI primitives.

# Implementation slices

1. Add markdown/prose/i18n groundwork without changing page behavior.
   - Add `react-markdown` to `apps/focal/client/package.json` and update the root worktree
     `pnpm-lock.yaml` with pnpm.
   - Add scoped `.aichat-prose` CSS in `src/index.css` that covers the old-focal prose surface the
     chat uses: paragraph margins, `ul`/`ol` indentation and spacing, links, `strong`, `em`, and
     dark-mode foreground/link colors. Keep the selectors scoped so other pages are untouched.
   - Add any missing `focal.aichat.help.*` or accessible-label locale keys in EN/RU. Reuse existing
     `focal.aichat.title`, `assistant`, `clearChat`, `send`, `voiceStart`, and `voiceStop` where
     they already match.
   - Build should stay green because the page has not consumed the new dependency or CSS yet.

2. Rebuild the page frame and header over existing state.
   - Keep the current `AIChatPage` state, effects, `handleSend`, `handleClear`, mutation handlers,
     and API imports unchanged.
   - Replace `<main className="min-h-screen ...">` with old-focal's
     `flex h-full flex-col overflow-hidden bg-background text-foreground` page frame.
   - Add a small local header renderer inside `AIChatPage.tsx` rather than editing `PageHeader`.
     It should reuse the shell primitives (`useSidebarOptional`, `SidebarTrigger`, `PageToolbar`,
     and existing tooltip components) so the sidebar trigger and top-bar toolbar stay consistent
     with slice 0, while matching old-focal's AI-chat-specific desktop one-row / mobile two-row
     header.
   - Header contract: title is bold `text-2xl md:text-3xl` on desktop and compact/truncated on
     mobile; help uses the old `aiChat.overview` copy through localized tooltip content; clear chat
     is red outline with `Trash2`, `text-red-600 border-red-300 hover:bg-red-50`, and remains
     disabled during sending/clearing.
   - Replace the body wrapper with old-focal's `flex-1 overflow-hidden px-2 pt-3 pb-3 md:p-6`,
     centered `max-w-3xl mx-auto h-full`, and `Card className="h-full flex flex-col"`.
   - Update tests to assert the title/help/clear controls and card title render, while allowing for
     duplicated desktop/mobile header DOM where necessary by using accessible names plus
     `getAllByRole` or scoped queries.

3. Port message bubbles and assistant Markdown.
   - Remove `renderSegments`, `parseInline`, and `InlineSegment` imports from `AIChatPage.tsx`.
   - Render structured messages exactly where they render now, but put them inside the old-focal
     bubble shell: avatar circles outside on `sm+`, mobile-only inline avatar/name row inside the
     bubble, `flex-row-reverse` for user turns, and `max-w-[calc(100%-6px)] sm:max-w-[80%]`.
   - For assistant text messages, render:
     `ReactMarkdown` inside `className="aichat-prose max-w-none"`; user messages remain plain
     `whitespace-pre-wrap` text.
   - Preserve the existing empty assistant placeholder logic, but style it like old-focal's
     assistant loading bubble with `Loader2` and `aria-live="polite"`.
   - Preserve the create-event button branch and `createEventMutation.mutate(message.eventData ?? {})`.
   - Remove `parseInline` and `InlineSegment` from `aichat.ts`, and remove only the parser tests from
     `aichat.test.ts`.
   - Update/add page tests proving Markdown lists/links/bold render without literal Markdown syntax,
     while the user message still renders as plain text.

4. Tune structured event/task cards to old-focal.
   - Keep `EventCardList` and `TaskCardList` props and API types unchanged.
   - Match old-focal card structure: `bg-background rounded-lg border shadow-sm hover:shadow-md
     transition-shadow flex w-full max-w-full overflow-hidden`, left panel `w-[56px] sm:w-[72px]`,
     and right body `min-w-0 p-3 space-y-1.5`.
   - Event cards: show date only when `!singleDate`, start time as the main text, optional end time
     below a dash, description clamped to two lines, and project/product/activity/location chips
     with the old icons. Add a local `isPastEvent` helper using `event.date` plus `event.endTime ??
     event.startTime` in the user's local timezone; when past, use green panel treatment,
     `CheckCircle2`, opacity, and line-through title. Do not extend the API type for timezone.
   - Task cards: show date only when `!singleDate && task.dueDate`, `task.dueTime ?? '--:--'` in the
     left panel, high-priority red treatment, low-priority blue treatment, completed opacity,
     green completed panel with `CheckCircle2`, and line-through completed title.
   - Add `MessageCards.test.tsx` for these states instead of relying on broad page snapshots.

5. Port the input bar and voice button presentation.
   - Keep `input`, `setInput`, Enter-to-send, disabled guards, and `VoiceInput` callbacks exactly as
     they are.
   - Change `VoiceInput`'s button to `size="icon"` with `aria-label`/`title` using
     `focal.aichat.voiceStart` or `voiceStop`; render only `Mic`/`MicOff` visibly.
   - Change the Send button to old-focal icon-only `Send`, `aria-label={t('focal.aichat.send')}`,
     and no visible text. Keep the existing disabled condition `!input.trim() || isSending ||
     isClearing`.
   - Keep the notice region above the controls so clear/create/voice failures remain visible.
   - Update page tests to click the icon-only Send/Voice buttons by accessible name and prove the
     same API calls/notice behavior as before.

6. Final parity pass and verification.
   - Confirm no behavior code changed beyond render-only wiring and orphan parser cleanup.
   - Run focused tests first:
     `pnpm test:run src/features/aichat/aichat.test.ts src/features/aichat/MessageCards.test.tsx src/features/aichat/AIChatPage.test.tsx`.
   - Then run the required full client checks:
     ```sh
     cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client
     pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
     ```
   - Screenshot-compare `/aichat` in light and dark against
     `superapp/apps/old-focal/client/src/pages/AIChat.tsx`, covering desktop and mobile: header,
     full-height card, scroll region, bubbles, Markdown, event/task cards, create-event button,
     clear-chat notice, icon Send, and Mic/MicOff.

# Tests

- `aichat.test.ts`: history slot scoping remains per user; proves the reskin did not touch
  localStorage ownership.
- `aichat.test.ts`: corrupt history still falls back to the localized welcome message; proves
  storage rescue remains intact.
- `aichat.test.ts`: `hasEventCards` and `hasTaskCards` still detect only query replies with payloads;
  proves structured-message branching did not change.
- `aichat.test.ts`: `draftToEventCreate` still maps complete drafts and legacy fallbacks; proves
  create-event behavior is untouched.
- `MessageCards.test.tsx`: event cards render count-independent card content with date/time panel,
  description, and project/product/activity/location chips; proves old-focal card anatomy.
- `MessageCards.test.tsx`: `singleDate` hides repeated event/task dates; proves the page keeps the
  compact old-focal same-day result layout.
- `MessageCards.test.tsx`: past event fixtures render green/check/line-through/opacity treatment;
  proves the visual past-state requirement.
- `MessageCards.test.tsx`: completed task fixtures render green/check/line-through/opacity treatment;
  proves completed cards match old-focal.
- `MessageCards.test.tsx`: high and low priority task fixtures render distinct priority chips/panel
  treatment; proves task priority parity.
- `AIChatPage.test.tsx`: fresh users see the welcome message rendered through Markdown; proves
  ReactMarkdown is wired without losing the default transcript.
- `AIChatPage.test.tsx`: a general reply with bold text, a list, and a link renders semantic
  `strong`/list/link nodes and no literal Markdown delimiters; proves assistant Markdown parity.
- `AIChatPage.test.tsx`: a user message containing Markdown-looking syntax remains plain text;
  proves only assistant text is Markdown-rendered, matching old-focal.
- `AIChatPage.test.tsx`: sending a typed message still calls `sendChatMessage` once with
  `{ message, currentEvent }`; proves the visual input changes did not alter send behavior.
- `AIChatPage.test.tsx`: streamed help replies append deltas and render sources in Markdown; proves
  SSE callback rendering still works with ReactMarkdown.
- `AIChatPage.test.tsx`: query replies render event/task counts and cards; proves structured payloads
  still bypass text Markdown.
- `AIChatPage.test.tsx`: completed event draft still exposes the create-event button and calls
  `createEvent` with the same mapped fields; proves draft-to-create behavior survived the reskin.
- `AIChatPage.test.tsx`: clear history still waits for `clearConversation`, resets to welcome on
  success, removes local history, and shows the success notice; proves clear behavior is preserved.
- `AIChatPage.test.tsx`: clear history failure keeps the transcript and shows `clearFailed`; proves
  the old red clear button did not introduce a destructive local reset.
- `AIChatPage.test.tsx`: icon-only Voice button reports unsupported speech recognition through the
  existing notice path; proves voice behavior remains testable and accessible after hiding text.
- `AIChatPage.test.tsx`: icon-only Send and Voice controls have accessible names; proves keyboard and
  screen-reader access survives the visual parity change.
- Final command set: `cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-aichat/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `aichat.markdown.dependencyMissing` | Vite/TypeScript cannot resolve `react-markdown` if `package.json` or lockfile is incomplete | `pnpm install --frozen-lockfile`, `pnpm typecheck`, or `pnpm build` before shipping | Nothing shipped; CI/local checks fail. Rescue is to update `package.json` and `pnpm-lock.yaml` together, not to reintroduce the inline parser. |
| `aichat.send.failed` | `sendChatMessage` rejects with `ApiError` or unknown error | Existing `handleSend` `catch` branch in `AIChatPage` | Assistant placeholder becomes the API message or localized `focal.aichat.errorGeneric`; input is re-enabled. |
| `aichat.stream.interrupted` | SSE callback receives `ApiError` with `code === 'stream_interrupted'` | Existing `onError` callback passed to `sendChatMessage` | Partial assistant content remains, followed by localized `focal.aichat.interrupted`. |
| `aichat.send.aborted` | `AbortError` from the in-flight request on unmount/new request | Existing `handleSend` `catch` branch | Empty assistant placeholder is removed; no technical error is persisted. |
| `aichat.clear.failed` | `clearConversation()` rejects | Existing `handleClear` `catch` branch | Localized `focal.aichat.clearFailed` notice; transcript and local history remain. |
| `aichat.createEvent.failed` | `createEvent()` rejects through React Query mutation | Existing `createEventMutation.onError` | Localized `focal.aichat.eventCreateFailed` notice; the create button remains available for retry. |
| `aichat.voice.unsupported` | No SpeechRecognition constructor exists | Existing `VoiceInput.toggle` guard | Localized `focal.aichat.voice.unsupported` notice. |
| `aichat.voice.offline` | `navigator.onLine` is false before recognition starts | Existing `VoiceInput.toggle` guard | Localized `focal.aichat.voice.offline` notice. |
| `aichat.voice.deniedOrMissingMic` | SpeechRecognition `onerror` reports `not-allowed`, `audio-capture`, or `network` | Existing `VoiceInput.onerror` switch | Localized permission, missing microphone, or network notice; listening state resets. |
| `aichat.voice.startFailed` | `recognition.start()` throws twice, including the retry | Existing retry `catch` in `VoiceInput` | Localized `focal.aichat.voice.startFailed` notice; microphone ref is cleared. |
| `aichat.history.storageUnavailable` | `localStorage.getItem`, `setItem`, or `removeItem` throws | Existing catches in `loadHistory`, `saveHistory`, and `clearHistorySlot` | Chat still works in memory; persistence may be lost for that browser/session. |
| `aichat.card.pastDateAmbiguous` | No exception; event payload lacks timezone, so past-state comparison uses local date/time | Local `isPastEvent` helper in `MessageCards.tsx` | Card may be classified by local browser time. Rescue is visual-only: do not extend the API type in this slice; keep the old-focal green/completed styling when local comparison says past. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** — This is the minimum complete reskin for the approved task: one feature page,
  its local card/voice helpers, tests, locale copy, one dependency/lockfile update, and scoped CSS.
  Existing chat API wrappers, event API, history keying, draft state machine, route, shell, and
  backend stay untouched. The only non-presentation cleanup is removing the orphan inline Markdown
  parser after `react-markdown` replaces its sole production use.
- **Architecture** — Data flow remains exactly as it is today: `AIChatPage` owns transcript/input/draft
  state, `sendChatMessage` owns SSE/non-stream transport, `createEvent` owns event creation, and
  `VoiceInput` owns browser speech recognition. New helpers are render-only: local header markup,
  Markdown rendering, scoped prose CSS, and card-state class helpers. Failure paths continue through
  the existing `notice` state or assistant placeholder.
- **Design** — The page explicitly covers old-focal's desktop and mobile header split, full-height
  scrollable card, avatar/bubble layout, mobile inline labels, assistant Markdown, structured
  event/task cards, loading reply, clear/create notices, icon-only Send, and Mic/MicOff. Controls keep
  accessible names even when visible text is removed. Light and dark parity must be verified by
  screenshot because CSS class assertions cannot prove the full visual contract.
- **DevEx** — Do not edit shared shell components to force this one page's header shape. The local
  header should be small and use existing primitives. Tests should assert visible behavior,
  accessible names, and targeted state classes for cards/Markdown, not broad snapshots. The dependency
  addition is justified by exact Markdown parity and is reversible with the page render change.

# Risks & migrations

- No database migration, data backfill, backend/API/schema change, generated OpenAPI change, route
  change, environment variable, or shell migration.
- Package risk: adding `react-markdown` requires a lockfile update and may affect bundle size. It is
  still the simplest faithful path because old-focal uses the same renderer and the approved think
  doc rejected hand-rolled Markdown.
- CSS risk: the new client lacks typography plugin classes, so `.aichat-prose` must be scoped and
  visually checked in light/dark. Rescue is to adjust only the scoped block, not global tokens.
- Header risk: generic `PageHeader` is not shaped like old-focal's AI-chat two-row mobile header.
  Rescue is a local AI-chat header using `useSidebarOptional`, `SidebarTrigger`, `PageToolbar`, and
  tooltip primitives; do not edit shared `PageHeader` or `AppShell` for this slice.
- Test risk: old-focal-style desktop/mobile duplicate header markup can create multiple matching
  clear buttons in component tests. Rescue is to query by role with `getAllByRole` or scope to the
  intended header region; do not collapse the duplicate markup just to simplify tests if it harms
  visual parity.
- Rollback plan: revert the planned files only. No persistent data shape or API behavior is changed.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting if implemented in the ordered slices above.
- [x] Size smell checked: the diff is structural because the binding contract changes the page
      frame, header, bubbles, cards, and input, but it remains contained to the AI-chat feature plus
      required locale, scoped CSS, and package/lockfile updates for Markdown parity.

# Out of scope

- Any change to `src/api/aichat.ts`, the SSE protocol, `/api/ai/chat`, `/api/ai/conversation`,
  backend conversation memory, request payload shape, or generated OpenAPI types.
- Any change to `src/api/events.ts`, event creation semantics, draft clarification rules, or
  `draftToEventCreate` behavior.
- Voice backend or recognition behavior beyond the icon-only button presentation.
- Route rename from `/aichat` to old-focal `/ai-chat`.
- Shared shell redesign, `PageHeader` changes, `AppShell` changes, new global tokens, or unrelated
  page cleanup.
- Other Focal pages or the AI assistant widget outside this page.
