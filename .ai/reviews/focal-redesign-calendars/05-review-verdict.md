# Review Verdict

Reviewer: Opus
Step: review
Score: 8.0 / 10
Status: BLOCKED

## Reason
GPT found two real, accurately-cited defects (the empty value-backed filter saving `filterValue: null`, and the never-re-synced per-card `filterDraft`) — both confirmed against source, neither fabricated. But it materially miscalibrated its headline Must-Fix: it framed the null-filter behavior as a security leak with "High" release risk and hard-blocked on it, without checking that this is faithful parity with the binding old-focal contract (which has the identical no-guard save) and that the filter is an owner-scoped, RBAC-gated narrowing of the owner's *own* events — not a cross-tenant exposure. Correct evidence, inflated threat model; that is a good-not-flawless review.

## Must Fix
- GPT Must-Fix #2 (stale `filterDraft`) is **valid and well-targeted**, and reviewers downstream should act on it: `apps/focal/client/src/features/calendars/CalendarsPage.tsx:325` initializes `filterDraft` via init-once `useState(() => fromCalendar(calendar))`; the card is keyed by stable `calendar.id` (`CalendarsPage.tsx:921`) so a refetch does not remount it and there is no `useEffect` re-sync; Save (`CalendarsPage.tsx:420` → `saveFilterMutation` `730-734`) then writes the stale filter over newer server state. Old-focal's card filter was read-only, so this stale-write surface was introduced by this change — GPT scored this one correctly.

## Should Consider
- GPT Must-Fix #1 should have been a **Should Consider, not a security Must-Fix**. The mechanics are real and correctly cited (`calendarFilters.ts:69` empty value → `null`; save enabled for any `supported` draft at `CalendarsPage.tsx:421`; sent by `createMutation` `685-692` / `saveFilterMutation` `730-734`; backend exact-match at `shared_calendar_filter.py:62-69`), but: (a) it is **faithful parity** with the binding contract — old-focal saves empty `filterValue` with no guard (`old-focal/.../pages/Calendars.tsx:1063-1070`, type-reset at `942-961`) and the backend is explicitly out of scope for this re-skin; (b) it is **not a cross-tenant leak** — `shared_calendars.py:209-218` gates the read by RBAC and the filter only narrows the *owner's own* events, so the worst case is the owner under-narrowing their own share to people they already invited. Calling this "security" with "High" risk overstates it.
- GPT's review under-weighted one genuine acceptance-criteria miss it *did* spot: `GoogleSyncPanel.tsx` is unchanged (confirmed: empty staged diff), yet Scope line 42 + the plan's Files table require restyling it. GPT filed it as Should Consider — fair, though it is an unmet AC, not merely a nicety.
- GPT's review correctly listed missing regression coverage (empty value-backed filter, stale draft after refetch, clipboard rejection, missing self-participation) — verified absent from `CalendarsPage.test.tsx` (no such `it(...)` blocks). This was a good catch.

## Tests Reviewed
Re-ran/inspected: `git -C .worktrees/focal-redesign-calendars diff --cached` (full + per-file); read `calendarFilters.ts`, `CalendarsPage.tsx` (FilterEditor, CalendarCard, state/mutations, render), backend `shared_calendar_filter.py` + caller `shared_calendars.py:204-218`; enumerated `CalendarsPage.test.tsx` cases; confirmed no `any`/`@ts-ignore` in changed files; verified old-focal save guards + read-only card. Did not execute Vitest (read-only review).

## Release Risk
Medium — one real introduced stale-write (Must-Fix #2) and one unmet restyle AC (GoogleSyncPanel) justify holding the gate; GPT's "High" rests largely on a security framing of #1 that does not hold up.
