# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.6 / 10
Status: BLOCKED

## Reason
The design mostly matches the task and plan: it stays frontend-only, preserves the old-focal filter model, reuses existing event APIs, and names unhappy paths and test coverage. It is blocked because the reused `EventPopover` interface is documented incompletely, which makes the state/lifecycle contract unsound for an unchanged reuse.

## Must Fix
- `.ai/design/focal-redesign-events-design.md:100` documents `EventPopover` without required props and `.ai/design/focal-redesign-events-design.md:26` omits the corresponding state/lifecycle ownership. The real contract requires `recurring`, `participants`, `isSaving`, `isDeleting`, `onParticipantsChange`, and `onOpenChange` (`superapp/apps/focal/client/src/features/calendar/EventPopover.tsx:43`), and CalendarPage relies on an `onOpenChange` guard to keep the draft while the recurring-scope dialog is open (`superapp/apps/focal/client/src/features/calendar/CalendarPage.tsx:501`). Update the design to include these required props and lifecycle rules, or explicitly define a wrapper/no-op strategy that still compiles and preserves the promised draft behavior.

## Should Consider
- `.ai/design/focal-redesign-events-design.md:83` leaves `todayYmd` derivation unspecified. Old-focal derives it from the display timezone (`superapp/apps/old-focal/client/src/pages/Events.tsx:178`); clarify whether the new page intentionally uses browser-local date or needs a shared helper to avoid date-preset drift.

## Tests Reviewed
N/A

## Release Risk
Medium

---
> Resolved 2026-06-23 in design rev2: full `EventPopover` contract (`recurring`/`participants`/`isSaving`/`isDeleting`/`onParticipantsChange`/`onOpenChange`) + the `onOpenChange` keep-open-while-`pendingOp` guard added to both the state-ownership and interface sections; `todayYmd` pinned to `toIsoDate(new Date())` (browser-local, matching `CalendarPage`). Re-review → `03-design-verdict-2.md`.
