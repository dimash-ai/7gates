# EXAMPLE — NOT A REAL REVIEW

> Codex **test review** (Gate 4) for the imaginary `auth-refresh` feature, in the scored
> verdict format. Codex never edits code; it only reviews and scores.
>
> Invoked as: `codex exec --sandbox read-only "<test review prompt>"`
> Reviewed the added tests plus the captured `make verify` output.

# Codex Review Verdict

Score: 9.2 / 10
Status: APPROVED

## Reason
`make verify` is green and the suite covers the acceptance criteria, including the
straddling-request concurrency case raised at plan review. One non-blocking gap remains.

## Must Fix
None.

## Should Consider
- Add an assertion that no token material appears in emitted logs (the task forbids it); a
  regex/snapshot check over captured log lines would lock this in.

## Tests Reviewed
- `make verify` → test (42 passed), lint, typecheck, build all green.
- Unit: successful refresh, single-retry-then-fail, invalid token, straddling-request race
  (fake clock).

## Release Risk
Low — tests are deterministic via the fake clock; no flaky timing dependencies. A clock-skew
boundary case is a nice-to-have follow-up, not blocking.
