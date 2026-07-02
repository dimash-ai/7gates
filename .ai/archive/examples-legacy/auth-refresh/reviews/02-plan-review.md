# EXAMPLE — NOT A REAL REVIEW

> Codex **plan review** (Gate 2) for the imaginary `auth-refresh` feature, in the scored
> verdict format. A must-fix caps the score at 8.9, so this is BLOCKED. Codex never edits code.
>
> Invoked as: `codex exec --sandbox read-only "<plan review prompt>"`
> Reviewed `.ai/plans/auth-refresh-plan.md` against `.ai/tasks/auth-refresh.md`.

# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The three-slice breakdown is sound and each slice keeps the tree green, but one acceptance
criterion is not covered by any slice — a must-fix, which caps the score below 9.0.

## Must Fix
- Concurrency gap. Acceptance criterion 1 requires in-flight requests never see a 401 from an
  expired-but-refreshable token. Slice 2 swaps the stored token but the plan does not describe
  how requests already dispatched with the old token are handled (single-flight refresh +
  transparent retry of the 401'd request). Add this to Slice 2 or 3 before implementation.

## Should Consider
- Name the typed error consistently: the task says "single auth error"; the plan says
  `AuthRefreshError`. Confirm they are the same surface or document the mapping.
- Record the minimum lead-time clamp value alongside the 80%-of-lifetime threshold so it is testable.

## Tests Reviewed
- Test strategy only (no code yet). Planned unit tests look right, but add a case for a request
  straddling the refresh boundary that asserts success after one transparent retry.

## Release Risk
Medium — shipping the token swap without the concurrency handling would cause intermittent
401s under load. Resolve the must-fix and resubmit for re-score.
