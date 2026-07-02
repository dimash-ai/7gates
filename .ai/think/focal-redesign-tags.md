# Problem

Slice 1 of the `focal-redesign-pages` epic: make the new Focal **Tags page** match
`apps/old-focal`'s Tags page **exactly** — layout and interactions, not just colours (slice 0 already
gave it old-focal's tokens). The new `TagsPage.tsx` and old-focal's `Tags.tsx` diverge in *structure*,
so this is more than a token re-skin: the new page must adopt old-focal's interaction patterns over
the new app's **existing** tags API (a re-skin of presentation + UI affordances, with behaviour and
data flow preserved).

The concrete gaps (new → old-focal target):
- **Color input**: new uses a native `<input type="color">`; old-focal uses a **12-swatch
  `PRESET_COLORS` grid** (selected swatch ringed) in both add and edit.
- **Create affordance**: new shows an **always-visible** create Card; old-focal uses an **`isAdding`
  toggle** — an "Add tag" header button reveals an inline create Card that collapses on success/cancel.
- **Search**: old-focal filters the list by name (a `filteredTags` useMemo + a Search-icon input with
  a clear "X"); the new page has none.
- **Row actions**: new uses labelled `Edit`/`Delete` buttons; old-focal uses **icon-only ghost**
  buttons (`Pencil`/`Trash2`; `Check`/`X` for confirm).
- **Header**: old-focal has a title + count Badge + search + add, desktop single-row / mobile two-row.

The thing to manage is **what is genuinely backed vs not** (the slice-0 lesson — build what's backed,
don't fake chrome):
- old-focal's Tags page also has an **`isViewingOtherCalendar`** branch (hide add/edit/delete when
  viewing another user's calendar), driven by `CalendarFilterContext`. **The new app has no such
  context** (0 refs to `CalendarFilterContext`/`currentCalendar`/`dataOwnerId`), and `listTags()` takes
  no `calendarId`. So that branch has **no backing data** — reproducing it would be faking a
  capability. It is **out of scope / deferred**; tags are always the signed-in user's own (equivalent
  to old-focal viewing your own calendar, where everything is editable).
- old-focal's header has a per-page **AI button**; the new app's AI entry is the shell `PageToolbar`
  "ИИ-ассистент" button (+ `/aichat`). A per-page AI button would **duplicate** the shell's — so it is
  not added; the shell already covers it.

# Assumptions

- **[confirmed — user/epic]** Binding contract = `apps/old-focal/client/src/pages/Tags.tsx`, exact.
  Slice runs on `feat/focal-redesign-tags` off `feat/focal-redesign-shell` (slice 0 tokens present), in
  an isolated worktree; `.ai/` pipeline stays in the outer repo.
- **[confirmed — fs]** old-focal `Tags.tsx`: `PRESET_COLORS` (12 hex swatches), `searchQuery` +
  `filteredTags` useMemo, `isAdding` inline create Card with the swatch grid + name input + Check/X,
  edit-in-place with the swatch grid, icon-only ghost row actions, a count Badge, desktop/mobile header
  variants, and the `isViewingOtherCalendar` gate.
- **[confirmed — fs]** new `TagsPage.tsx`: native color input, always-visible create form, no search,
  labelled actions, an `errorMessage` banner; wired to `api/tags.ts` (`listTags/createTag/updateTag/
  deleteTag` — typed off the generated OpenAPI `TagRead/TagCreate/TagUpdate`) + React Query with the
  `['tags']` key. `listTags()` has **no** params → search is **client-side**.
- **[confirmed — grep]** new app has **no** calendar-filter / viewing-other-calendar concept (0 refs) →
  `isViewingOtherCalendar` deferred, not faked.
- **[confirmed — grep]** existing `focal.tags.*` i18n keys: `title`, `form.{name,color,submit,
  namePlaceholder}`, `actions.{edit,delete,save,cancel}`, `empty`, `loading`, `errors.*`. New UI
  (search, add-toggle, create-new, count, swatch labels) needs **new** `focal.tags.*` keys (ru + en).
