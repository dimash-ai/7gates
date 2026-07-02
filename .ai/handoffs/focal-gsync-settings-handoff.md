# Stage

Gate 7 (ship) — sub-slice ② **a** (sync settings core) of the `focal-parity` epic's slice 10
(advanced Google Calendar sync). Stacked branch `feat/focal-gsync-settings` → base
`feat/focal-gsync-connection` (sub-slice ①, PR #108). **Frontend-only — no server / API / schema /
migration change.**

# What changed

Extends the main-calendar Google section (added in ①) with the **two-way-sync controls**, wired to
the already-migrated backend via the existing typed `api/integrations.ts`. The custom-filter panel
(②b) and the inbound/outbound/notification option toggles (③) are later sub-slices and intentionally
not here.

- **Sync direction** Select — `focal_to_google` / `google_to_focal` / `bidirectional` →
  `updateSyncSettings({ syncDirection })`.
- **What-to-sync (mode)** Select — `off` / `all` / `work_only` → `updateSyncSettings({ syncMode })`.
  (`custom` is a valid backend value but is deliberately deferred to ②b's filter panel; the picker
  shows its placeholder for an already-`custom` persisted value rather than mis-mapping it.)
- **Sync now** button — `runGoogleSync()`; on success renders a result summary ("Synced: N imported,
  …") or "Already up to date" when the four counts sum to zero. Spinner while pending.
- **Last synced** line — localized date via `toLocaleString(i18n.language)`, shown when `lastSyncAt`
  is set.
- **Delete imported events** button — shown only when direction ≠ `focal_to_google` →
  `deleteImportedEvents()`.
- **Error handling** — the settings-backed pickers (interval/direction/mode) now share **one**
  consolidated load-error row when the settings query fails (was three identical rows); every
  mutation failure surfaces the shared `role="alert"` action error.
- **i18n** — `focal.calendars.google.*` keys added in ru + en (directionLabel, directions.*,
  modeLabel, modePlaceholder, modes.*, syncNow, syncNoChanges, syncResult, deleteImported, lastSync),
  full key + interpolation parity.

# Files touched

- `apps/focal/client/src/features/calendars/MainCalendarGoogleSection.tsx`
- `apps/focal/client/src/features/calendars/MainCalendarGoogleSection.test.tsx`
- `apps/focal/client/src/i18n/locales/en.json`, `ru.json`

# Tests run

```sh
cd superapp-gsync/apps/focal/client
pnpm typecheck   # tsc -b: 0 errors
pnpm lint        # biome: 310 files, 0 fixes
pnpm test:run    # 100 files, 1176 tests passed
pnpm build       # production build ✓
```

# Still needs review

- **Frontend-only** — reuses the existing `/api/integrations/google/*` endpoints and typed client.
- Non-blocking follow-ups (carried to ②b / backfill): `custom` mode + its filter panel (②b); whether
  "Sync now" should also disable on `settings.isError`; pre-existing `focal.calendars.google.*` vs
  `focal.settings.google.*` i18n overlap (separate settings-page section — a future consolidation).
  Radix Select `onValueChange` selection is not interaction-tested (unreliable in happy-dom); the
  selects' presence/labels, the buttons' click→mutation wiring, the result summary (incl. the
  `sum === 0` branch), the last-sync show/hide, the delete-imported show/hide, and the error states
  are covered (13 tests in the file).
- **Pipeline deviation:** GPT-Codex was unavailable this session — it hit the ChatGPT usage limit
  (`codex exec` → "You've hit your usage limit … try again at 6:33 PM"), not merely slow. Gates 4/5
  (build + holistic review) and 6 (test) were performed by fresh-context **Opus subagents** —
  documented in `reviews/focal-gsync-settings/*-verdict.md`. Re-attempt Codex once credits reset for
  any later sub-slice.

# PR / release notes (for users)

Your main calendar's Google sync now has full **two-way controls**: choose the sync direction
(Focal → Google, Google → Focal, or both ways), pick what to sync (everything, work events only, or
nothing), run a **manual sync on demand** with a clear summary of what changed (or "Already up to
date"), see when it last synced, and remove previously imported Google events. Failed actions and a
settings-load failure now show a single clear, localized message instead of silent no-ops.

(No secrets, tokens, keys, or PII in this change — client components, locale strings, and tests.)

# Status

CLEARED FOR RELEASE — gates 4-7 passed (build/review 9.3 Opus · test 8.5→resolved→APPROVED Opus ·
ship Opus). The test gate's sole Must-Fix (untested `sum === 0` "already up to date" branch) was
fixed by adding a dedicated test, plus two strengthenings (assert the interpolated count; lock the
null-`lastSyncAt` absence); re-ran green (typecheck · lint · 1176 vitest · build). GPT-Codex was
unavailable (usage limit) → Opus subagents reviewed.
