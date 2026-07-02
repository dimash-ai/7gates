# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.3 / 10
Status: APPROVED

## Reason
The plan is a minimum, surgical re-skin that preserves all behavior, correctly sequences the orphan `parseInline` removal after react-markdown replaces its sole caller (AIChatPage.tsx:40-54), and faithfully implements the think doc's binding decision (react-markdown + scoped `.aichat-prose` because the client has neither `react-markdown` nor `@tailwindcss/typography`). Every named shell primitive (`useSidebarOptional`, `SidebarTrigger`, `PageToolbar`) exists and is verifiably usable, failure modes are named with concrete error/catch/user-visible triples, and the local-header + no-timezone-extension decisions are surfaced tradeoffs rather than silent assumptions.

## Must Fix
None

## Should Consider
- Think-doc/plan precedent claim is inaccurate (non-blocking): both the think doc (lines 38-40) and the plan ("Header risk") state tags/heatmap "rendered the trigger via `useSidebarOptional` + a bespoke header," but `TagsPage.tsx:84-96` and `HeatmapPage.tsx:218` use bespoke headers with no `useSidebarOptional`/`SidebarTrigger` — that trigger comes from the shared `AppShell`/`PageHeader`. The executable instruction is still sound (the primitives exist and `PageHeader.tsx:44-50` demonstrates the exact pattern); only the cited precedent is wrong.
- The new app has no `HelpTooltip`/`PresetHelpTooltip` to port old-focal's `aiChat.overview` help preset; the plan's "help uses the old `aiChat.overview` copy through localized tooltip content" is achievable via the existing `Tooltip` primitives + new `focal.aichat.help.*` keys (which the plan does add), but could state explicitly that the preset component is reproduced, not reused.
- `isPastEvent` uses local-timezone `date`+`endTime??startTime` because `ChatEventInfo` carries no `timezone` (unlike old-focal); the plan correctly declines to extend the type and flags the ambiguity, but the build step should ensure the test fixtures pin a deterministic local time so the past/non-past assertions don't flake on the runner's TZ.

## Tests Reviewed
N/A

## Release Risk
Low
