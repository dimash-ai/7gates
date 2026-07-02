# Review Verdict

Reviewer: Opus subagent (fresh context) — GPT Codex unavailable this session (ChatGPT usage limit hit; `codex exec` returned "You've hit your usage limit … try again at 6:33 PM")
Step: build (+ holistic review — gate 5 folded in; the review was holistic for this small frontend slice)
Score: 9.3 / 10
Status: APPROVED

## Reason
Correct, surgical, well-scoped sub-slice 2a. TanStack Query v5 mutation/invalidation usage, the `sum === 0` "no changes" branch, the delete-imported visibility guard (`settings.data && settings.data.syncDirection !== 'focal_to_google'`), and the shared `role="alert"` action-error / consolidated settings load-error rows are all sound. i18n has full ru/en key + interpolation parity (`{{date}}`, `{{imported|exported|updated|deleted}}` match across locales) with no hardcoded user-facing strings. No spec IDs, no AI attribution, no `any` (casts are to the API union types). Scope matches 2a exactly — `custom` mode is deliberately deferred to the later custom-filter sub-slice.

## Must Fix
None

## Should Consider
- `MainCalendarGoogleSection.tsx` mode Select: `MODE_OPTIONS` omits `custom` (a valid backend `SyncMode`). A user whose persisted `syncMode` is already `custom` sees the placeholder rather than a matched item — safer than mis-mapping (a save would clobber the custom config), and the custom-filter panel is a later sub-slice. Carry as a known follow-up.
- "Sync now" renders outside the settings load-error guard, so it stays clickable if the settings query failed. Arguably intentional (`runGoogleSync()` needs no settings); consider disabling on `settings.isError` for tidiness.
- Pre-existing i18n drift: `focal.calendars.google.*` (this feature) overlaps `focal.settings.google.*` (separate settings-page section) with slightly different wording. Out of scope for 2a; a future consolidation pass would cut drift. Flag only — do not touch here.

## Tests Reviewed
`git diff feat/focal-gsync-connection -- apps/focal/client`; read the full component, `api/integrations.ts`, and both locale files. Did not rerun pnpm checks in read-only review (build side ran them: typecheck/lint/1176 vitest/build all green).

## Release Risk
Low
