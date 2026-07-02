# Goal

**Slice 1 of the `focal-redesign-pages` epic.** Bring the new Focal **Tags page**
(`apps/focal/client/src/features/tags/TagsPage.tsx`) to **exact visual + interaction parity with
`apps/old-focal`'s Tags page** (`apps/old-focal/client/src/pages/Tags.tsx`), over the new app's
**existing** tags API. Builds on slice 0's foundation (old-focal tokens), so the restyle reads as
old-focal once it matches old-focal's layout + interactions. Runs in an isolated worktree on branch
`feat/focal-redesign-tags` (based on `feat/focal-redesign-shell`).

> **Binding visual contract** = `apps/old-focal/client/src/pages/Tags.tsx`. **Thing changed** =
> `apps/focal/client/src/features/tags/TagsPage.tsx` (+ its test + new i18n keys). **Behavioural base**
> = the new app's existing `api/tags.ts` (`listTags/createTag/updateTag/deleteTag`) and React Query
> mutations — preserved; this is a re-skin, not a rebuild.

# Scope

Match old-focal's Tags page structure + interactions:

- **Preset color swatches** — replace the new app's native `<input type="color">` with old-focal's
  12-swatch `PRESET_COLORS` grid (`#3b82f6 … #84cc16`), in both add and edit (selected swatch ringed).
- **Inline "Add tag" toggle** — replace the always-visible create form with old-focal's `isAdding`
  toggle: an "Add tag" button in the header reveals an inline create Card (swatches + name input +
  Check/X confirm), collapsing on success/cancel.
- **Search** — client-side filter by tag name (`filteredTags` useMemo over the fetched list), with a
  Search-icon input + clear "X" in the header. No API change (`listTags()` takes no params).
- **Icon-only ghost actions** — row actions become icon-only ghost buttons (`Pencil`/`Trash2`);
  add/edit confirm become `Check`/`X` icon buttons (matching old-focal).
- **Header + count** — title + a count Badge; desktop single-row / mobile two-row responsive layout,
  matching old-focal. The shell's `PageToolbar` (incl. the "ИИ-ассистент" button) supplies the AI
  entry; no per-page AI button is added.
- New user-facing strings via i18next (`ru` + `en`) under `focal.tags.*`.

# Out of scope

- **`isViewingOtherCalendar` gating** — the new app has **no** `CalendarFilterContext`/`currentCalendar`
  concept (0 refs); tags are always the signed-in user's own, so old-focal's "hide edit/add when
  viewing another calendar" branch has no backing data and is **deferred** (not faked). All
  add/edit/delete stay available — equivalent to old-focal viewing your own calendar.
- **Any server / API / schema / behaviour change** — frontend-only; the search is client-side.
- A **per-page AI button** (the shell `PageToolbar` already provides it).
- Restyling other pages (their own slices); the foundation tokens (slice 0, already merged into this
  branch's base).

# Acceptance criteria

- [ ] From the slice's focal client: `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green.
- [ ] The Tags page matches `apps/old-focal`'s Tags page in **light and dark**: preset-swatch grid,
      inline add-toggle, search filter, icon-only actions, header + count — verified by screenshot.
- [ ] Behaviour preserved: create/edit/delete still hit the existing API and invalidate the `['tags']`
      query; the existing `TagsPage.test.tsx` still passes (updated only where markup changed).
- [ ] No hardcoded strings (i18next `ru` + `en`); diff surgical (TagsPage + its test + i18n keys); no
      API change.

# Verification commands

```sh
# from the slice's focal client (worktree)
cd apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```
