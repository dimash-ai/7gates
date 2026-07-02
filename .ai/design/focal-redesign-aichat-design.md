# Design summary

A presentation-only re-skin of `features/aichat` to old-focal `pages/AIChat.tsx`, on the new stack,
with **zero changes to data flow, the API, SSE streaming, the draft/clarify state machine, history,
or voice**. Two decisions everything else hinges on:

1. **Header = a bespoke per-page header matching old-focal exactly** (not the shared `PageHeader`).
   The shared `PageHeader` is a single row at `text-2xl` that always appends `PageToolbar`, so it
   **cannot** reproduce old-focal AIChat's breakpoint-specific header: a desktop variant
   (`hidden md:flex`, title `text-2xl md:text-3xl font-bold`, AIChat.tsx:471-491) and a separate
   mobile variant (`md:hidden`, title `text-lg font-bold truncate`, AIChat.tsx:493-517), each with
   the help tooltip + the red **"Очистить чат"** button. So `AIChatPage` builds the header inline,
   following the **established redesigned-page pattern** verified in the shipped heatmap slice
   (`features/heatmap/HeatmapPage.tsx`): `{sidebar && <SidebarTrigger className="h-8 w-8" />}` via
   `useSidebarOptional`, separate desktop/mobile rows, and `<PageToolbar />` in each row. PageToolbar
   (AI / theme / language) is the **slice-0 shell chrome carried on every redesigned page** (heatmap,
   tags) — it stays for new-app consistency and theme/lang access even though old-focal's aichat
   header predates it; "exact old-focal" binds the header's *title sizing, help, and clear button* and
   the page body. This reverts the earlier "reuse PageHeader as-is" framing per the Gate-3 Must Fix.
2. **Assistant Markdown = `react-markdown` + a scoped `.aichat-prose` style** (the client has neither
   `react-markdown` nor `@tailwindcss/typography` — confirmed), per the approved think doc. User text
   stays `whitespace-pre-wrap` (old-focal only Markdown-renders assistant turns).

Everything else is structural matching: the full-height frame, avatar/bubble shell with the
mobile-only inline avatar+label row, the event/task card states, and the icon-only `Send` + `Mic`
toggle. Traces to `.ai/think/focal-redesign-aichat.md` + `.ai/plans/focal-redesign-aichat-plan.md`.

# Architecture

Touched (all under the worktree `…/.worktrees/focal-redesign-aichat/apps/focal/client/src`):

```
features/aichat/
  AIChatPage.tsx   ← frame + bespoke old-focal header (desktop/mobile rows) + bubbles + ReactMarkdown; state/handlers UNCHANGED
  MessageCards.tsx ← add event past-state + task completed green panel (tune classes only)
  VoiceInput.tsx   ← same speech logic; button → size="icon", Mic/MicOff only, aria-label
  aichat.ts        ← remove parseInline/InlineSegment after ReactMarkdown takes its sole caller
  *.test.tsx/ts    ← update for header/icon controls/markdown; add MessageCards.test.tsx
components/PageToolbar.tsx, ui/sidebar.tsx (SidebarTrigger/useSidebarOptional), ui/tooltip ← REUSED in the bespoke header (no edits); PageHeader NOT used
index.css          ← add scoped .aichat-prose block (no global-token edits)
i18n/locales/{en,ru}.json ← add focal.aichat help + a11y label keys (reuse existing where present)
package.json + pnpm-lock.yaml ← add react-markdown
```

Coupling: the page builds a bespoke header from shell primitives (`useSidebarOptional` +
`SidebarTrigger`, `PageToolbar`, the `Tooltip` set) — the same primitives the shipped heatmap/tags
slices use — and drives the existing aichat data layer (`api/aichat.ts`, `api/events.ts`, `./aichat`
helpers). Ownership of transcript/input/draft state stays entirely in `AIChatPage`; `react-markdown`
is a pure render dependency at the leaf. No new shared component, no shell edit, no context.

# Data model

| entity | change | notes |
|--------|--------|-------|
| — | None | No persistent state, schema, API payload, or generated-type change. localStorage history keying is untouched. |

# Interfaces & contracts

No public/exported contract changes. Internal-only:

- `AIChatPage` (default-style page export) — unchanged props (none); unchanged calls to
  `sendChatMessage`, `clearConversation`, `createEvent`.
- `MessageCards`: `EventCardList({events, singleDate})` / `TaskCardList({tasks, singleDate})` — **same
  signatures**; only internal classNames + a local `isPastEvent(event)` helper added (no new prop, no
  API-type change — `ChatEventInfo` keeps no `timezone`).
