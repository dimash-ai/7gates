# Problem

The new Focal client has a full `/aichat` page but is missing old-focal's **global AI assistant**:
a floating widget reachable from every page (a `PageToolbar` sparkles button currently just routes
to `/aichat`), recommended questions, the voice/text **clarify-create** flow (ask → clarify → create
an event/task) with spoken read-back, continuous voice mode, and voice navigation. This is parity
slice 12. The earlier audit graded the assistant/voice area "major gap": no `AIAssistantWidget`,
no `AIClarificationDialog`, no `VoiceControl`, no TTS.

The de-risking fact, confirmed by inspecting the current tree: **the backend is fully in place; the
remaining work is pure frontend.** `server/app/api/ai.py` + `ai_chat.py` expose every route the old
widget used — `/chat` (SSE), `/recommended-questions`, `/question-stats`, `/conversation`,
`/clarify-event`, `/clarify-task`, `/detect-intent`, `/help`. On the client, `api/aichat.ts`
currently wraps only `/chat` (`sendChatMessage`) and `/conversation` (`clearConversation`); the other
six routes (`/recommended-questions`, `/question-stats`, `/clarify-event`, `/clarify-task`,
`/detect-intent`, `/help`) **still need thin typed wrappers added** — client work, not backend. The
`/aichat` page already runs chat over SSE and does voice **input** via `SpeechRecognition`
(`features/aichat/VoiceInput.tsx`). So slice 12 is client assembly: **add the missing typed
wrappers**, then build the floating widget + clarification dialog + TTS read-back + voice nav against
the existing endpoints — no backend work, no new endpoints, no infra.

One scoping subtlety this think doc settles: slice 2 deferred **AI assistant-mode data-scoping**
(threading the selected calendar/owner into the AI read context) "to the AI slice", after building
and reverting it as a domain-split single-context redesign. The IDOR it would have ridden on is
**already fixed** (slice 2b: `resolve_ai_data_owner` + write-gate). So that data-scoping is a
*separable backend enhancement*, not a prerequisite for the user-facing widget parity.

# Assumptions

- **[confirmed — tree inspection]** All AI routes the widget needs exist on the new backend
  (`app/api/ai.py`/`ai_chat.py`: `/chat`,`/recommended-questions`,`/question-stats`,`/conversation`,
  `/clarify-event`,`/clarify-task`,`/detect-intent`,`/help`). On the client, `api/aichat.ts` wraps
  only `/chat` + `/conversation` so far; the other six routes need thin typed wrappers added (client
  work). → slice 12 needs **no backend change** — but more client wrappers than a one-line claim implied.
- **[confirmed — focal CLAUDE.md migration constraint]** Voice is the **browser Web Speech API**
  (no Whisper/TTS infra, no `services/chat`). `SpeechRecognition` is already used in
  `VoiceInput.tsx`; only `speechSynthesis` (TTS read-back) is net-new, and it is a browser API.
- **[confirmed — tree inspection]** No `AIAssistantWidget` / `AIClarificationDialog` / `VoiceControl`
  exist in the new client yet; the `PageToolbar` sparkles button routes to `/aichat` rather than
  opening a widget.
- **[confirmed — worktree list]** Parallel slices are live: **slice 11 (offline/PWA)** is in
  `superapp-offline` and also mounts globally in `App.tsx`/`AppShell`. → a real (small) shared-file
  contention on the app shell + i18n; whoever merges second rebases. Calendar/gsync/goals/auth
  worktrees don't touch the assistant surfaces.
- **[confirmed — slice 2 notes]** AI assistant-mode data-scoping is deferred and the IDOR is already
  fixed; therefore client widget parity does not depend on it.
- **[unverified — settle at design gate]** Exact old→new component map and how much of
  `VoiceInput.tsx`'s recognition plumbing is reusable vs. extracted into a shared `VoiceControl`;
  whether the widget needs its own `AIAssistantContext` (open state + page context) or can reuse the
  `/aichat` page's chat state. Neither blocks the framing.

# Options considered

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Client-only widget + voice parity (chosen)** | Build the floating `AIAssistantWidget`, `AIClarificationDialog`, TTS read-back, continuous voice + voice nav against the existing endpoints (adding the few missing client wrappers); defer AI data-scoping to 12b. | Frontend-only, independently shippable; no backend risk; matches old-focal user-facing parity; reuses existing SSE + recognition plumbing. | Leaves assistant-mode data-scoping for a follow-up (acceptable — IDOR already fixed; main calendar is the default scope). |
| **B — Bundle AI assistant-mode data-scoping in** | Also redesign the AI read path to thread calendar/owner scope (the slice-2 deferral). | One slice covers widget + scoping. | Not frontend-only — backend domain redesign (single-context split), developer-owned, bigger blast radius; couples a shippable client parity to a riskier backend change. **Rejected** — split as 12b. |
| **C — Transliterate old-focal widget verbatim** | Port the old components 1:1. | Fast first draft. | Old widget is on the legacy stack (`fetchWithAuth`, old contexts); the new client has typed `api/aichat.ts` + `apiFetchSse` + a different shell — verbatim port fights the new patterns. **Rejected** — adapt to the new stack, preserve behavior not code. |

# Recommendation

**Option A — client-only assistant + voice parity, wired to the existing AI endpoints, with
AI assistant-mode data-scoping split out to a separate backend slice 12b.** Rationale: the backend
is fully in place and the client API layer is mostly there (chat + conversation wrapped; six routes
need thin wrappers added), so the entire user-facing gap is client work — building it
frontend-only keeps the slice independently shippable and risk-free, matches old-focal behavior, and
avoids coupling it to the deferred backend data-scoping redesign (which the already-shipped IDOR fix
makes non-urgent). Reuse `apiFetchSse` for chat and the existing `SpeechRecognition` plumbing; add
`speechSynthesis` for read-back. Detailed old→new component mapping is settled at the design gate.

# Out of scope

- **AI assistant-mode data-scoping** (calendar/owner into the AI read context) → separate slice 12b
  (backend, developer-owned). Not required for widget parity; IDOR already fixed in slice 2b.
- **Backend / endpoints** — none added or changed; all required routes already exist.
- **Whisper/TTS infra, `services/chat`** — browser Web Speech API only.
- **Auth/landing** — separate effort/worktree.
- The `/aichat` page is **kept** (old-focal ships both page and widget); this slice does not remove it.

# Open questions

- **Shell-mount coordination with slice 11 (offline):** both mount in `App.tsx`/`AppShell`. Confirm
  the merge order and that the second one rebases — not a blocker, just sequencing.
- **Widget state vs page state:** does the widget get its own `AIAssistantContext` (open + page
  context + transcript) or share the `/aichat` chat hook? Settle at design.
- **`VoiceControl` extraction:** reuse `VoiceInput.tsx` in place or extract a shared
  recognition+synthesis controller used by both the page and the widget? Settle at design.

# Success criteria

- [ ] A floating assistant widget is reachable on every authed page via the toolbar entry, opens
      with the current page as context, shows recommended questions, runs a chat turn over SSE, keeps
      a client-local transcript, and clears server-side conversation state — matching old-focal.
- [ ] The clarify-create flow (voice or text → `clarify-event`/`clarify-task` → confirm → created)
      works and reads the clarifying question aloud (TTS), degrading silently when `speechSynthesis`
      is unavailable.
- [ ] Continuous voice mode and voice navigation work and degrade gracefully when
      `SpeechRecognition` is unavailable or permission-denied; the text path is unaffected.
- [ ] `cd superapp-aichat/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run &&
      pnpm build` green; ru + en parity; no backend change in the diff.
