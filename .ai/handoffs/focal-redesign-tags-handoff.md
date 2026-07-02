# Stage

Step 7 (ship) — slice 1 of the `focal-redesign-pages` epic: the Tags page.
Worktree `/Users/allosta/Desktop/superapp-tags-wt`, branch `feat/focal-redesign-tags`, single commit
`b9dd2ea` (base: slice-0 `feat/focal-redesign-shell` @ `afaaeba`).

# What changed

Restyled the Focal **Tags page** to match `apps/old-focal`'s Tags manager exactly, over the new
app's **existing** tags API (a re-skin — `api/tags.ts`, the React Query mutations, and the `['tags']`
key are untouched):

- **Preset color swatches** — old-focal's 12-swatch `PRESET_COLORS` grid replaces the native color
  picker, in both add and edit (selected swatch ringed).
- **Inline "Add tag" toggle** — an "Add tag" header button reveals an inline create card (swatches +
  name + confirm/cancel), replacing the always-visible form; matches old-focal's open/cancel/reset.
- **Search** — a client-side filter by name (Search-icon input + clear "X"); no API change.
- **Icon-only ghost actions** — `Pencil`/`Trash2` rows; `Check`/`X` confirms.
- **Header** — a single responsive container: one row on desktop, two rows on mobile (title + count,
  then controls), with the shell `PageToolbar` (AI / theme / language) rendered in it and the
  `SidebarTrigger` guarded by `useSidebarOptional` so the page stays renderable standalone.
- New strings localized in `ru` + `en` (`manageTitle`, `searchPlaceholder`, `clearSearch`, `add`,
  `createNew`, `colorOption`); `empty` and the name placeholder re-valued to old-focal's copy.

# Files touched

- `apps/focal/client/src/features/tags/TagsPage.tsx` (rewritten body — old-focal interactions)
- `apps/focal/client/src/features/tags/TagsPage.test.tsx` (updated + strengthened: 15 cases)
- `apps/focal/client/src/i18n/locales/en.json` / `ru.json` (new keys + copy parity)

# Tests run

```sh
cd <worktree>/apps/focal/client
pnpm lint        # biome: 217 files, 0 errors
pnpm typecheck   # tsc -b: 0 errors
pnpm test:run    # 49 files, 368 tests passed
pnpm build       # production bundle built
```

# Verification output

```sh
$ pnpm test:run
 Test Files  49 passed (49)
      Tests  368 passed (368)
```

# Still needs review

- **Manual visual QA is the one remaining pre-merge gate — NOT yet performed.** The code targets
  old-focal's layout/interactions, but pixel parity is **unverified by screenshot**. Before merge,
  compare vs old-focal in light AND dark, desktop + mobile: the swatch grid, the inline add-toggle,
  search + clear, icon-only actions, the count, and the desktop-one-row / mobile-two-row header (the
  mobile two-row split is the thing to eyeball; on desktop the count sits next to the title rather
  than far-right — a deliberate single-container trade-off).
- Frontend-only re-skin: no server / API / schema / behaviour change; `api/tags.ts` + `['tags']`
  untouched. The `isViewingOtherCalendar` gate is **deferred** (no `CalendarFilterContext` in the new
  app — not faked).
- Minor (non-blocking): delete has no failure-path test (its `onError` reuses the shared handler that
  create/update failure tests already cover).

# PR / release notes (for users)

**Managing tags now works the way it does in the established Focal app.** Pick from a palette of
preset colors, add a tag inline, search to filter your tags, and edit or delete with compact icon
buttons. This is a visual/interaction re-skin; how tags are stored and synced is unchanged.

(No secrets, tokens, keys, or PII — one React component, its tests, and localized strings.)

# Status

CODEX APPROVED (9.2) — all 7 gates passed (think 9.2 · plan 9.4 · design 9.4 · build 9.2 ·
review 9.3 · test 9.4 · ship 9.2). **MERGED via PR #56** (merge commit `9d6f3d1`) into `feature/focal-migration` 2026-06-23; branch
deleted (remote + worktree + local). Remaining: the manual light/dark visual QA (disclosed above,
not yet performed).

---
Cleared for release.
