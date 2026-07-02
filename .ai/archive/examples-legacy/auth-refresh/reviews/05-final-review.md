# EXAMPLE — NOT A REAL REVIEW

> Codex **final release review** (Gate 5) for the imaginary `auth-refresh` feature, using
> `prompts/final-release-review.md`, in the scored verdict format. Codex never edits code.
>
> Invoked as: `codex exec --sandbox read-only "<final release review prompt>"`
> Reviewed the full diff vs. base, tests, `make verify` output, and the PR text in
> `auth-refresh-handoff.md`.

# Codex Review Verdict

Score: 9.5 / 10
Status: APPROVED

## Reason
All acceptance criteria are met and tested, every prior gate scored >= 9.0, and the PR
description accurately reflects the change. Cleared for release.

## Must Fix
None.

## Should Consider
- Name the new structured log fields in the PR's "What changed" so on-call knows what to
  search for after rollout.

## Tests Reviewed
- Full `make verify` on the complete change (test, lint, typecheck, build) — green.
- Confirmed the concurrency and invalid-token paths are exercised end-to-end.

## Release Risk
Low — additive behind the existing auth client with a documented rollback (revert the new
modules). No migrations, no new dependencies, no breaking changes to login/logout.
