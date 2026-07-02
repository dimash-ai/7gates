# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.8 / 10
Status: BLOCKED

## Reason
The prior EventPopover contract gap is mostly resolved: the design now names the required props and documents the `onOpenChange` keep-open guard, and the `todayYmd` choice is explicitly justified. However, the participant ownership contract is still internally wrong against the real CalendarPage behavior.

## Must Fix
- `.ai/design/focal-redesign-events-design.md:121` says participants mirror CalendarPage as "empty on create; the event's contacts on edit," but `superapp/apps/focal/client/src/features/calendar/CalendarPage.tsx:261` sets participants to `[]` on edit, and the popover contract takes `PrimaContact[]`, not event `contactIds`. Correct the design to match existing state ownership and avoid implying new contact hydration/persistence work.

## Should Consider
None

## Tests Reviewed
N/A

## Release Risk
Medium

---
> Resolved 2026-06-23 in design rev3: participants now stated as `[]` on **both** create and edit (matching `CalendarPage.tsx:253,261`), popover takes `PrimaContact[]` (no `contactIds` hydration), no new contact persistence. Re-review → `03-design-verdict-3.md`.