- **[unverified — settle at design gate]** whether to reach old-focal's header via the shared
  `PageHeader` (rightActions = search + add + count; `PageToolbar` brings the AI button) or a bespoke
  header like old-focal's own; whether to keep the new app's `errorMessage` banner (robustness) or drop
  it for literal parity (old-focal shows nothing on error). Both are visual/UX calls for the design.

# Options considered

Fork 1 — **how to restyle**; fork 2 — **the error banner**.

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Rewrite TagsPage body to old-focal's structure over the existing API (chosen)** | Replace the page's JSX/state with old-focal's patterns (swatches, isAdding toggle, search, icon actions, count header) while keeping `api/tags.ts` + the React Query mutations + the `['tags']` key. | Exact old-focal parity; behaviour/data untouched; one-file change + its test + i18n; testable. | The page body is largely rewritten (a big single-file diff) — but it traces 1:1 to old-focal and the API layer is untouched. |
| **B — Minimal token-only restyle** | Leave the structure, only nudge classes. | Smaller diff. | Does **not** reach "exact old-focal" — misses swatches, search, inline-add, icon actions. Rejected (fails the goal). |
| **C — Lift old-focal Tags.tsx wholesale** | Copy old-focal's file in. | Fast literal fidelity. | Drags in `apiRequest`/`fetchWithAuth`/`CalendarFilterContext`/`AIAssistantHeaderButton`/`SidebarToggle` + the calendar-filter data layer the new app doesn't have; breaks the typed `api/tags.ts` contract. Rejected. |

Fork 2 — the error banner: **keep** the new app's `errorMessage` (a robustness improvement that only
renders on failure and doesn't conflict with old-focal's look) rather than drop it for literal parity.
Recommend keep; settle at design.

# Recommendation

**Option A** — rewrite the TagsPage body to old-focal's structure over the **existing** typed API.
Rationale: the goal is exact old-focal interaction parity, which B can't reach and C can't reach
without importing a data layer the new app doesn't have. A keeps the surgical boundary at *presentation
+ UI affordances*: the API module, mutation shapes, and `['tags']` invalidation are untouched, so it's
a re-skin, not a behaviour change. The client-side search and preset swatches are pure UI. Defer the
`isViewingOtherCalendar` gate (no backing concept) and rely on the shell `PageToolbar` for AI.

Plan shape (settled at gate 2): (1) add `focal.tags.*` i18n keys (ru+en) for search/add/create-new/
count; (2) rewrite `TagsPage.tsx` to old-focal's layout + interactions over `api/tags.ts`; (3) update
`TagsPage.test.tsx` for the new markup (swatches, add-toggle, search, icon actions) — preserving the
create/edit/delete + invalidation assertions; (4) `pnpm lint && typecheck && test:run && build` green;
screenshot light+dark vs old-focal.

# Out of scope

- `isViewingOtherCalendar` gating (no `CalendarFilterContext` in the new app — deferred, not faked).
- Any **server / API / schema / behaviour** change; the search is client-side over the existing query.
- A **per-page AI button** (shell `PageToolbar` already provides it).
- Other pages / the foundation tokens (slice 0, already in this branch's base).

# Open questions

- **Header mechanism** — shared `PageHeader` (rightActions: search + add + count; `PageToolbar` → AI)
  vs a bespoke header matching old-focal's own. Settled at the design gate; both reach old-focal's look.
- **Error banner** — keep the new app's `errorMessage` (recommended) or drop for literal parity.
- **Preset palette** — adopt old-focal's exact 12 `PRESET_COLORS` hex values verbatim (yes).
- **Empty-vs-filtered-empty** — match old-focal's single "no tags" message for both the empty list and
  a no-match search (old-focal does); confirm copy at design.

# Success criteria

- [ ] From the slice's focal client: `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green.
- [ ] Tags page matches `apps/old-focal` in **light + dark**: 12-swatch grid, inline add-toggle, search
      filter + clear, icon-only actions, header + count — verified by screenshot.
- [ ] Behaviour preserved: create/edit/delete hit the **existing** API and invalidate `['tags']`;
      `TagsPage.test.tsx` green (updated only for changed markup); **no** API/schema change.
- [ ] Surgical diff (TagsPage + test + i18n keys); i18next `ru`+`en`; nothing faked (the
      viewing-other-calendar gate is deferred with a named missing-context reason).
