# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 7.0 / 10
Status: BLOCKED

(build-slice 5 — continuous voice + voice navigation, first pass)

## Reason
The slice is client-only and covers most intended wiring, but it violates the core recognition lifecycle contract and the i18n hard constraint, and has a non-reactive calendar-active derivation. Static review only — codex could not run the focused Vitest suite (read-only sandbox `EPERM` on a repo-root temp file); doer-reported local green: typecheck/lint/test:run = 1377.

## Must Fix
- `VoiceControl.tsx` `startSession`: toggling continuous mode on while a single-shot session is already listening aborts the active recognizer and immediately starts a new one without waiting for the old `onend`/audio-stack release, overlapping two live Web Speech sessions — violates "exactly one live recognition session." (The continuous *restart* path already waits `CONTINUOUS_RESTART_DELAY_MS` for exactly this reason.)
- `VoiceControl.tsx:55`: `isCalendarActive` is computed from `getCalendarNav()`, which reads a **ref** mutated by `AIAssistantContext.registerCalendarNav` with no setState — navigating into/out of the calendar while the voice panel is open never re-renders, so nav example chips can show off-calendar or stay hidden on-calendar. (Routing is correct — live-read — so display-only, but wrong.)
- `VoiceControl.tsx:299`: creation example phrases are hardcoded and rendered to users; free-form creation examples (unlike the parser-coupled nav `commandExamples` approved in B1) fall under the i18n hard rule and must live in both locale files.

## Should Consider
- `VoiceControl.tsx:236`: a continuous-mode start failure (unsupported/offline/catch) leaves the continuous switch enabled though no session is running.

## Tests Reviewed
Inspected latest-commit diff/stat, full touched files, context speech/navigation/provider files, and the old-focal VoiceControl reference. Attempted a focused Vitest run; blocked by sandbox `EPERM`.

## Release Risk
Medium

---

**Disposition:** All three Must-Fix confirmed against source (race in `startSession`; ref-backed `registerCalendarNav` in `AIAssistantContext.tsx:95-104`; hardcoded `creationExamples`). Fixes dispatched: defer start-over-live through the release delay; reactive `isCalendarActive` state in the context; move creation examples to i18n via the existing `localizedList` guard; reset the toggle on continuous start failure. Re-review tracked in `B-build-verdict-9.md`.
