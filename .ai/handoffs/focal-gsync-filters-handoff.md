# Stage

Gate 7 (ship) — sub-slice ② **b** (custom sync filter) of the `focal-parity` epic's slice 10
(advanced Google Calendar sync). Stacked branch `feat/focal-gsync-filters` → base
`feat/focal-gsync-settings` (sub-slice ②a, PR #110). **Frontend-only — no server / API / schema /
migration change.**

# What changed

Adds old-focal's **custom sync filter** to the main-calendar Google section. The mode picker gains a
`custom` option; choosing it reveals a filter panel, wired to the already-migrated backend via the
existing `api/integrations.ts` (the `SyncSettings` fields `projectType` / `timeType` /
`selectedSpheres` / `selectedProjects` / `selectedProducts` already exist). This completes the
direction/mode/custom-filter trio; the inbound/outbound/notification option toggles are sub-slice ③.

- **`MODE_OPTIONS`** gains `custom`.
- **Custom panel** (shown when `settings.data.syncMode === 'custom'`):
  - **Project type** Select — `all` / `mission` / `provision`.
  - **Time** Select — `all` / `work` / `personal`.
  - **Spheres / Projects / Products** — three reused `MultiSelect` lists. Options come from
    `listSpheres()` and `listProjects()`; **products are split out of the projects tree** by
    `parentProjectId` (top-level rows → projects, rows with a parent → products), so no new endpoint
    is needed. Each list is rendered only when it has entries (old-focal parity).
- **One `customFilterMutation`** patches whichever field changed (`updateSyncSettings`) and
  invalidates the settings query; its failure joins the shared `role="alert"` action error.
- The sphere/project queries are **gated** (`enabled`) on the custom mode, so nothing is fetched
  until the user opts into custom.
- **i18n** — `focal.calendars.google.*` keys added in ru + en (modes.custom, projectTypeLabel,
  projectTypes.*, timeTypeLabel, timeTypes.*, spheresLabel/projectsLabel/productsLabel,
  *Placeholder, filterSearch/filterEmpty/filterClear); RU labels match old-focal verbatim.

# Files touched

- `apps/focal/client/src/features/calendars/MainCalendarGoogleSection.tsx`
- `apps/focal/client/src/features/calendars/MainCalendarGoogleSection.test.tsx`
- `apps/focal/client/src/i18n/locales/en.json`, `ru.json`

# Tests run

```sh
cd superapp-gsync/apps/focal/client
pnpm typecheck   # tsc -b: 0 errors
pnpm lint        # biome: 310 files, 0 fixes
pnpm test:run    # 100 files, 1181 tests passed (18 in this component)
pnpm build       # production build ✓
```

# Still needs review

- **Frontend-only** — reuses the existing endpoints/typed client and the existing `MultiSelect`
  primitive; products derived client-side from the projects tree (no new endpoint).
- Coverage: custom-panel reveal (5 controls), hide-when-not-custom, the three option lists populated
  from the queries, the selected sphere/project/product rendered as badges (which also proves the
  parentProjectId products split). The `MultiSelect` / Radix-`Select` **popover-open** interaction is
  not click-tested (unreliable in happy-dom) — same documented limitation as ②a.
- Follow-ups: ③ option toggles (acceptFrom*/notify*/push*/reminder*); the pre-existing
  `focal.calendars.google.*` vs `focal.settings.google.*` i18n overlap (a separate settings-page
  section — future consolidation, not this slice).

# PR / release notes (for users)

When you set Google sync to **Custom**, you can now choose exactly what syncs: by project type
(mission / provision), by work vs. personal time, and by specific spheres, projects, and products —
matching the legacy Focal filter. Each choice saves immediately.

(No secrets, tokens, keys, or PII in this change — client components, locale strings, and tests.)

# Status

CLEARED FOR RELEASE — gates 4-7 passed (build/review 9.4 Opus · test 9.2→strengthened→APPROVED Opus ·
ship Opus). Neither review raised a Must-Fix; the test reviewer's top should-consider (no test drove
the projectType/timeType binding — a swapped binding would ship green) was closed by adding a binding
test, plus an empty-list parity test; re-ran green (typecheck · lint · 1181 vitest · build).
**Pipeline deviation:** GPT-Codex was live this session but its xhigh review kept overrunning under
parallel-session load and was stopped; the user chose to finish via fresh-context **Opus subagents**
(documented in `reviews/focal-gsync-filters/*-verdict.md`).
