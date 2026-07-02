# EXAMPLE — NOT A REAL REVIEW

> Codex **implementation review** (Gate 3) for slice 1 of the imaginary `auth-refresh`
> feature, in the scored verdict format. Codex never edits code; it only reviews and scores.
>
> Invoked as: `codex exec --sandbox read-only "<diff review prompt>"`
> Reviewed: `git diff` for Slice 1 — Refresh client (pure exchange).

# Codex Review Verdict

Score: 9.3 / 10
Status: APPROVED

## Reason
The Slice 1 diff is self-contained, matches the plan's scope, and is covered by tests; only
non-blocking polish remains.

## Must Fix
None.

## Should Consider
- Assert the token endpoint URL is present at startup so a missing config value fails loudly
  rather than at first refresh.
- Add a one-line comment noting `expiresAt` is derived from `expires_in` in seconds.

## Tests Reviewed
- `make test lint typecheck` (passes in the provided output).
- Unit tests for the pure exchange: success + invalid token.

## Release Risk
Low — adds an as-yet-unused pure function and a typed error; no behavior change until later
slices wire it in. No token values logged or thrown.
