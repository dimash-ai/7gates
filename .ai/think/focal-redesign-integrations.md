# Problem

The `focal-redesign-integrations` slice must bring the new app's settings/integrations surface to
**exact visual parity with old-focal's `Integrations.tsx`**, per the epic's binding contract (exact
old-focal). Two facts shape it:

1. **Content already matches — this is a re-skin, not a rebuild.** old-focal's `Integrations.tsx`
   (1,819 lines) is a catch-all: `PushNotificationsCard`, `AiAgentTokensCard` (the `foc_` agent API
   with scopes `events:read`/`tasks:read`/`tasks:write`/`goals:read`/`budgets:read`),
   `DeleteAccountCard`, and `IntegrationsPage` itself (Google connect/calendars/sync-settings/
   import/delete-imported, Backup export/import, iCal import/export). The **new app already composes
   all of this** on its `/settings` page (`SettingsPage.tsx` → `PrimeTimeSection`,
   `GoogleCalendarSection`, `PushSection`, `AgentTokensSection`, `BackupSection`, `IcalSection`,
   account-delete via `api/account`), wired to existing `api/{integrations,push,agentTokens,backup,
   ical,account,settings}.ts`. So the work is presentation, not data/logic.

2. **The route/nav identity diverges — and the user chose to match old-focal.** old-focal = a
   `/integrations` route, nav «Интеграции»; the new app named it `/settings` («Настройки»). **User
   decision (2026-06-23): rename `/settings` → `/integrations` + nav «Интеграции», with a `/settings`
   redirect**, in addition to the re-skin.

The risk to manage is **scope discipline on a catch-all page**: keep it a re-skin + a route rename;
don't drift into reworking the Google-sync/token/backup *behavior*, and don't silently drop the one
section that has no old-focal-Integrations equivalent (`PrimeTimeSection`).

# Assumptions

- **[confirmed — user]** Scope = re-skin to old-focal `Integrations.tsx` **and** rename route/nav to
  `/integrations` / «Интеграции» with a `/settings` redirect.
- **[confirmed — fs]** The new `/settings` page composes all old-focal Integrations content:
  `SettingsPage.tsx` imports/renders `PrimeTimeSection` (l.55), `GoogleCalendarSection`,
  `PushSection`, `AgentTokensSection`, `BackupSection` (l.226), `IcalSection` (l.373), and
  `deleteAccount` (`api/account`). → content parity; no new feature work.
- **[confirmed — fs]** old-focal's visual contract = `pages/Integrations.tsx` + `components/
  GoogleCalendarSync.tsx` + `GoogleCalendarSyncAdvanced.tsx`; its look is the slice-0 tokens already
  ported into the new `index.css`.
- **[confirmed — fs]** APIs are all present + wired (`api/integrations.ts` — Google status/calendars/
  select/sync-settings/run/import/delete/convert/disconnect; `push.ts`, `agentTokens.ts`, `backup.ts`,
  `ical.ts`, `account.ts`, `settings.ts`). → **re-skin over existing endpoints; no API change.**
- **[confirmed — repo CLAUDE.md]** reproduce in **Tailwind 4 / shadcn** (no Tailwind-3 config /
  PostCSS); React 19; Wouter routing in `App.tsx`; i18next `ru`+`en`.
- **[confirmed — fs]** Routing today: `App.tsx` maps `/settings` → `SettingsPage`; the sidebar item is
  `{ key:'settings', href:'/settings', icon: Settings }` in `AppSidebar.tsx`. Renaming = add the
  `/integrations` route, repoint the nav item (label «Интеграции», likely the lucide `Plug` icon to
  match old-focal), and add a `/settings`→`/integrations` redirect.
- **[divergence — flag, do not silently drop]** `PrimeTimeSection` is on the new `/settings` but is
  **not** on old-focal's Integrations page (old-focal edits prime time via a `PrimeTimeDialog` opened
  from the calendar). Removing it here would orphan the only prime-time editor in the new app → a
  behavior regression. Default: **keep it**; relocation is a separate decision (open question).
- **[unverified — settle at design gate]** old-focal's exact section order + card chrome; whether the
  page uses tabs or a single scroll (old-focal = single scrolling page with `id` anchors, e.g.
  `#ai-agents`); the precise nav icon; whether the AI-assistant top-bar button appears on this page.

