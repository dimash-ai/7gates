# Stage

Gate 7 (ship) — sub-slice ③ (request/notification option toggles) of the `focal-parity` epic's slice
10 (advanced Google Calendar sync). **This completes slice 10.** Stacked branch
`feat/focal-gsync-options` → base `feat/focal-gsync-filters` (sub-slice ②b, PR #112).
**Frontend-only — no server / API / schema / migration change.**

# What changed

Adds old-focal's three **direction-gated** request/notification toggle sections to the main-calendar
Google sync settings, wired to the existing typed client (the 10 boolean `SyncSettings` fields already
exist). With this, the new main-calendar Google section reaches functional parity with old-focal's
`GoogleCalendarSyncAdvanced` (connection · calendar · interval · direction · mode · custom filter ·
manual sync · these toggles).

- **Incoming requests** (shown when direction is `google_to_focal` or `bidirectional`):
  acceptFromObservers, acceptFromExternal, acceptRequestCreate, acceptRequestUpdate,
  acceptRequestDelete — under "Accept from" / "Which requests" sub-labels.
- **Responses to participants** (shown only when `bidirectional`): notifyOnAccept, notifyOnDecline,
  notifyOnReschedule.
- **Notifications for me** (shown when `google_to_focal` or `bidirectional`): pushOnNewRequest,
  reminderUnprocessed.
- Each toggle is a shadcn **`Switch`** rendered by a `renderToggle(field)` helper (label+switch row),
  persisting via the existing mutation — **renamed `customFilterMutation` → `settingsMutation`** since
  it now patches the toggles as well as the filter; its failure joins the shared `role="alert"`.
- The 10 fields and their i18n label keys live in a `TOGGLE_LABELS` map typed by a `ToggleField` union.
- **i18n** — `focal.calendars.google.*` keys added in ru + en (5 section/sub-headers + 10 toggle
  labels), RU labels match old-focal verbatim.

# Files touched

- `apps/focal/client/src/features/calendars/MainCalendarGoogleSection.tsx`
- `apps/focal/client/src/features/calendars/MainCalendarGoogleSection.test.tsx`
- `apps/focal/client/src/i18n/locales/en.json`, `ru.json`

# Tests run

```sh
cd superapp-gsync/apps/focal/client
pnpm typecheck   # tsc -b: 0 errors
pnpm lint        # biome: 310 files, 0 fixes
pnpm test:run    # 100 files, 1187 tests passed (24 in this component)
pnpm build       # production build ✓
```

# Still needs review

- **Frontend-only** — reuses the existing endpoint/typed client and the existing `Switch`/`Label`
  primitives; the rename is behavior-neutral for the ②b filter call sites (byte-identical payloads).
- Coverage: all three direction cases (bidirectional → 3 sections, google_to_focal → no responses,
  focal_to_google → none, the last awaiting the loaded direction), toggle persistence (exact field +
  flipped value), checked-state reflection (catches a swapped binding), and a toggle-failure →
  shared-alert test. **The `Switch` is fully testable in happy-dom** (unlike the Radix Select /
  MultiSelect popovers), so persistence is covered directly.
- Deferred (parity polish, not behavior): old-focal's per-toggle help tooltips (`*Tooltip` keys) and
  section icons are intentionally omitted, matching the re-skin's leaner styling.
- **Pipeline deviation:** GPT-Codex was live but its xhigh review kept overrunning under
  parallel-session load and was stopped; gates 4/5/6 were performed by fresh-context **Opus
  subagents** (documented in `reviews/focal-gsync-options/*-verdict.md`).

# PR / release notes (for users)

Your main calendar's Google sync settings now include the **request and notification controls** from
the legacy app. Depending on your sync direction you can choose which incoming requests to accept
(from observers / external participants; create / update / delete), whether to notify participants
when you accept, decline, or reschedule, and how you're notified of new and unhandled requests. Each
switch saves immediately, and the options shown match your chosen sync direction.

(No secrets, tokens, keys, or PII in this change — client components, locale strings, and tests.)

# Status

CLEARED FOR RELEASE — gates 4-7 passed (build/review 9.5 Opus · test 9.4→strengthened→APPROVED Opus ·
ship Opus). Neither review raised a Must-Fix; the test reviewer's top should-consider (no test proved
a toggle failure feeds the shared alert — the path the rename touched) was closed by adding a
toggle-failure test; re-ran green (typecheck · lint · 1187 vitest · build). GPT-Codex review runs
overran under load → Opus subagents reviewed.
