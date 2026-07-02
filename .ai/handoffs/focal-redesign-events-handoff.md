# Stage

Stage 7: ship — `focal-redesign-events` (slice 10 of the `focal-redesign-pages` epic). Branch
`feat/focal-redesign-events` off the shell foundation `afaaeba`; commit `b8c663f`.

# What changed

Added the **События (Events)** page to the new Focal client at exact visual + behavior parity with
old-focal's `pages/Events.tsx` — a filterable, searchable list of calendar events, distinct from the
calendar grid. The page does not exist in the new app today, so this also wires the `/events` route
and the sidebar nav item. It is a **re-skin/assemble over existing APIs** (no server/API/calendar
change): it reuses the calendar's `EventPopover` (create/edit) and `RecurringScopeDialog` (this /
following / all scope) and the existing `api/events.ts` mutations, and adds two new generic
primitives the filter bar needs.

- New page `features/events/EventsPage.tsx`: header (New-event button, filter toggle with active
  count, orphan + priority selects, filtered/total count), collapsible filter card (search,
  project-type, sphere/project/product/activity/tag multi-selects, 14 date presets + custom range,
  reset), upcoming/past grouped date cards with priority stripe, project colour, orphan-dashed,
  recurrence/status/project-type badges, completed treatment; per-row **Edit + Delete** actions
  (one-off deletes immediately; recurring routes through the scope dialog) plus create/edit via the
  reused `EventPopover` — old-focal parity.
- New pure logic `features/events/eventsFilters.ts`: the old-focal `EventFilters` model + defaults,
  validated `localStorage` load/save (single→array, no-tag, invalid-preset→thisMonth, soft
  `all`→thisMonth, and full type-validation so corrupted storage can't crash the page), the predicate
  chain, grouping/sort, recurrence detection, and `CalendarPage`-mirrored draft/payload helpers.
- New primitive `components/ui/multi-select.tsx`: generic controlled multi-select from
  Popover/Badge/Input (single trigger button; no nested buttons).
- New util `lib/datePresetRange.ts`: all 14 presets via timezone-safe calendar-string arithmetic,
  the bounded `all`/incomplete-custom rest range (2020-01-01 → year+2), and the events query-window
  helper.
- Wiring: `App.tsx` `/events` route; `AppSidebar.tsx` **События** item (Исполнение group) + the
  `tasks` nav label retuned from the interim "Tasks & events" back to "Tasks" for old-focal parity;
  `i18n/locales/{en,ru}.json` events + multi-select keys (full EN↔RU parity).

Deferred (flagged in code, not faked): the old-focal `CalendarFilterContext` "viewing another shared
calendar" scope — the new app has no such context yet, so the page shows the signed-in user's own
events and never sends a client-supplied `userId`/`calendarId`.

# Files touched

- `apps/focal/client/src/features/events/EventsPage.tsx` (new)
- `apps/focal/client/src/features/events/EventsPage.test.tsx` (new)
- `apps/focal/client/src/features/events/eventsFilters.ts` (new)
- `apps/focal/client/src/features/events/eventsFilters.test.ts` (new)
- `apps/focal/client/src/features/events/index.ts` (new)
- `apps/focal/client/src/components/ui/multi-select.tsx` (new)
- `apps/focal/client/src/components/ui/multi-select.test.tsx` (new)
- `apps/focal/client/src/lib/datePresetRange.ts` (new)
- `apps/focal/client/src/lib/datePresetRange.test.ts` (new)
- `apps/focal/client/src/App.tsx` (route) · `apps/focal/client/src/App.test.tsx` (new)
- `apps/focal/client/src/components/AppSidebar.tsx` (nav item + tasks label) ·
  `apps/focal/client/src/components/AppShell.test.tsx` (nav tests)
- `apps/focal/client/src/i18n/locales/en.json` · `apps/focal/client/src/i18n/locales/ru.json`

16 files, +3355 / −25. All within `apps/focal/client/src/`. No backend, OpenAPI, package, or
calendar-grid file changed.

# Tests run

```sh
cd superapp/apps/focal/client
pnpm lint        # biome — Checked 227 files. No fixes applied.
pnpm typecheck   # tsc -b — clean
pnpm test:run    # Test Files 54 passed (54) · Tests 445 passed (445)
pnpm build       # ✓ built
```

# Verification output

```sh
 Test Files  54 passed (54)
      Tests  445 passed (445)
✓ built
```

# Still needs review

- **Visual QA (light + dark) against old-focal** is the one thing the gates can't certify — run the
  client locally, sign in to a superapp-dev account, and compare `/events` to old-focal's События:
  `cd superapp/apps/focal/client && pnpm dev`.
- Minor, non-blocking coverage gaps flagged at gate 6 (not fixed to keep the slice surgical): the
  multi-select `maxDisplay` "+N" overflow path, a page-level "Past events" DOM assertion, and the
  `AppShell` test asserting a literal RU nav string.
- The `tasks` nav label was retuned to "Tasks"/"Задачи" (the tasks page's own internal events tab is
  the tasks slice's concern, intentionally untouched here).

# PR / release notes (for users)

The user-facing PR title + body is kept clean (no pipeline/branch narrative) in
[`focal-redesign-events-PR.md`](./focal-redesign-events-PR.md) — use that as the PR description. It
contains no secrets, tokens, keys, or PII.


# Status

CODEX APPROVED (9.1) — all 7 gates ≥9.0. PUSHED + PR #67 OPEN into `feature/focal-migration`
(https://github.com/Allosta-Group/superapp/pull/67). Pre-merge: human visual QA (light/dark) + merge.
