# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.8 / 10
Status: BLOCKED

## Reason
The design is broadly coherent, scoped, and correctly rejects the old hash recovery flow in favor of Supabase PKCE. It is blocked by a concrete scope/verification mismatch that could send implementation and checks to the wrong focal client worktree.

## Must Fix
- `.ai/design/focal-parity-auth-landing-design.md:49` uses `cd superapp/apps/focal/client`, but the kickoff task requires `cd superapp-auth/apps/focal/client` at `.ai/tasks/focal-parity-auth-landing.md:36` and `:43`. Align the design’s target path/verification command with the task so the build and tests run against the intended app.

## Should Consider
- `.ai/design/focal-parity-auth-landing-design.md:73` defines `requestPasswordReset(email)` without explicitly requiring the Supabase redirect target to `/reset-password`; adding that contract and a test assertion would make the PKCE recovery handoff harder to misbuild.

## Tests Reviewed
N/A

## Release Risk
Medium
