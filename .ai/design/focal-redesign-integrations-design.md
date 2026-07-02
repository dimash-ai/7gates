# Design summary

Re-skin the new app's existing `features/settings` surface **in place** to old-focal
`Integrations.tsx`'s visual language, and change the page **identity** to `/integrations`
(«Интеграции»). Two decisions everything hinges on:

1. **Presentation + identity only.** Keep every existing data path — `features/settings` section
   components, their React Query keys, mutations, and the `api/{integrations,push,agentTokens,backup,
   ical,account,settings}.ts` wrappers — untouched. The diff changes markup/classes, the route, the
   nav item, and i18n copy. No backend/API/schema/dependency change. (Traces to think §"re-skin not
   rebuild" + plan §Summary.)
2. **Follow old-focal's real section order, with two documented deltas.** old-focal `IntegrationsPage`
   renders (verified, plan-review verdict): **Google → Push (1645) → Backup (1648) → iCal (1715) →
   AI-agents `#ai-agents` (1777) → dashed "more coming" placeholder (1780) → Delete account (1792)**.
   This design adopts that order, and: **(a)** inserts the additive `PrimeTimeSection` in the slot
   old-focal fills with the dashed placeholder (between AI-agents and Delete-account), so Delete stays
   last and old-focal's six real sections keep their exact relative order; **(b)** **omits** the
   dashed "more coming" placeholder (non-functional decoration that would imply integrations the app
   doesn't have — Simplicity First); **(c)** **adds** `id="ai-agents"` to the AI-agents card (it does
   not exist in the new baseline — `AgentTokensSection.tsx:161` has no id — only in old-focal).

This resolves the gate-1 Should-Consider (PrimeTime parity-vs-regression: keep it, accept it as a
documented additive section, judge screenshot parity on the six old-focal sections) and the gate-2
Should-Considers (exact order; "add" not "keep" the anchor; the placeholder card).

# Architecture

Frontend-only; presentation + routing layer. No new module or shared layer — reuse existing shadcn
primitives (`Card`, `Button`, `Badge`, `Input`, `Label`, `Select`, `Switch`/`Checkbox`).

```
App.tsx (wouter Switch)
  ├─ Route "/integrations"  → <SettingsPage/>        (new primary identity)
  ├─ Route "/settings"      → <Redirect to="/integrations" + search + hash>   (legacy alias)
  └─ … unchanged routes (/ → /tasks, etc.)

AppSidebar.tsx  SECTIONS[settings group]
  └─ item { key:'integrations', href:'/integrations', icon: Plug }   (was settings/Settings)

features/settings/  (folder + export names UNCHANGED — identity is the route, not the folder)
  SettingsPage.tsx           page frame + header «Интеграции»; renders sections in old-focal order
   ├─ GoogleCalendarSection  re-skin → old-focal GoogleCalendarSync(.Advanced) chrome
   ├─ PushSection            re-skin → old-focal PushNotificationsCard chrome
   ├─ BackupSection          re-skin → old-focal backup card
   ├─ IcalSection            re-skin → old-focal iCal card
   ├─ AgentTokensSection     re-skin → old-focal AiAgentTokensCard chrome; ADD id="ai-agents"
   ├─ PrimeTimeSection       re-skin (additive; kept to avoid regressing the only prime-time editor)
   └─ DeleteAccountSection   re-skin → old-focal DeleteAccountCard (destructive, last)

i18n/locales/{ru,en}.json    add focal.app.nav.integrations; retitle page to «Интеграции»;
                             section copy stays in the focal.settings.* namespace (minimal churn)
```

Coupling: each section stays self-contained (section-local state + its own query/mutations); the page
only orders them. The route/nav edit is isolated to `App.tsx` + `AppSidebar.tsx`.

# Data model

| entity | change | notes |
|--------|--------|-------|
| — | **None** | No tables/columns/migrations. No persistent state added or changed; this is a presentation + client-route change only. |

# Interfaces & contracts

No new or changed server endpoints, API wrappers, or exported component signatures. The contracts
this slice establishes/preserves:

- **Route:** `GET /integrations` (client route) renders the page; `GET /settings` issues a client
  redirect to `/integrations` **preserving `location.search` and `location.hash`** (so
  `/settings#ai-agents` → `/integrations#ai-agents`, and any `?…` callback params survive).
- **Nav:** sidebar exposes exactly one item for this surface — key `integrations`, href
  `/integrations`, label `t('focal.app.nav.integrations')`. The old `settings` item is gone (not
  duplicated).
- **Anchor:** `#ai-agents` resolves to the AI-agents card (`id="ai-agents"`), matching old-focal's
  deep link.
- **Unchanged (must not alter):** every `api/*` call + React Query key + mutation + invalidation in
  the five section components; the OAuth begin URL builder; the one-shot token/iCal/webhook reveal
  semantics; the HTTPS-only webhook guard; the delete-account confirm-word gate.

# Flow (happy + unhappy paths)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy | click «Интеграции» in sidebar | `App.tsx` route `/integrations` | page renders all sections in old-focal order, old-focal look, light+dark |
| legacy alias | navigate `/settings` (old link / PWA shortcut / bookmark) | `App.tsx` `<Redirect>` | lands on `/integrations`, search+hash preserved; no loop (only `/settings`→`/integrations`) |
| deep link | `/integrations#ai-agents` (or `/settings#ai-agents`) | `id="ai-agents"` on the AI-agents card | scrolls to AI-agents section |
| Google unavailable | `getGoogleAvailable() === false` | `GoogleCalendarSection` | renders `null` — **no empty card** (unchanged behavior) |
| section query error | Google/push/settings query fails | each section (existing branches) | section-local alert/notice; rest of page unaffected |
| token create | submit create-token form | `AgentTokensSection` (unchanged) | one-shot secret panel shown **once**; dismissed if its token is revoked |
| webhook save | non-HTTPS URL entered | `AgentTokensSection` (unchanged) | rejected **before** the API call (SSRF-ish guard preserved) |
| backup/iCal import | invalid file chosen | Backup/Ical sections (unchanged) | localized error notice; same-file re-pick still fires (input value reset) |
| delete account | click delete | `DeleteAccountSection` (unchanged) | confirm-word gate → `deleteAccount()` → `signOut()`; card stays last + destructive |
| i18n miss | missing key after copy edits | `pnpm build` (JSON) + component tests | caught pre-merge; user never sees raw `focal.*` keys |

# Alternatives rejected

- **Wholesale port of old-focal `Integrations.tsx`** — drags in old-focal's Tailwind-3 patterns,
  `apiRequest`/`fetchWithAuth`, toast system, and its own state; the **wrong data layer** + a banned
  toolchain; discards tested sections. (think Option B.)
- **Rename the folder to `features/integrations`** — pure churn across imports/tests; the user-facing
  identity is the **route/nav**, not the folder name. Keep `features/settings`.
- **Drop `PrimeTimeSection` for literal old-focal parity** — it's the only prime-time editor in the
  new app; removing it regresses behavior. Keep it as a documented additive section.
- **Reproduce old-focal's dashed "more coming" placeholder card** — non-functional decoration that
  advertises integrations the app doesn't have; omit (Simplicity First).
- **Keep two live routes (`/settings` and `/integrations`)** — duplicate identity; use a redirect so
  there is one canonical page.

# Test strategy

Vitest + @testing-library/react (jsdom), **behavior-first** (accessible queries, not class
snapshots) — markup changes must not break behavior coverage. Levels & what each proves:

- **Route (`App.test.tsx`, new):** `/integrations` renders the page; `/settings` redirects to it
  preserving query/hash; an unknown route still hits `NotFoundPage` (the inserted route doesn't
  swallow the catch-all).
- **Nav (`AppShell.test.tsx`):** sidebar shows the «Интеграции» item → `/integrations`; the old
  settings nav item is gone; existing shell behavior (dashboard gating, meeting badge, sign-out)
  unchanged.
- **Page (`SettingsPage.test.tsx`):** header renders «Интеграции» title/subtitle; sections render in
  the designed order incl. retained PrimeTime and final Delete-account; existing prime-time / backup /
  iCal / delete-account behavior assertions stay green after the card move.
- **Sections (`Google/Push/AgentTokens` tests):** every existing API call / mutation / status branch
  still fires after the re-skin (connect/select/sync/disconnect; subscribe/unsubscribe/test; token
  create one-shot reveal / revoke / HTTPS webhook gate / iCal); the `#ai-agents` anchor is present.

"Verified" before ship = `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green **and**
manual light/dark, desktop/mobile screenshot comparison of `/integrations` against old-focal
`Integrations.tsx` + `GoogleCalendarSync*.tsx` (header, card width/spacing, icon squares, badges,
muted/warning panels, destructive card, mobile wrapping). Full per-file test list lives in the plan.

# Security & release notes

- **Secrets:** the one-shot token / iCal / webhook reveal panels stay show-once and are dismissed on
  revoke — no secret persisted to state beyond its panel, none logged, none added to i18n. (Preserved,
  not changed.)
- **SSRF-ish guard:** the webhook editor's HTTPS-only rejection **before** the API call is preserved.
- **Authz:** none added; delete-account keeps its confirm-word gate; no new endpoints/surfaces.
- **Release:** client-only. No migration, no server change, no dependency/lockfile change. The
  `/settings`→`/integrations` redirect keeps old links, bookmarks, and PWA shortcuts working.
  **Rollback** = revert the listed frontend files (no schema/server state to undo).
