# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 8.4 / 10
Status: BLOCKED

## Reason
The route/nav rename, section order, API/query-key preservation, Google-unavailable null return, one-shot secret handling, HTTPS webhook guard, PrimeTime retention, `#ai-agents`, and delete-account confirmation are in place. The build still misses concrete old-focal visual surfaces required by the task/design, so the re-skin is not yet at the approved visual contract.

## Must Fix
- `PushSection.tsx` renders the enabled state as plain enable/test/disable buttons without the old-focal active/inactive header badge and switch-like main control (`old-focal/.../Integrations.tsx:147`,`:181`).
- `SettingsPage.tsx` Backup card omits the muted warning panel from the binding contract (`old-focal/.../Integrations.tsx:1707`). Add the localized warning copy/panel.

## Should Consider
- Add focused assertions for the push status/switch affordance and backup warning panel so these parity surfaces do not regress.

## Tests Reviewed
diff/status + task/plan/design + changed files + old-focal references; `git diff --check`, `biome check`, `tsc --noEmit` passed; Vitest blocked by read-only sandbox EPERM.

## Release Risk
Medium
