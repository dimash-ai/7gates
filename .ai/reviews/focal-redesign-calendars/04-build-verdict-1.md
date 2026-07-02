# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.3 / 10
Status: BLOCKED

## Reason
The implementation stays frontend-only and preserves the existing shared-calendar API surface, but it misses a central approved design requirement: the owned-card «Что показывается» section is not an editor. The tests also do not prove the non-default filter create/edit behavior that was the main functional addition.

## Must Fix
- `apps/focal/client/src/features/calendars/CalendarsPage.tsx:376` renders «Что показывается» as a read-only summary, while the approved design requires the owned-card section to contain `FilterEditor` and persist via `updateCalendar` (`.ai/design/focal-redesign-calendars-design.md:41`, `.ai/design/focal-redesign-calendars-design.md:123`). `FilterEditor` only appears in the generic edit dialog at `apps/focal/client/src/features/calendars/CalendarsPage.tsx:1099`, so the required accordion-section edit flow is missing.
- `apps/focal/client/src/features/calendars/CalendarsPage.test.tsx:140` claims create is "not a hardcoded filterType" but only submits the default `all` payload at `apps/focal/client/src/features/calendars/CalendarsPage.test.tsx:156`. Add coverage for selecting a non-default filter and for editing an existing calendar filter, as required by `.ai/plans/focal-redesign-calendars-plan.md:75` and `.ai/plans/focal-redesign-calendars-plan.md:77`.

## Should Consider
- Add visible `isError` handling for accessible-calendar and participant query failures; the design calls for section-local errors, but the current participants/accessibles branches have no error UI (`apps/focal/client/src/features/calendars/CalendarsPage.tsx:446`, `apps/focal/client/src/features/calendars/CalendarsPage.tsx:955`).
- Restore regression coverage for participant role update/remove; the old role-change test was dropped and the plan explicitly called out invite/role/remove API-call coverage.

## Release Risk
Medium

---
_Resolution (doer): moved `FilterEditor` into the owned-card «Что показывается» section (owner-editable, persists via a new `saveFilterMutation` → `updateCalendar`); slimmed the pencil dialog to name+color. Added tests: non-default-filter create (drives the Radix Select → filterType `isWorkTime`/`true`), in-section filter edit (→ `updateCalendar` filterType/filterValue only), and restored the participant role-change test. Added section-local `isError` UI for accessible + participants. typecheck/lint/370 tests/build all green. Re-scored in 04-build-verdict-2.md._
