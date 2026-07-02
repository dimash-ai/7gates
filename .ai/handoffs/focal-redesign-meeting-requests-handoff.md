# Stage

Step 7 (ship) — slice of the `focal-redesign-pages` epic: the **Запросы на события** (meeting
requests) page. Branch `feat/focal-redesign-meeting-requests` (worktree, cut off the shell foundation
`feat/focal-redesign-shell`), single commit `0112cea`.

# What changed

Re-skinned the new Focal meeting-requests page to **exact parity with old-focal's
`MeetingRequestsPage` + `MeetingRequestCard`**, keeping the existing `api/meetingRequests`
react-query wiring. Frontend-only; behaviour preserved.

- **Header** → shared `PageHeader` (CalendarClock icon + title + pending-count badge); the AI control
  stays in the shared toolbar (no page-local duplicate).
- **Filter row** added: search (title/organizer) + **calendar** Select (`listAccessibleCalendars` +
  `sharedCalendarId`, incl. the personal "main" calendar) + **type** Select (new/reschedule/cancel).
- **Status tabs** (all / pending / accepted / declined / tentative) with old-focal icons + count
  badges from the full request list.
- **Request card** rebuilt to old-focal's look — status-coloured left border, type/status badges, the
  time row, the orange "Было" reschedule row, location / organizer / description, and the
  accept / decline / tentative / delete actions — all over the existing mutations (incl. reschedule
  routing and the duplicate-submit guard).
- Pure filter helpers added to `requests.ts`; all strings via i18next (ru reproduces old-focal copy).

# Files touched

- `apps/focal/client/src/features/meetings/MeetingRequestsPage.tsx`
- `apps/focal/client/src/features/meetings/requests.ts`
- `apps/focal/client/src/features/meetings/MeetingRequestsPage.test.tsx`
- `apps/focal/client/src/i18n/locales/ru.json`, `en.json`

# Tests run

```sh
cd /Users/allosta/Desktop/wt-focal-meeting-requests/apps/focal/client
pnpm lint        # biome: 217 files, 0 errors
pnpm typecheck   # tsc -b: 0 errors
pnpm test:run    # 49 files, 384 tests passed (33 in the meeting-requests file)
pnpm build       # production bundle built
```

# Verification output

```sh
$ pnpm test:run
 Test Files  49 passed (49)
      Tests  384 passed (384)
$ pnpm build
✓ built (chunk-size warning only — pre-existing, unrelated)
```

# Still needs review

- **Manual light/dark visual QA** vs old-focal — header, filter row, status tabs+counts, each card
  state (pending/accepted/declined/tentative + reschedule "Было"), empty + search-empty. This is the
  task's screenshot-verified acceptance criterion and is **NOT yet satisfied** — it is the explicit
  remaining **pre-merge** gate (the code implements light+dark via old-focal's `dark:`-variant
  classes, but pixel parity is not screenshot-verified yet). Do not merge until this is signed off.
- Frontend-only: no server / API / schema / behaviour change. The calendar filter uses the real
  `listAccessibleCalendars` + `sharedCalendarId` (not faked). Builds on the shell slice's tokens.
- The pending status-tab count badge intentionally mirrors old-focal's `bg-yellow-100` (no `dark:`
  variant) — contract-faithful, not an oversight.

# PR / release notes (for users)

**The Запросы на события (meeting requests) page now matches Focal's established design.** You get
the familiar layout — a search box, calendar and request-type filters, status tabs (all / pending /
accepted / declined / under-question) with live counts, and the colour-coded request cards with their
accept / decline / tentative / delete actions, including the "was: <old time>" line for reschedules.
Behaviour is unchanged — only the look. (Final light/dark visual sign-off is pending before merge.)

(No secrets, tokens, keys, or PII in this change — UI components, filter helpers, tests, and ru/en
locale strings.)

# Status

CODEX APPROVED (9.1) — all 7 gates passed (think 9.2 · plan 9.4 · design 9.3 · build 9.4 ·
review 9.4 · test 9.4 · ship 9.1). Code cleared for release. Remaining before merge: the light/dark
**screenshot visual QA** (the task's acceptance criterion, not yet satisfied), then push the branch +
open the PR (base `feature/focal-migration`).

---
Cleared for release pending the pre-merge visual QA.
