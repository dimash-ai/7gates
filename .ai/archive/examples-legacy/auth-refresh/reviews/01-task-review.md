# EXAMPLE — NOT A REAL REVIEW

> Codex **task review** (Gate 1) for the imaginary `auth-refresh` feature, in the scored
> verdict format. Codex never edits code; it only reviews and scores.
>
> Invoked as: `codex exec --sandbox read-only "<task review prompt>"`
> Reviewed `.ai/tasks/auth-refresh.md`.

# Codex Review Verdict

Score: 9.1 / 10
Status: APPROVED

## Reason
Goal, scope, and out-of-scope are clear and the acceptance criteria are testable. Only minor
wording ambiguities remain — none blocking.

## Must Fix
None.

## Should Consider
- Define "transient" for the retry rule (timeouts / 5xx vs 4xx) so the retry boundary is
  unambiguous for implementation and tests.
- Acceptance criterion 1 says in-flight requests "never see a 401" — state explicitly that a
  single transparent retry of a 401'd request satisfies it.

## Tests Reviewed
- N/A at the task stage. Confirmed the task names the cases to test (success,
  single-retry-then-fail, invalid token) and added the straddling-request case to the list.

## Release Risk
Low — the concurrency requirement is the main thing to watch once the plan is written.
