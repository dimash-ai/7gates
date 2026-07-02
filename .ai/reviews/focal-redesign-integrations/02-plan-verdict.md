# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.1 / 10
Status: APPROVED

## Reason
The plan is a genuine minimum-viable re-skin plus the user-approved `/settings`→`/integrations` rename: it reuses every existing API wrapper, React Query key, mutation, and section behavior (verified against the real `SettingsPage.tsx`, `GoogleCalendarSection.tsx`, `AgentTokensSection.tsx`, `PushSection.tsx`), names concrete failure modes with where-caught/what-user-sees, and ties each test to a real risk. The PrimeTime parity-vs-regression tension is correctly resolved (keep it, flag placement). Remaining issues are wording accuracy and a section order that's deferred to design rather than read now — both non-blocking.

## Must Fix
None.

## Should Consider
- **`id="ai-agents"` is described as preserved, but it does not exist in the baseline.** The plan says "keep `id="ai-agents"` for anchors" and the test "assert the `ai-agents` anchor remains" — current `AgentTokensSection.tsx:161` renders `<section>` with no id; the anchor exists only in `old-focal/client/src/pages/Integrations.tsx:582`. Intent (add the anchor to match old-focal) is right and the test is valid, but reframe "keep/remains" as "add" so the doer doesn't assume a baseline that isn't there.
- **Provisional section order diverges from old-focal's actual render order.** Plan proposes Google → Push → AI agents → Backup → iCal → Prime time → Delete account, but `IntegrationsPage` actually renders Google → Push (1645) → Backup (1648) → iCal (1715) → AI agents (1777, `id="ai-agents"`) → dashed placeholder (1780) → Delete account (1792). The plan subordinates this to the design reviewer ("unless the design reviewer cites a specific old-focal mismatch"), consistent with the think doc's "settle at design gate", so it's acceptable — but the real order is now documented above for the design step.
- **old-focal's `border-dashed` "more coming" card (Integrations.tsx:1780) is unmentioned.** Not required for a behavior-preserving re-skin, but it's part of literal visual parity; flag for the design gate to accept or include.

## Tests Reviewed
N/A (plan step — no tests run). Inspected the existing test baseline the plan builds on: `SettingsPage.test.tsx` (prime-time/backup/iCal/delete-account coverage confirmed), `AppShell.test.tsx` (no settings-nav assertions today, so the plan's nav-item tests are net-new), `GoogleCalendarSection.test.tsx`, `PushSection.test.tsx`, `AgentTokensSection.test.tsx` exist; `App.test.tsx` correctly marked `add` (absent). Verified plan's factual anchors: `getGoogleAvailable()===false` → `null` (GoogleCalendarSection.tsx:140), HTTPS webhook gate before API (AgentTokensSection.tsx:148–156), `/settings` client deep-links bounded to App.tsx:63 + AppSidebar.tsx:102, Wouter ^3.10 supports the redirect.

## Release Risk
Low
