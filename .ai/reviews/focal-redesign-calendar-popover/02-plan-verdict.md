# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.3 / 10
Status: APPROVED

## Reason
This is a minimum-viable, reuse-first plan: it builds on the existing mutations, `RecurrenceScope`, `prefill`/`onSelect`, and the foundation primitives rather than rebuilding, and every load-bearing claim I checked against the real code holds. The anchoring mechanic, the `completed` mapping, the dependent link-query wiring, the failure modes, and the payload-preserving test rewrite are all concrete and correct, and the think doc's three open questions are resolved with explicit recommendations.

## Must Fix
None.

## Should Consider
- **Sharpen the "dirty fields" rule at the design gate** (plan line 45 vs tests lines 89, 92). The recurring-update test asserts the patch is exactly `{title, date, startTime, endTime, recurrence}` (no `completed`/`color`) while the mark-done test asserts an update *does* send `completed` when toggled. These reconcile only if the 5 core fields are always-sent but `completed`/`color`/link-IDs are sent solely when changed. Pin the "core vs conditional" partition precisely in design.
- **Name the `EventBlock.onSelect` anchor type's home** — co-locate the `AnchorSource` type with `EventPopover` and import it into both `EventBlock` and `CalendarPage` to avoid a `CalendarPage`→`EventBlock` import cycle.
- **ContactPicker inside a Radix `Popover`** — the nested own-popover may fight the outer popover's outside-click/Escape focus-scope; verify during build.

## Tests Reviewed
N/A (plan step). Verified the plan's test claims against `CalendarPage.test.tsx` (preserved create/edit/delete + recurring-scope assertions) and `EventBlock.test.tsx` (`onSelect` extended to `(event, anchor)`); confirmed `occurrenceDate?` on `EnrichedEventRead` (openapi.d.ts:3109), `EventCreate`/`EventUpdate` carry every popover field, `PopoverAnchor`+`virtualRef` supported (@radix-ui/react-popover 1.1.16) and not yet exported (popover.tsx:29), and the radio-group/select/switch/checkbox primitives exist.

## Release Risk
Low