# Options considered

The route-identity fork (rename vs keep `/settings`) was **put to the user → "match old-focal:
/integrations + «Интеграции»"**. The remaining real fork is **how to apply the re-skin**:

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Re-skin in place + rename (chosen)** | Restyle the existing `SettingsPage` + its sections to old-focal's look; add `/integrations` route + redirect + nav repoint. | True re-skin; keeps all working API wiring, tests, and section logic; surgical; matches every other slice's shape. | Must touch routing + nav + their tests (slightly beyond a pure visual diff — but user-approved). |
| **B — Rebuild the page from old-focal wholesale** | Port old-focal `Integrations.tsx` structure/code directly. | Maximal literal fidelity. | Drags in old-focal's `apiRequest`/`fetchWithAuth` + Tailwind-3 patterns + its own state mgmt — the **wrong data layer** and a **banned toolchain**; throws away tested sections. **Rejected.** |

# Recommendation

**Option A.** Re-skin the existing `SettingsPage.tsx` + its six sections to old-focal
`Integrations.tsx`'s exact visual language (page header «Интеграции» + icon, single scrolling
card layout in old-focal's order, section/card chrome, the Google connect/sync UI styling), driven
by the slice-0 tokens. Rename the route `/settings` → `/integrations` (add the route, redirect the
old path), and repoint the `AppSidebar` nav item to «Интеграции» (`/integrations`, lucide `Plug`).
**Keep every existing API call, section behavior, and test green** — change only markup/classes +
the route/nav identity + i18n copy. Reproduce old-focal's look in Tailwind 4. Keep `PrimeTimeSection`
(removing it regresses prime-time editing) and flag its placement for a later decision.

**Build sub-steps (settled at the design gate):** (1) page shell + header + section ordering; (2)
per-section card re-skin (Google, Push, AI-tokens, Backup, iCal, Delete-account, Prime-time); (3)
route rename + redirect + nav; (4) i18n + tests.

# Out of scope

- Any **server / API / schema / contract** change — frontend-only over existing endpoints.
- **Behavior / logic** changes to Google sync, push, token CRUD, backup, iCal, or delete-account.
- The **`/calendars` `GoogleSyncPanel`** (calendars slice) and shell nav changes beyond this item.
- **Dropping `PrimeTimeSection`** without a relocation plan (default: keep).
- Porting old-focal's stack verbatim (Option B).

# Open questions

- **`PrimeTimeSection`** — keep on `/integrations` (default, no regression), or relocate to match
  old-focal (prime-time lived in a calendar dialog)? Settle at the design gate; if relocated, that's
  a separate slice, not this one.
- **Section order + page chrome** — confirm old-focal's exact order and whether anchors (`#ai-agents`)
  / the AI top-bar button are reproduced. Settle at the design gate.
- **Redirect mechanism** — Wouter `<Redirect>` from `/settings`; confirm no other code deep-links
  `/settings` (grep at build).

# Success criteria

- [ ] `/integrations` matches old-focal `Integrations.tsx` in **light + dark** (screenshot parity),
      reproduced on Tailwind 4 / shadcn.
- [ ] Sidebar shows «Интеграции» → `/integrations`; `/settings` redirects there; no dead links.
- [ ] All flows preserved (Google connect/disconnect/select/sync/import, push, token CRUD, backup,
      iCal, delete account) — **no API change**; existing section tests pass (updated for the route).
- [ ] No hardcoded strings (i18next `ru`+`en`); surgical diff tracing to the task; `pnpm lint &&
      pnpm typecheck && pnpm test:run && pnpm build` green.
