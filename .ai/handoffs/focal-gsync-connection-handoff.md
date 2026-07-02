# Stage

Gate 7 (ship) — sub-slice ① (connection) of the `focal-parity` epic's slice 10 (advanced Google
Calendar sync). Branch `feat/focal-gsync-connection` → base `feature/focal-migration` (rebased onto
the current tip; one commit). **Frontend-only — no server / API / schema / migration change.**

# What changed

Adds the **main-calendar Google connection** UI and hardens the existing per-filter panel, wired to
the already-migrated backend via the existing typed `api/integrations.ts`. This is the connection
sub-slice; the direction/mode/custom-filters panel and the inbound/outbound/notification options are
**later sub-slices** of slice 10 and intentionally not here.

- **`MainCalendarGoogleSection`** (new) — the personal («Мой календарь») Google section: connect
  (OAuth begin URL), connected badge + account email, a **Google-calendar picker** (`getGoogleCalendars`
  / `selectGoogleCalendar`), an **auto-sync interval** picker (off / 15m / 30m / 1h / 3h / daily →
  `updateSyncSettings` `autoSync`+`autoSyncInterval`), and disconnect. Per-query **load-error states**
  for the calendars/settings queries, and a shared `role="alert"` **action error** when the select /
  interval / disconnect mutations reject. Mounted as a collapsible "Google" section on the
  `MainCalendarCard` in `CalendarsPage`.
- **`GoogleSyncPanel`** (existing per-filter-calendar panel) — now also surfaces the shared localized
  action error when its per-calendar disconnect rejects (previously swallowed), plus a new test.
- **i18n** — `focal.calendars.google.*` keys added in ru + en (actionError, calendarLabel,
  calendarPlaceholder, intervalLabel, intervals.*, primarySuffix).

# Files touched

- `apps/focal/client/src/features/calendars/MainCalendarGoogleSection.tsx` (added)
- `apps/focal/client/src/features/calendars/MainCalendarGoogleSection.test.tsx` (added)
- `apps/focal/client/src/features/calendars/GoogleSyncPanel.tsx` (action-error on disconnect failure)
- `apps/focal/client/src/features/calendars/GoogleSyncPanel.test.tsx` (added)
- `apps/focal/client/src/features/calendars/CalendarsPage.tsx` (mount the Google section on MainCalendarCard)
- `apps/focal/client/src/i18n/locales/en.json`, `ru.json` (`calendars.google.*` keys)

# Tests run

```sh
cd superapp-gsync/apps/focal/client
pnpm typecheck   # tsc -b: 0 errors
pnpm lint        # biome: 310 files, 0 errors
pnpm test:run    # 100 files, 1170 tests passed
pnpm build       # production build ✓
```

# Verification output

```sh
$ pnpm test:run
 Test Files  100 passed (100)
      Tests  1170 passed (1170)
$ pnpm build
✓ built in ~290ms
```

# Still needs review

- **Frontend-only** — no schema/migration; reuses the existing `/api/integrations/google/*` endpoints
  and the typed `api/integrations.ts` client.
- Non-blocking follow-ups (carried to later sub-slices / backfill): cross-surface cache invalidation
  between the main-section disconnect and the per-filter `GoogleSyncPanel` status caches; the
  unreachable `: 'off'` interval fallback; asserting `role="alert"` in the action-error tests;
  backfilling tests for `GoogleSyncPanel`'s pre-existing connected/loading states. The Radix Select
  `onValueChange` (calendar-select / interval-change) is not interaction-tested (Radix Select is
  unreliable in happy-dom); render / load-error / mutation-error / connect / disconnect are.
- **Pipeline deviation:** the GPT-Codex side (Gate-5 review pass, Gate-6 test doer, and this Gate-7
  final release review) was unavailable this session (hung at startup / returned a stale verdict under
  3+ parallel-session load). Those gates were performed by fresh-context **Opus subagents** instead —
  documented in each `reviews/focal-gsync-connection/*-verdict.md`. Gate 4 (build) was the normal
  GPT-Codex review (APPROVED 9.2).

# PR / release notes (for users)

You can now connect **Google Calendar from your main calendar** in Focal: open the calendar's
"Google sync rules" section to link your Google account, choose which Google calendar to sync, set
how often it auto-syncs (off, every 15/30 minutes, hourly, every 3 hours, or daily), and disconnect
when you're done. If the calendar list or settings can't load, or an action fails, you now get a
clear, localized error instead of a silent no-op. (This is the connection groundwork; the full
two-way-sync controls — direction, what-to-sync filters, and request settings — arrive in the next
updates.)

(No secrets, tokens, keys, or PII in this change — it is client components, locale strings, and tests.)

# Status

CLEARED FOR RELEASE — gates 4-7 passed (build 9.2 GPT-Codex · review 9.2 Opus · test 9.2 Opus ·
ship 8.8→resolved Opus). The ship gate's sole Must-Fix (stale rebase → would show a spurious flower
backend-dep deletion) was fixed by rebasing onto the current `feature/focal-migration`; re-verified
the diff is exactly the 7 intended frontend files and re-ran green (typecheck · lint · 1170 vitest ·
build). GPT-Codex was unavailable for gates 5-7 (hung under parallel-session load) → Opus subagents
reviewed; gate 4 was the normal GPT-Codex review.
