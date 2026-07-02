# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.6 / 10
Status: BLOCKED

## Reason
The full 6-type filter expansion is justified by the old-focal contract and is backed by existing `filterType`/`filterValue` plus `listSpheres`/`listProjects`. The design is otherwise well-scoped, but two interface/data-model issues need correction before build because they can lead to broken implementation or silent filter normalization.

## Must Fix
- `.ai/design/focal-redesign-calendars-design.md:68` misstates `MyParticipationRead` as `{ calendars: MyParticipationItem[] }`; the generated contract is `participatingCalendars`, `isOnlyParticipant`, and `ownCalendarsCount` (`superapp/apps/focal/client/src/api/openapi.d.ts:3923`). Correct the interface notes/usage so the accessible/leave surface is built against the real response shape.
- `.ai/design/focal-redesign-calendars-design.md:76`-`.ai/design/focal-redesign-calendars-design.md:81` defines `FilterDraft` as only the 6 supported types, but `.ai/design/focal-redesign-calendars-design.md:98`-`.ai/design/focal-redesign-calendars-design.md:100` and `.ai/design/focal-redesign-calendars-design.md:116` require unknown/custom stored shapes to be displayed without silent rewrite. Add an explicit unsupported/read-only draft state or make `fromCalendar` nullable so the contract cannot accidentally normalize unknown filters.

## Should Consider
- Clarify whether «Доступные мне» is derived from `participatingCalendars` or from `listAccessibleCalendars` filtered to non-owned calendars, since the backend accessible endpoint includes owned calendars too.

## Tests Reviewed
N/A

## Release Risk
Medium

---
_Resolution (doer): corrected `MyParticipation` notes to the real `{participatingCalendars[{calendar,role,isOwner}], isOnlyParticipant, ownCalendarsCount}` shape (leave id still via `listParticipants` + `user.id`); made `FilterDraft` a discriminated `supported | unsupported` union with `toFilterPayload → null` for unsupported (never normalized); clarified «Доступные мне» = `listAccessibleCalendars` filtered `userId !== user.id`, leave scoped by `participatingCalendars(!isOwner)`. Re-scored in 03-design-verdict-2.md._
