# Stage

3-gate · slice 13 (final) of the `focal-parity` epic: **Cleanup sweep**. Branch
`feat/focal-parity-cleanup` → base `feature/focal-migration` (one commit `809f2c3`).
Frontend-only; no server/API/schema/migration (all endpoints already exist).

# What changed

Four small residual-parity fixes (the cleanup slice from the epic plan):
1. **Meeting-accept refreshes the calendar** — accepting (or reschedule-accepting) a meeting request
   now invalidates the calendar events query so the new event appears immediately; decline / tentative
   / delete do NOT (no event created), via an `{ invalidateEvents }` flag on the shared success
   handler.
2. **Theme + language toggles on the public Privacy/Terms pages** — a shared `PublicToggles` (theme
   via `useTheme`, language via the existing dropdown pattern), mounted on the session-less legal
   pages; the full `PageToolbar` is deliberately not used (it carries shell assumptions).
3. **Type-to-confirm on calendar delete** — the delete dialog now requires typing the confirm word
   (`Delete`/`Удалить`) before the action enables; resets on open and close; leave/remove keep the
   plain confirm; the DELETE endpoint is unchanged.
4. **Tasks/Events orphan-count sidebar badges** — a red `AlertTriangle` + count badge on the Tasks
   and Events nav items, from `/api/stats/orphans` (camelCase contract, rest-of-period window so it
   doesn't undercount, calendarId-scoped). The query is `enabled: canViewOtherPages` so limited
   shared-calendar users (viewer/requester) never fire the owner-only endpoint.

# Files touched

12 files: `features/meetings/MeetingRequestsPage.tsx`, `features/legal/{PrivacyPage,TermsPage}.tsx` +
new `features/legal/PublicToggles.tsx`, `features/calendars/CalendarsPage.tsx`,
`components/AppSidebar.tsx` (+ their tests) and `i18n/locales/{en,ru}.json`.

# Tests run

```sh
cd apps/focal/client
pnpm typecheck   # 0 errors
pnpm lint        # biome: 0 errors (280 files)
pnpm test:run    # 78 files, 934 tests passed
pnpm build       # ✓
```

# Still needs review

- **Frontend-only** — no schema/migration. The orphan badge respects the same RBAC boundary as the
  endpoint (`canViewOtherPages` = owner/full_access/developer); client scoping is not security
  (slice-2 RBAC/RLS is the boundary).

# PR / release notes (for users)

Accepting a meeting request now updates your calendar right away. The public Privacy and Terms pages
get **dark-mode and language** toggles. Deleting a calendar now asks you to **type the confirm word**
first. And the sidebar shows a small **count badge** on Tasks/Events for items missing a project or
product, so orphaned items are easy to spot.

(No secrets, tokens, keys, or PII — client components, locale strings, and tests.)

# Status

OPUS VERIFY/RELEASE-GATE APPROVED (9.4). Gate-A design APPROVED 9.4 (2 passes) · Gate-B build APPROVED
9.4 (first pass). Cleared for release; open the PR.
