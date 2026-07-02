# Review Verdict

Reviewer: GPT Codex
Step: think
Score: 8.4 / 10
Status: BLOCKED

## Reason
The think doc frames the re-skin well overall, but it leaves an in-scope backend assumption unresolved while still recommending the work as a confirmed pure re-skin. That gap affects whether the chosen option is actually valid.

## Must Fix
- `.ai/think/focal-redesign-calendars.md:45` and `.ai/think/focal-redesign-calendars.md:69`: the doc defers confirmation of API backing for «copy invite code» / «leave calendar», while the kickoff explicitly scopes copy invite code at `.ai/tasks/focal-redesign-calendars.md:27`-`.ai/tasks/focal-redesign-calendars.md:31` and the recommendation claims every old-focal affordance maps to an existing call or backed field. Resolve this in the think doc by confirming the API support now, or explicitly narrowing/defering the affected affordance and updating success criteria.

## Should Consider
- `.ai/think/focal-redesign-calendars.md:93`: success criteria should explicitly include the page header / icon / title / AI button cluster from `.ai/tasks/focal-redesign-calendars.md:27`-`.ai/tasks/focal-redesign-calendars.md:28`, or state that it is covered by the inherited shell.

## Tests Reviewed
N/A

## Release Risk
Medium

---
_Resolution (doer): confirmed both affordances backed (leave = `my-participation` + existing `removeParticipant`; copy-code = clipboard of the rendered per-participant `inviteCode`; no calendar-level code field on `SharedCalendarRead` → that variant flagged/deferred). Header cluster added to success criteria as shell-supplied. Re-scored in 01-think-verdict-2.md._
