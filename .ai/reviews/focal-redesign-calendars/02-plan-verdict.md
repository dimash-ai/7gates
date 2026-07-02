# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.3 / 10
Status: APPROVED

## Reason
The plan is a true minimum-viable re-skin that stays inside the think doc's contract: every affordance I checked is backed by the existing code, the failure modes are named with which-error/caught-where/what-the-user-sees, each test states what it proves, and the one risky assumption (leave-calendar self-removal) is verified backable in the actual backend. I verified the load-bearing claims against source and found no correctness, scope, or security defect to cite.

## Must Fix
None.

## Should Consider
- **Filter-editor parity is partial vs the binding contract.** Old-focal's «Что показывается» Select offers 6 types — `all`, `isWorkTime`, `sphere`, `project`, `product`, `projectType` (`apps/old-focal/client/src/pages/Calendars.tsx:954-959`); the plan ships only 5 UI options (all/workTime/personalTime/mission/provision), i.e. it drops `sphere`/`project`/`product` (which require extra spheres/projects/products fetches, resolved at `Calendars.tsx:581-586`). The plan's handling is sound and contract-safe (unsupported shapes render read-only, never overwritten — plan lines 34, 106), and the think doc deferred the exact shape to the design gate, but this is a visual-parity reduction being pre-decided in the plan; the design gate should explicitly ratify it against the screenshot rather than inherit it silently.
- **`listMyParticipation` is not what resolves the leave id.** `MyParticipationRead`/`MyParticipationItem` carry no participant-row id (`openapi.d.ts` ~3916-3931; backend `app/schemas/shared_calendar.py:95-104`), so the self participant id must come from `listParticipants(calendarId)` + the authenticated `user.id` regardless. The plan already states this fallback (slice 6, lines 56-60), but frames `listMyParticipation` as the primary leave source; it is really the list-scoping/affordance source, and `listParticipants` is the id resolver in every case. Worth stating plainly so the build doesn't assume the wrapper yields the id. The wrapper is still correctly in scope (the task names it explicitly).
- **Self-removal happy path is provable in a unit test, but lean on the existing backend guarantee.** The backend already proves self-removal returns 204 for a viewer (`apps/focal/server/tests/test_shared_calendar_participants_db.py:256-260`); the frontend test (plan line 87) only needs to prove the correct `removeParticipant(calendarId, selfParticipantId)` call is made — which the plan states. No change needed; flagging so the build doesn't over-test backend behavior from the client.

## Tests Reviewed
N/A (plan step — no tests executed). I reviewed the plan's proposed test list (plan lines 68-95) for whether each states what it proves: the create test proves `filterType`/`filterValue`/`filterRules` flow from UI state instead of hardcoded `'all'` (correctly targets the real gap at `CalendarsPage.tsx:84`); the leave tests prove `removeParticipant` is called with the resolved self id and that missing-self blocks the delete; the clipboard tests prove the rendered per-participant `inviteCode` is copied with no API call (matches `CalendarsPage.tsx:369-373` and old-focal `Calendars.tsx:532-533`) and that the denied path shows a localized error. Coverage maps to the risky paths, not just the happy path. I also re-read the existing `CalendarsPage.test.tsx` (the "moved-DOM" baseline the plan updates) and confirmed the create assertion at lines 123-128 is exactly what the filter-wiring slice must change.

## Release Risk
Low. No server/API/schema/migration change; rollback is a client-only revert (plan lines 132, 139-140). Every affordance is verified backed by existing endpoints and primitives, and the one contract-dependent feature (leave) is confirmed enforceable by the live backend self-removal branch.
