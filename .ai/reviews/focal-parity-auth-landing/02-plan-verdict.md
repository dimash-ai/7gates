# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.1 / 10
Status: APPROVED

## Reason
The plan re-expresses Supabase recovery on the PKCE `?code=` flow rather than transliterating old-focal's hash `type=recovery`, preserves the critical auth-bypass guard old-focal carried in `AuthProvider` (the "non-recovery auth events cannot overwrite an active recovery session" test), and names every failure mode with a specific exception, catch site, and user-visible outcome (17-row error map). It is reuse-first and surgical: no `@allosta/auth`, no backend, reuses `getSupabase()`, the existing public toggles, and the `translation.focal.*` i18n namespace.

## Must Fix
None.

## Should Consider
- Landing-header control fidelity: old-focal `FocalLanding.tsx:213` renders `LanguageToggle` only; the new client's `PublicToggles` bundles language+theme. Pin at design whether the landing header is language-only (strict parity) or language+theme.
- Recovery vs cache-clear ordering: the recovery guard must precede the existing `onAuthStateChange` `userChanged → queryClient.clear()` path so a recovery session can't trip a cache clear. Make explicit at design/build.
- Task vs plan path: task says `cd superapp-auth/...` (the worktree), plan says `cd superapp/...` (generic). Harmless; flag for cleanliness.

## Tests Reviewed
N/A (plan step) — the test inventory is sound: pure-unit tests for `supabaseErrors` + `commonPasswords` decouple cooldown math from UI timing; `AuthProvider.recovery.test.tsx` proves the handshake, TTL/clear, stale-flag ignore, and the no-overwrite guard; reset/login tests cover pending/expired/success, rate-limit escalation, and generic-copy-without-raw-leak.

## Release Risk
Low — frontend-only, env-driven identity unchanged, no migration/backend/Supabase-config change; rollback is a revert of the listed client files.
