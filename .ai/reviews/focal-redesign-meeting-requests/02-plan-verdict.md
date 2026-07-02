# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.4 / 10
Status: APPROVED

## Reason
The plan is the minimum-viable re-skin: it keeps the working `api/meetingRequests` data/mutation/i18n wiring and only adds the old-focal filter/tab UI plus a card restyle. Every load-bearing claim checks out against source — `MeetingRequestRead.sharedCalendarId: string | null` (openapi.d.ts:3863, via `MeetingRequest = Schemas['MeetingRequestRead']` meetingRequests.ts:5), `listAccessibleCalendars()` returning `{id,name,color}` (sharedCalendars.ts:16-17; openapi.d.ts:2206-2228), and `PageHeader` exposing `icon`/`title`/`rightActions` + an always-mounted `PageToolbar` AI button (PageHeader.tsx:34-97, PageToolbar.tsx:32-35) — so the calendar filter is correctly in-scope (not faked) and the PageHeader/no-page-local-AI decision is sound. Slices are small, independently reviewable, keep the build green between them, and failure modes are named with concrete error→catch-site→user-visible mappings.

## Must Fix
None.

## Should Consider
- The old-focal "main calendar" Select option uses a context-driven custom name (`mainCalendarName` from `CalendarFilterContext`, old-focal MeetingRequestsPage.tsx:336-339), which the plan intentionally drops (context out of scope). The plan never names the key for the "main" label; `calendars.main` is confirmed missing in ru.json. The build step should state the exact key so the doer doesn't reintroduce the context or hardcode the string.
- The plan reproduces old-focal's hardcoded semantic colors (yellow/green/red/blue/orange) "where equivalent" to shell tokens but leaves resolution to build judgment. The new page currently uses semantic tokens only (MeetingRequestsPage.tsx:35-48); the build should make the token-vs-literal-color call explicit per element to avoid dark-mode drift (the gate is a light+dark screenshot match).
- Slice 1 ships pure helpers + locale keys before any consumer — genuinely green here, but the doer should confirm `pnpm lint` stays clean after slice 1 rather than assume it.

## Tests Reviewed
N/A for plan step. Read the existing test file to confirm the plan's test list extends rather than contradicts current coverage; `buildRequest` already carries `sharedCalendarId: null`, so the new calendar-filter tests have a real field to assert against. The 20 named tests each pin a specific behavior.

## Release Risk
Low
