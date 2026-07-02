# Review Verdict

Reviewer: Opus
Step: build
Score: 9.2 / 10
Status: APPROVED

## Slice
4a.3 — `TaskInfoDialog` + wiring TaskDialog/TaskInfoDialog into `TasksPage` (demote quick-add).

## Reason
TaskInfoDialog faithfully ports old-focal's component (title, inline due-date PATCH, project-type badge, description, completed toggle, Edit/Delete) with every write affordance `canEdit`-gated and `currentCalendarId` threaded; TasksPage wiring (Add→create, pencil→edit, row→info, quick-add demoted, schedule-as-event) is correct and the slice-2 invariants (canEdit guards, calendarId scoping, grouping/sort/badges/stripes/header-selects/count, `['tasks']`/`['events']` invalidations) are fully preserved with strong new test coverage.

## Must Fix
None

## Should Consider
- **Scope (tracked for the PR body):** the cumulative locale diff carries a `focal.app.timezone.*` block (label/search/popular/all/useSystem/notFound + 12 cities) added in the 4a.2 commit. Verified: `TimezoneSelector.tsx` (slice 3, already merged) **consumes** these keys and `feature/focal-migration` had **zero** of them — so this is an additive backfill that fixes a live slice-3 raw-key render, in both en+ru. Kept (removing it re-breaks TimezoneSelector); will be called out in the ship PR body as a sibling-slice i18n backfill.
- Minor parity: `TaskInfoDialog` description renders plain `whitespace-pre-wrap`; old-focal wraps it in `LinkifyText` (no such primitive yet) — defer to a later parity pass.
- `projectType` badge defaults unknown→`provision` (matches old-focal's else branch); cosmetic.

## Tests Reviewed
`TaskInfoDialog.test.tsx` (controls, completion PATCH + calendarId + invalidate, due-date popover PATCH, edit handoff, delete+close, read-only omission + no-write, error-no-close); `TasksPage.test.tsx` (Add→create with quick-add gone, pencil→edit, row→info, canEdit=false disables/omits + no-write, calendarId threaded everywhere, schedule-as-event incl. `timezone` + dual invalidation, create-error keeps dialog open). Local typecheck/lint clean, `pnpm test:run` 78 files / 913 passed.

## Release Risk
Low
