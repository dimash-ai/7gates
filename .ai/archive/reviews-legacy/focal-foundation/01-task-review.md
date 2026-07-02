# Codex Review Verdict

Score: 8.4 / 10
Status: BLOCKED

## Reason
The task is mostly specific and well-scoped, but it includes scoped backend behavior without measurable acceptance criteria and leaves core JWKS cold-cache/key-rotation behavior undefined. Those gaps would force implementation-significant assumptions.

## Must Fix
- `.ai/tasks/focal-foundation.md:39` scopes wiring `user_settings` / `user_onboarding` behind `/me` and `settings` endpoints, but `.ai/tasks/focal-foundation.md:78-79` only requires tests for `/me`. Define the settings endpoint contract and verification, or move it out of scope.
- `.ai/tasks/focal-foundation.md:40-41` scopes a reusable `DASHBOARD_USER_EMAILS` check, but no acceptance criterion or test defines matching rules, empty-list behavior, or unauthorized result. Add measurable criteria or remove it from this slice.
- `.ai/tasks/focal-foundation.md:69-70` says cold JWKS cache / unknown `kid` is "handled without blocking the request path," but does not define expected behavior. Specify whether startup fails, auth rejects with `AuthRequiredError`, stale keys are used, or a background refresh is scheduled.

## Should Consider
- `.ai/tasks/focal-foundation.md:36-38` calls identity healing "best-effort," but does not state what `/me` returns if the upsert fails or races. Add failure/concurrency expectations if profile persistence is required for the slice.

## Tests Reviewed
No tests run; task-definition review only. Inspected `.ai/tasks/focal-foundation.md`, `.ai/checklists/scoring-rubric.md`, and `CLAUDE.md`.

## Release Risk
Medium
