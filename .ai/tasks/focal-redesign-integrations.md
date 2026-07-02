# Goal

Bring the new Focal app's settings/integrations surface to **exact visual parity with old-focal's
`Integrations.tsx`**, and **rename the route `/settings` → `/integrations`** (nav label
«Интеграции», with a `/settings` redirect) so the page identity matches old-focal too. A slice of
the `focal-redesign-pages` epic ([think](../think/focal-redesign-pages.md)); binding contract =
`apps/old-focal`.

> **Binding visual contract** = `superapp/apps/old-focal/client/src/pages/Integrations.tsx` (1,819
> lines) + the Google components it composes (`components/GoogleCalendarSync.tsx`,
> `GoogleCalendarSyncAdvanced.tsx`), `index.css` light+dark tokens. **The thing changed** =
> `superapp/apps/focal/client/src/features/settings/*` (its `SettingsPage.tsx` +
> `GoogleCalendarSection` / `PushSection` / `AgentTokensSection` and the inline `PrimeTimeSection` /
> `BackupSection` / `IcalSection` / account-delete) + the route + the sidebar nav item.

> **Re-skin, not rebuild.** The new `/settings` page already composes **all** of old-focal
> Integrations' content (Google connect/calendars/sync-settings/import, Push, AI agent tokens,
> Backup, iCal, Delete account), wired to the existing `api/{integrations,push,agentTokens,backup,
> ical,account,settings}.ts`. This slice changes **presentation + the route/nav identity only** —
> not the data layer or behavior. Reproduce old-focal's look in **Tailwind 4 / shadcn** (no
> Tailwind-3 config / PostCSS); strings via i18next (`ru` + `en`); light + dark.

# Scope

- Re-skin `features/settings/SettingsPage.tsx` and its sections to old-focal `Integrations.tsx`:
  page header («Интеграции» + icon), card layout/order/spacing, section headers, the Google
  connect/disconnect + calendar-select + sync-settings UI, Push, AI-agent-tokens, Backup, iCal,
  Delete-account — matching old-focal's exact visual language via the slice-0 tokens.
- **Route rename:** add `/integrations` (rendering the page), update the nav item in `AppSidebar.tsx`
  (key/href/label «Интеграции»/icon), and add a `/settings` → `/integrations` redirect so old links
  resolve.
- Update the affected i18n keys (`ru` + `en`) to old-focal's copy; update existing
  `features/settings/*.test.tsx` + any route/nav test to the new path/label.

# Out of scope

- **Any server / API / schema / contract change** — frontend-only re-skin over existing endpoints.
- **Behavior / logic changes** — Google OAuth/sync, push, token CRUD, backup, iCal, delete-account
  flows are preserved as-is.
- The **`/calendars` `GoogleSyncPanel`** (that's the calendars slice) and the broader shell nav
  reconciliation beyond this one item.
- **Removing the `PrimeTimeSection`** (it's on the new `/settings` but not on old-focal's
  Integrations page) **without a relocation plan** — see Open questions in the think doc; default is
  keep it (removing the only prime-time editor would regress behavior).

# Acceptance criteria

- [ ] `/integrations` renders the page matching old-focal `Integrations.tsx` in **light + dark**
      (screenshot parity), reproduced on Tailwind 4 / shadcn.
- [ ] Sidebar shows «Интеграции» linking to `/integrations`; `/settings` redirects to `/integrations`.
- [ ] All existing flows still work (Google connect/disconnect/select/sync, push, token CRUD,
      backup export/import, iCal import/export, delete account) — no API change.
- [ ] No hardcoded strings (i18next `ru` + `en`); surgical diff tracing to this task.
- [ ] Green: `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`.

# Verification commands

```sh
cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-integrations/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```
