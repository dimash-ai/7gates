# Goal

Bring the new Focal **Запросы на события** page (`apps/focal/client/src/features/meetings/`) to
**exact visual + structural parity with `apps/old-focal`'s `MeetingRequestsPage.tsx`**, reproduced in
the new stack, over the **existing** `api/meetingRequests` API, on top of the **shell foundation**
(this slice's branch `feat/focal-redesign-meeting-requests` is cut off `feat/focal-redesign-shell`,
so it inherits old-focal's tokens). Part of the `focal-redesign-pages` epic ("exact old-focal").

> **Binding visual contract** = `apps/old-focal/client/src/pages/MeetingRequestsPage.tsx` +
> `apps/old-focal/client/src/components/meeting-requests/MeetingRequestCard.tsx`. **Thing changed** =
> `apps/focal/client/src/features/meetings/MeetingRequestsPage.tsx` (+ its tests). **Re-skin, not
> rebuild:** the page already works on `api/meetingRequests` (react-query: accept / decline /
> tentative / reschedule-accept / reschedule-decline / delete) and routes every string through
> i18next — keep that wiring; change the presentation + add the missing filter/tab UI to match
> old-focal.

# Scope

The new page **diverges** from old-focal and must converge to it:
- **Header** — match old-focal: `CalendarClock` icon + title + the pending-count badge
  ("{n} ожидают ответа"); reconcile to the shell's `PageHeader` (icon badge + title + rightActions)
  or old-focal's bespoke header, decided at design.
- **Filter row** — add old-focal's **search Input** (title/organizer) + **type Select**
  (new / reschedule / cancel, with the coloured icons). The **calendar Select** depends on
  accessible-calendars data + a `sharedCalendarId` on the request — **in scope only if that data
  exists** in the new API; otherwise flag as backend-blocked (do not fake).
- **Status filter** — replace the current Button row with old-focal's **Tabs** (all / pending /
  accepted / declined / tentative) with the per-tab icons (Inbox / Check / XCircle / HelpCircle) and
  count badges.
- **Request card** — restyle to old-focal's `MeetingRequestCard` look (status colour coding, type +
  status badges, time / reschedule-was / location / organizer / description rows, the
  accept/decline/tentative + delete actions). Keep the existing mutation wiring.
- **Empty / loading states** — match old-focal (CalendarClock empty Card + hint).
- All strings via **i18next (ru + en)**, reproducing old-focal's exact RU copy.

# Out of scope

- Any **server / API / schema / behaviour** change — frontend-only over the existing
  `api/meetingRequests`; a missing backend field (e.g. a calendar discriminator) is a flagged
  handoff, never faked.
- The **shell** (tokens / sidebar / page-header chrome) — delivered by slice 0 (`feat/focal-redesign-shell`),
  inherited here.
- Other pages; porting old-focal's Tailwind-3 / `apiRequest` / wouter wiring wholesale.

# Acceptance criteria

- [ ] From the worktree: `cd apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run &&
      pnpm build` all green.
- [ ] The page matches `apps/old-focal`'s MeetingRequestsPage in **light and dark** — header, filter
      row, status tabs with counts, request cards (all states), empty/loading — verified by
      screenshots.
- [ ] Behaviour preserved: accept / decline / tentative / reschedule / delete still work over the
      existing API; no regression in `MeetingRequestsPage.test.tsx`.
- [ ] No hardcoded strings (i18next ru + en); no API/behaviour change; surgical diff scoped to
      `features/meetings/`.

# Verification commands

```sh
cd /Users/allosta/Desktop/wt-focal-meeting-requests/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```
