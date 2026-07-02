# Stage

Step 7 (ship) — slice `focal-redesign-tasks` of the `focal-redesign-pages` epic: the Tasks page
re-skinned to old-focal core parity. Branch `feat/focal-redesign-tasks`, single commit `b64d163`,
in the git worktree `superapp-tasks` (cut off the slice-0 shell foundation `afaaeba`).

# What changed

Rewrote the new Focal **Tasks page** (`apps/focal/client/src/features/tasks`) to match
`apps/old-focal`'s Tasks page, over the new app's **existing** tasks API, on the slice-0 token
foundation. Frontend-only; no API/behaviour change.

- **Tasks-only** — removed the new app's `all`/`events`/`tasks` tabs + the week-events coupling
  (events live on their own page, a later slice), matching old-focal.
- **Old-focal rows** — active rows: the dual stripe (priority + project-color), orphan amber
  treatment (red alert icon, amber dashed, amber badge with a generic-label fallback for unmapped
  reasons), the mission/provision project-type badge (only for those values), a disabled edit
  affordance + delete; completed rows: dimmed + line-through + delete-only, with the dimmer
  completed-orphan amber.
- **Active/Completed cards** with old-focal's grouping (orphans inline within Active).
- **Old-focal header** — Add (focuses the quick-add) + Filter toggle + orphan select + priority
  select + the **incomplete-only** count badge (`{filtered} of {total}` / `{n} active`).
- Wired to the existing `api/tasks` CRUD + `taskSort` (unchanged); `ru`+`en` locale keys added,
  stale tab/event keys removed.

# Files touched

- `apps/focal/client/src/features/tasks/TasksPage.tsx` (rewrite)
- `apps/focal/client/src/features/tasks/TasksPage.test.tsx` (rewritten + strengthened)
- `apps/focal/client/src/i18n/locales/en.json` + `ru.json` (`focal.tasks.*` keys)

# Tests run

```sh
cd superapp-tasks/apps/focal/client
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```

# Verification output

```sh
$ pnpm test:run
 Test Files  49 passed (49)
      Tests  374 passed (374)
$ pnpm build
✓ built (chunk-size warning only — pre-existing)
```

# Still needs review

- **Manual visual QA** (light + dark, desktop + mobile) vs old-focal Tasks: rows (active/completed/
  orphan), the Active/Completed cards, the header + count badge — the one thing unit tests can't assert.
- **Deferred, flagged (not faked):** the advanced filter panel (`focal-redesign-tasks-filters`) and the
  full create/edit TaskDialog (`focal-redesign-tasks-dialog`); the dialog's `recurrence` +
  multi-participant fields are a **backend gap** (on the event contract, not `TaskCreate`/`TaskUpdate`)
  needing a handoff before that follow-up. The interim quick-add stays the create path until then.

# PR / release notes (for users)

The **Tasks page is re-skinned to the proven Focal design**: a clean tasks-only list with the
familiar priority/project colour stripes, the Active and Completed groups, the orphan highlighting,
and the old-focal header with its task count. It supports light and dark via the shared theme.
Behaviour is unchanged (the same create, complete, and delete). Advanced filtering and the full task
editor follow in the next slices.

> **Visual QA pending:** pixel-parity against old-focal in light + dark (desktop + mobile) has **not**
> yet been verified — that manual screenshot pass is the one remaining acceptance item before merge.
> The slice is code-complete and fully tested (374 green); the redesign inherits the shipped theme but
> the per-screen visual comparison is outstanding (same pending step as slice 0).

(No secrets, tokens, keys, or PII — a frontend component, its tests, and locale strings.)

# Status

CODEX APPROVED (9.2) — all 7 gates passed (think 9.1 · plan 9.4 · design 9.5 · build 9.1 ·
review 9.3 · test 9.5 · ship 9.2). Cleared for release. Remaining before merge: manual light/dark
visual QA, and pushing the branch + opening the PR.
