# Stage

Step 7 (ship) — slice 1 of the `focal-parity` epic: the **shared-calendar context + shell**
foundation. Branch `feat/focal-parity-shared-calendar` → base `feature/focal-migration`
(one squashed slice commit). Frontend-only; no server/API/schema change.

# What changed

Adds the shared-calendar selection + access foundation that the rest of the parity epic consumes
(plan slice 1, "Shared calendar context and shell"). Per-page read-only mutation gating, timezone,
and offline are **later slices** and intentionally not here.

- **`CalendarFilterContext`** (new) — ports old-focal's calendar-filter semantics onto the new typed
  `api/sharedCalendars` + React Query: the selected calendar (`"main"` sentinel in localStorage),
  the 6-role matrix → `canEdit` / `canViewOtherPages` / `canManageCalendars` / `dataOwnerId` /
  `isViewingAsAssistant`, `matchesFilter`, first-entry auto-select gated to participant-only users,
  and a non-throwing default so consumers degrade to the main calendar.
  - **Fails closed** (deny edit + other pages, never main-calendar full rights) when a selected
    calendar can't be resolved — including after a refetch where access was revoked / the calendar
    was deleted — instead of old-focal's fail-open. The selected calendar resolves from the
    accessible list **or** participation data, so an `/accessible` outage doesn't escalate rights.
  - **`matchesFilter` custom** mirrors the new backend evaluator
    (`server/app/domain/shared_calendar_filter.py`): `{ logic, conditions:[{field,operator,value}] }`
    with `eq/neq/in/nin`, `and`=all / `or`=any.
  - Exposes `loadError` when the accessible/participation queries fail.
- **`CalendarSwitcher`** (rewritten) — a dropdown over the main calendar, owned filter-calendars, and
  calendars shared with the user (with their role shown); a load-error affordance + the refresh
  control doubling as retry.
- **`AppSidebar`** — limited menu (only Calendar + Meeting requests) for guests who can't view other
  pages, a "Viewing <name>" banner with the role when viewing someone else's calendar, and the
  Personal-CRM link gated behind the same access.
- **`CalendarsPage`** — dispatches `mainCalendarUpdated` on a main-calendar rename/recolor so the
  switcher live-syncs.
- **`App.tsx`** mounts `CalendarFilterProvider` inside the auth gate; **i18n** adds the
  `focal.app.calendarFilter.*` keys in ru + en.

# Files touched

- `apps/focal/client/src/features/calendars/CalendarFilterContext.tsx` (added)
- `apps/focal/client/src/features/calendars/CalendarFilterContext.test.tsx` (added)
- `apps/focal/client/src/features/calendars/index.ts` (export provider/hook/types)
- `apps/focal/client/src/components/CalendarSwitcher.tsx` (rewritten)
- `apps/focal/client/src/components/AppSidebar.tsx` (limited menu + banner + CRM gating)
- `apps/focal/client/src/components/AppSidebar.test.tsx` (added)
- `apps/focal/client/src/features/calendars/CalendarsPage.tsx` (dispatch `mainCalendarUpdated`)
- `apps/focal/client/src/App.tsx` (mount `CalendarFilterProvider`)
- `apps/focal/client/src/App.test.tsx` (provider passthrough in the router mock)
- `apps/focal/client/src/i18n/locales/en.json`, `ru.json` (`calendarFilter.*` keys)

# Tests run

```sh
cd superapp-parity/apps/focal/client
pnpm typecheck   # tsc -b: 0 errors
pnpm lint        # biome: 264 files, 0 errors
pnpm test:run    # 71 files, 828 tests passed
pnpm build       # production build ✓
```

# Verification output

```sh
$ pnpm test:run
 Test Files  71 passed (71)
      Tests  828 passed (828)

$ pnpm build
✓ built in ~260ms
(pre-existing chunk-size warning only, unrelated)
```

# Still needs review

- **Frontend-only** — no server / API / schema / migration change. The context reads the existing
  `/api/shared-calendars/accessible` + `/my-participation` endpoints; client scoping is **not**
  security (backend RBAC + RLS remain authoritative) — covered by the fail-closed tests.
- Known non-blocking follow-ups (carried to slice 2 / later): an unresolved saved selection fails
  closed but the switcher still shows the "My calendar" label until the user switches; `neq` /
  unknown-operator and the live color-rename branch are not directly unit-asserted.
- Per-page consumption of `canEdit` / `dataOwnerId` / `matchesFilter` is **slice 2** — this slice
  wires the context + shell only.

# PR / release notes (for users)

Focal's sidebar now has a working **calendar switcher**: pick your main calendar, one of your own
filter-calendars, or a calendar someone has shared with you. When you open a calendar shared with
you, the app adapts to your access — view-only guests get a focused menu (Calendar + Meeting
requests) and a banner showing which calendar you're viewing and your role on it. If the calendar
list can't be loaded, the switcher shows a clear error with a one-tap retry. (This lays the
groundwork for shared-calendar viewing; the matching per-page behavior arrives in the next update.)

(No secrets, tokens, keys, or PII in this change — it is client components, a React context, locale
strings, and tests.)

# Status

CODEX APPROVED (9.2) — all 7 gates passed (think 9.4 · plan 9.3 · design 9.3 · build 9.1 ·
review 9.2/9.2 · test 9.3 · ship 9.2). Cleared for release. Remaining: push the branch + open the
PR into `feature/focal-migration`.

---
Cleared for release.
