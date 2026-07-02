# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.2 / 10
Status: BLOCKED

(build-slice 4 — clarify-create dialog + TTS, first pass)

## Reason
The slice covers happy paths, validation-before-merge, TTS fallback, creation, and query invalidation, but misses two correctness details: close/unmount does not actually abort clarify/detect fetches and one detect-error path can still mutate after close; the manual create-kind override is silently overwritten by intent detection.

## Must Fix
- `AIClarificationDialog.tsx` creates an `AbortController` but the `clarifyEvent`/`clarifyTask` calls don't receive `controller.signal`, and the wrappers in `api/aichat.ts` expose no signal param — closing aborts only local state, not the in-flight fetch.
- `detectIntent` can reject after the dialog closes; the `catch` still falls through to `processTurn`, which mutates refs/state and starts another request after unmount.
- The selected kind is unconditionally overwritten by `detectIntent`, so a user's idle-state manual choice from the kind buttons is ignored before the first clarify call.

## Should Consider
- Add focused tests for abort-signal propagation and the pre-start manual override.

## Tests Reviewed
Inspected diff, status, `AIClarificationDialog.test.tsx`, API/widget code. Local green reported (typecheck/lint/test:run=1289), not rerun.

## Release Risk
Medium