- `VoiceInput({onTranscript, onNotice, disabled})` — **same signature**; render-only change.
- `aichat.ts`: **remove** `parseInline` + `InlineSegment` (sole caller `renderSegments` is deleted
  from `AIChatPage`). All other helpers (`loadHistory`, `saveHistory`, `historyKey`,
  `clearHistorySlot`, `draftToEventCreate`, `hasEventCards`, `hasTaskCards`, `todayIsoDate`,
  `welcomeMessage`, `WELCOME_MESSAGE_ID`) unchanged.

# Flow (happy + unhappy paths)

Data flow is **identical to today**; only rendering changes. The unhappy paths are the *existing* ones
(this slice must not regress them):

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — send | Enter / Send icon | `handleSend` → `sendChatMessage` (unchanged) | user bubble + streamed/non-stream assistant bubble; assistant text via ReactMarkdown |
| happy — query reply | classifier returns events/tasks | `MessageCards` | old-focal cards; past events + completed tasks get green panel + `CheckCircle2` + line-through |
| happy — create draft | reply `type==='create' && isComplete` | existing create button → `createEventMutation` | "Создать событие" button → `createEvent`; success appends confirmation |
| send fails | `sendChatMessage` rejects (`ApiError`/unknown) | existing `handleSend` catch | placeholder shows message or `focal.aichat.errorGeneric`; input re-enabled |
| stream interrupted | SSE `onError` `code==='stream_interrupted'` | existing `onError` | partial text + `focal.aichat.interrupted` |
| send aborted | unmount/new request `AbortError` | existing catch | empty placeholder removed |
| clear fails | `clearConversation` rejects | existing `handleClear` catch | `focal.aichat.clearFailed` notice; transcript kept |
| create fails | `createEvent` rejects | existing `onError` | `focal.aichat.eventCreateFailed` notice; button stays |
| voice unsupported/offline/denied | `VoiceInput` guards/`onerror` | existing `VoiceInput` | localized notice via `onNotice` |
| past-state ambiguous | event payload has no timezone | `isPastEvent` (local date+time) | classified by local browser time — surfaced limitation, visual-only (no API-type change) |

# Alternatives rejected

- **Shared `PageHeader`** — rejected (Gate-3 Must Fix): it is a single row at `text-2xl` that always
  appends `PageToolbar`, so it cannot reproduce old-focal AIChat's desktop (`text-2xl md:text-3xl`) +
  separate mobile (`text-lg`) header variants. The bespoke header (matching old-focal sizing/variants,
  built from the same primitives the shipped heatmap/tags slices use) is required for exact parity.
- **Hand-rolled Markdown** (extend `parseInline`) — rejected in the think doc: won't match old-focal
  (lists/links) and is more owned code than adopting `react-markdown` (which old-focal uses).
- **`@tailwindcss/typography` for `prose`** — rejected: adds a second styling dep for one surface;
  a small scoped `.aichat-prose` block matches `prose prose-sm dark:prose-invert` with less footprint.
- **Extend `ChatEventInfo` with `timezone`** to compute past-state like old-focal — rejected: that is
  an API-contract change, out of scope for a re-skin; local-time comparison is acceptable and flagged.

# Test strategy

Vitest + Testing-Library, all in the worktree client (`pnpm test:run`). Levels:

- **Component (page)** `AIChatPage.test.tsx` — prove behavior is preserved through the re-skin: send
  calls `sendChatMessage` once; SSE deltas + sources render; query replies render cards; create-draft
  button calls `createEvent`; clear waits on `clearConversation` (success resets to welcome, failure
  keeps transcript + shows notice); welcome renders; **assistant Markdown** renders semantic
  `strong`/list/link nodes with no literal delimiters while a Markdown-looking **user** message stays
  plain text; icon-only Send/Voice have accessible names.
- **Component (cards)** new `MessageCards.test.tsx` — event/task anatomy (date panel, chips),
  `singleDate` hides the per-card date, **past event** + **completed task** render green/`CheckCircle2`/
  line-through/opacity, priority chips. Fixtures **pin a deterministic local datetime** so past-state
  assertions don't flake on the runner TZ (Gate-2 reviewer note).
- **Unit (helpers)** `aichat.test.ts` — keep history-scoping, corrupt-history fallback, card-detection,
  draft-mapping tests; drop only the `parseInline` tests.
- **Verified before ship** = `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green in the
  worktree, plus a manual light+dark screenshot compare of `/aichat` against old-focal (CSS classes
  can't prove the full visual contract).

# Security & release notes

- No authz/secrets/SSRF/rate-limit surface — frontend re-skin; the JWT-scoped API calls are unchanged.
- New dependency `react-markdown` renders **assistant** text (model output). It does **not** render raw
  HTML by default (no `rehype-raw`), so Markdown stays safe; keep it that way (no `rehype-raw`).
- Rollback = revert the slice's files; no data shape, API, or migration involved. Lockfile updated
  with `react-markdown` so `pnpm install --frozen-lockfile` stays green.
