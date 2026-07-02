# Summary

Re-skin the existing new-Focal settings surface in place so the shipped page identity is
`/integrations` and the visible page matches old-focal's `Integrations.tsx` visual language. Keep
the current `features/settings` data flow, API wrappers, query keys, mutations, and tests as the
base; this slice changes presentation, route/nav identity, and i18n copy only.

Implementation should happen in `.worktrees/focal-redesign-integrations`. Paths below use the
canonical task paths (`superapp/apps/focal/...`); inside that worktree they map to `apps/focal/...`.
Do not rename the `features/settings` folder or move behavior into a new feature just to match the
route name.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/client/src/App.tsx` | modify | Add `/integrations`, redirect `/settings` to `/integrations`, and keep the page mounted inside the existing auth/app shell. Preserve search/hash in the redirect so old deep links and callback URLs do not lose context. |
| `superapp/apps/focal/client/src/components/AppSidebar.tsx` | modify | Replace the settings nav item with an integrations nav item: key `integrations`, href `/integrations`, label from i18n, and a plug/link-style lucide icon. Keep section grouping, dashboard gating, meeting badge, mobile-close behavior, and sign-out unchanged. |
| `superapp/apps/focal/client/src/features/settings/SettingsPage.tsx` | modify | Re-skin the page frame and inline sections (`PrimeTimeSection`, `BackupSection`, `IcalSection`, `DeleteAccountSection`) to old-focal card/header/spacing patterns while preserving their existing logic. Keep `PrimeTimeSection`, styled as a normal card, because removal would regress the only current prime-time editor. |
| `superapp/apps/focal/client/src/features/settings/GoogleCalendarSection.tsx` | modify | Re-skin the Google connection, calendar select, sync settings, sync/import/convert/delete actions, notices, loading/error states, and status badges against old-focal `GoogleCalendarSync*.tsx`; keep every API call and mutation outcome unchanged. |
| `superapp/apps/focal/client/src/features/settings/PushSection.tsx` | modify | Re-skin push notifications to old-focal card chrome, active/inactive status, device rows, test action, and unsupported/not-configured notices without changing browser Push API or backend calls. |
| `superapp/apps/focal/client/src/features/settings/AgentTokensSection.tsx` | modify | Re-skin AI-agent token creation, scope checkboxes, token/iCal/webhook one-shot reveal panels, token rows, inactive badge, inline confirmations, and webhook editor. Preserve token CRUD/iCal/webhook behavior and keep `id="ai-agents"` for anchors. |
| `superapp/apps/focal/client/src/i18n/locales/ru.json` | modify | Add `focal.app.nav.integrations`, update page title/subtitle and affected section copy to old-focal Russian text, and keep every displayed string localized. |
| `superapp/apps/focal/client/src/i18n/locales/en.json` | modify | Add the matching English keys/copy for every Russian key changed or added. |
| `superapp/apps/focal/client/src/App.test.tsx` | add | Prove `/integrations` renders the settings/integrations page and `/settings` redirects to it. |
| `superapp/apps/focal/client/src/components/AppShell.test.tsx` | modify | Prove the sidebar renders the integrations nav item, links to `/integrations`, and no longer exposes the old settings nav item. Keep existing shell behavior tests intact. |
| `superapp/apps/focal/client/src/features/settings/SettingsPage.test.tsx` | modify | Update page/header/section-order expectations for integrations copy and keep prime-time, backup, iCal, and delete-account behavior coverage green after the re-skin. |
| `superapp/apps/focal/client/src/features/settings/GoogleCalendarSection.test.tsx` | modify | Keep Google behavior coverage green after markup changes; add assertions for the connected/disconnected status affordances if the re-skin introduces badges or moved controls. |
| `superapp/apps/focal/client/src/features/settings/PushSection.test.tsx` | modify | Keep push behavior coverage green after markup changes; update label/role queries only where the old-focal layout moves controls. |
| `superapp/apps/focal/client/src/features/settings/AgentTokensSection.test.tsx` | modify | Keep agent token behavior coverage green after markup changes and assert the `ai-agents` anchor remains on the rendered section/card. |

# Implementation slices

1. **Route, nav, and title identity.**
   - Add a small redirect route for `/settings` that navigates to `/integrations` and preserves
     `window.location.search` plus `window.location.hash`.
   - Mount the existing `SettingsPage` at `/integrations`; keep `/` -> `/tasks` and all other routes
     unchanged.
   - Repoint the sidebar item from `{ key: 'settings', href: '/settings', icon: Settings }` to
     `{ key: 'integrations', href: '/integrations', icon: Plug }` or the closest existing lucide
     integration icon. Do not change the surrounding nav section or add old-focal-only nav entries.
   - Add `focal.app.nav.integrations` in both locales and update `focal.settings.title`/subtitle to
     the old-focal integrations copy. Keep the existing `focal.settings.*` namespace for section
     strings to avoid broad churn.
   - Add/update `App.test.tsx` and `AppShell.test.tsx`; run the focused tests before moving to visual
     page work.

2. **Page frame and inline card chrome.**
   - Replace `SettingsPage`'s plain centered stack with old-focal's full-height scrolling page frame:
     `flex flex-col h-full overflow-hidden`, `border-b bg-background shrink-0` header,
     desktop/mobile title sizing, and `max-w-4xl mx-auto space-y-6` content density.
   - Header copy is «Интеграции» / `Integrations` plus the old-focal link/integration icon visual.
     Reuse existing app-shell mobile trigger behavior; do not add duplicate sidebar controls if the
     current shell already supplies them for that viewport.
   - Re-skin `PrimeTimeSection`, `BackupSection`, `IcalSection`, and `DeleteAccountSection` to the
     old-focal `Card` pattern: icon square, `CardTitle`/`CardDescription`, muted info/warning panels,
     responsive button rows, and destructive account-delete border. Keep native file inputs hidden
     and labelled as they are now.
   - Keep `PrimeTimeSection` present and place it after the integration cards but before the final
     delete-account card, so destructive account deletion remains last.
   - Update `SettingsPage.test.tsx` for moved DOM and localized integration title/subtitle while
     preserving all existing behavior assertions.

3. **Google calendar section re-skin.**
   - Wrap the section in old-focal card chrome and use existing shadcn primitives already available in
     the app (`Card`, `Button`, `Badge`, `Label`, `Select`, `Switch`/`Checkbox` where appropriate)
     instead of adding packages or custom primitives.
   - Reproduce old-focal Google states from `GoogleCalendarSync.tsx` and
     `GoogleCalendarSyncAdvanced.tsx`: connected/not-connected badges, account email, last sync,
     calendar picker, sync direction/mode controls, incoming-request toggles, response toggles,
     manual sync/import actions, convert-to-local/delete-imported maintenance actions, and clear
     muted/error/success panels.
   - Keep `getGoogleAvailable() === false` returning `null`; do not render an empty card.
   - Preserve the current React Query keys, mutations, invalidations, and URL builder.
   - Update `GoogleCalendarSection.test.tsx`; run the focused test after the section compiles.

4. **Push notifications section re-skin.**
   - Convert the dark slate standalone section to old-focal card chrome with violet icon square,
     active/inactive badges, a switch-like main enable/disable affordance, device rows using muted
     backgrounds, and the existing test notification action.
   - Preserve support detection, VAPID query gating, `Notification.requestPermission()`,
     service-worker subscription lookup, subscribe/unsubscribe calls, lead-time update select, and
     all current error/status branches.
   - Update `PushSection.test.tsx` only where queries need to follow the new accessible control names
     or moved markup.

5. **AI-agent tokens section re-skin.**
   - Convert the section to old-focal `AiAgentTokensCard` chrome with `id="ai-agents"`, cyan icon
     square, create row, scope checklist, one-shot reveal panels, token cards, inactive warning badge,
     iCal/webhook buttons, and inline confirmation panels.
   - Preserve the current safer behavior where webhook save rejects non-HTTPS URLs before the API
     call and one-shot panels are dismissed when their owning token is revoked.
   - Do not port old-focal-only rename behavior unless it already exists in the new API/client; this
     task is a re-skin over current functionality.
   - Update `AgentTokensSection.test.tsx` for moved markup and anchor preservation.

6. **Section order, copy sweep, and final visual pass.**
   - Use this final order unless the design reviewer cites a specific old-focal mismatch: Google,
     Push, AI agents, Backup, iCal, Prime time, Delete account. This follows the task's named
     integration sequence, keeps prime time without making it the page identity, and keeps delete
     account last.
   - Sweep every changed visible string through `ru.json` and `en.json`; no hardcoded strings in TSX.
   - Search for old `/settings` app links in the client and update only this nav/route surface. Do not
     change API paths such as `/api/settings`.
   - Run the full client verification and perform light/dark screenshot comparison against old-focal
     `Integrations.tsx` plus `GoogleCalendarSync*.tsx`: header, card width, spacing, icons, badges,
     muted panels, destructive card, mobile wrapping, and no overlapping text.

# Tests

- `superapp/apps/focal/client/src/App.test.tsx`
  - `/integrations` renders the integrations page inside the authenticated shell; proves the new
    primary route is live.
  - `/settings` redirects to `/integrations` while preserving query/hash; proves old links and anchor
    links do not dead-end.
  - An unrelated unknown route still renders `NotFoundPage`; proves the route insertion does not
    swallow the catch-all.
- `superapp/apps/focal/client/src/components/AppShell.test.tsx`
  - Sidebar shows `focal.app.nav.integrations` with href `/integrations`; proves nav identity changed.
  - Sidebar does not show the old settings nav label as a nav item; proves the route rename is not
    duplicated in navigation.
  - Existing dashboard gating, meeting badge, refresh, children, and sign-out tests remain; prove the
    sidebar edit did not regress shell behavior.
- `superapp/apps/focal/client/src/features/settings/SettingsPage.test.tsx`
  - Header title/subtitle render integrations copy; proves visible page identity matches the route.
  - Section headings render in the planned order, including retained prime time and final delete
    account; proves the catch-all page did not silently drop behavior.
  - Existing prime-time tests prove saved window rendering, disabled/null save, enabled save, and
    end-time correction still call `api/settings` exactly as before.
  - Existing backup tests prove JSON import confirmation, valid import counts, and invalid-file
    rejection still work after the card move.
  - Existing iCal tests prove export download, import counts, and import failure messaging still work.
  - Existing account deletion test proves destructive confirmation still gates `deleteAccount()` and
    signs out only after the confirm word matches.
- `superapp/apps/focal/client/src/features/settings/GoogleCalendarSection.test.tsx`
  - Disconnected state still exposes the OAuth URL with the current user id; proves connect behavior
    survived the re-skin.
  - Integration-unavailable state renders nothing; proves the card wrapper does not create a blank
    unavailable card.
  - Connected state shows account email/status and enables sync controls; proves status/calendar/
    settings queries still compose.
  - Toggle, calendar-select, manual sync, and disconnect tests still prove the same API calls and
    status messages after markup changes.
- `superapp/apps/focal/client/src/features/settings/PushSection.test.tsx`
  - Unsupported and server-not-configured states still render localized notices; proves browser/server
    gating remains intact.
  - Subscribed-device test still lists the device, sends a test push, and reports success; proves
    service-worker subscription behavior is unchanged.
  - Lead-time select test still calls `updatePushSettings` with the subscription id and minutes; proves
    device settings did not become presentation-only.
- `superapp/apps/focal/client/src/features/settings/AgentTokensSection.test.tsx`
  - Token list/inactive tests still prove stale-token calculation and row rendering.
  - Create-token tests still prove checked scopes are sent and one-time secrets are revealed once.
  - Revoke, HTTPS webhook validation/save, iCal generation, and iCal revoke tests still prove the same
    API calls and confirmation gates.
  - Anchor assertion proves the `#ai-agents` deep link target remains present after card re-skin.
- Manual/visual verification after implementation:
  - `cd /Users/allosta/Desktop/allosta/.worktrees/focal-redesign-integrations/apps/focal/client`
  - `pnpm install --frozen-lockfile`
  - `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`
  - Run the app and compare `/integrations` in light and dark against old-focal for desktop and mobile
    widths, including connected/disconnected Google, empty token list, subscribed/unsubscribed push,
    import-confirm panels, one-shot secret panels, destructive delete confirmation, and long localized
    strings.

# Error & rescue map

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `SettingsRedirectLoop` | No thrown exception; `/settings` redirects back to itself or to a route that redirects back | `App.test.tsx` route test and manual navigation | The page never settles or shows the wrong route; fix by making `/settings` target `/integrations` only. |
| `SettingsRedirectDropsContext` | No thrown exception; search/hash are omitted from redirect target | `App.test.tsx` preserving query/hash | Old callback or `#ai-agents` links land on `/integrations` without the intended notice/anchor. |
| `IntegrationsRouteMissing` | Wouter falls through to `NotFoundPage` for `/integrations` | `App.test.tsx` primary-route render test | User sees the not-found page when clicking the nav item. |
| `ActiveNavMismatch` | No thrown exception; sidebar item href/key still points at `/settings` or active state compares the wrong href | `AppShell.test.tsx` and manual sidebar check | Sidebar shows the old item, wrong label, or no active state on `/integrations`. |
| `LocaleKeyMissing` | i18next returns a key string or stale settings copy | Component tests using `i18n.t(...)`, manual RU/EN check, `pnpm build` for JSON syntax | User sees `focal...` keys or «Настройки» where old-focal expects «Интеграции». |
| `UnavailableGoogleBlankCard` | No exception; `getGoogleAvailable()` false still renders an empty card shell | `GoogleCalendarSection.test.tsx` unavailable-state test | User sees an empty integration card for an unavailable backend integration. |
| `GoogleMutationDrift` | Existing mutation is not called because a control was replaced or disconnected | Google section behavior tests | User can see controls but connect/select/sync/disconnect/save actions do not persist. |
| `PushPermissionDrift` | Existing Push/Notification branch is not reached after control changes | Push section tests with stubbed browser APIs | User can see push controls but cannot subscribe, unsubscribe, or send a test notification reliably. |
| `AgentSecretLeakOrLoss` | One-shot token/iCal/webhook panels are not shown, not dismissed, or shown for the wrong token | Agent token tests for create/revoke/webhook/iCal flows | User misses a one-time secret or sees a stale secret after revocation. |
| `PrimeTimeRegression` | `PrimeTimeSection` is removed or its save controls are disconnected | Settings page prime-time tests and section-order test | User loses the current prime-time editor or cannot save the window. |
| `ImportControlRegression` | Hidden file input loses label/ref or same-file reset | Backup/iCal upload tests | User cannot trigger import or retry the same file after an error. |
| `ResponsiveOverlap` | No thrown exception; title/actions/buttons/long labels overlap after visual changes | Manual desktop/mobile light/dark screenshots | Header or card controls are hard to read or click on small screens. |

# Review lenses (pre-answer before gate2-plan)

- **Scope / strategy** — This is the minimum viable implementation for the approved decision:
  route/nav rename plus a visual re-skin over existing `features/settings` behavior. Existing API
  wrappers, React Query keys, mutations, auth shell, shadcn primitives, and tests already solve the
  functional surface, so the plan does not introduce server routes, schemas, packages, or a wholesale
  old-focal port. The route decision is reversible because `/settings` remains a redirect and no
  persisted data changes.
- **Architecture** — Data flow stays section-local React state plus TanStack Query over
  `api/{integrations,push,agentTokens,backup,ical,account,settings}.ts`. Route identity changes only in
  `App.tsx` and `AppSidebar.tsx`. The re-skin may use existing shadcn `Card`, `Button`, `Badge`,
  `Input`, `Label`, `Select`, `Switch`, and `Checkbox`; it must not create a new design system layer.
  Unhappy paths remain section-local: query errors render alerts/notices, mutations set existing
  status text, and redirects preserve context.
- **Design** — The page must be a dense single-scroll integrations surface, not a landing page:
  old-focal header, old-focal card width and spacing, icon squares, status badges, muted warning/info
  panels, destructive delete card, responsive button wrapping, and light/dark token behavior. Empty,
  loading, unavailable, connected, disconnected, permission-denied, pending-import, one-shot secret,
  and confirmation states are all part of the re-skin.
- **DevEx** — Keeping the folder/export name avoids churn for imports and tests while the route/nav
  provide the user-facing identity. Tests remain behavior-first and use accessible names instead of
  brittle class snapshots. The next developer should be able to trace every changed production line to
  visual parity, `/integrations` identity, retained prime-time behavior, or localized copy.

# Risks & migrations

- No database migrations, data backfills, server changes, API changes, generated OpenAPI changes,
  dependency additions, lockfile edits, or config changes are planned.
- Main risk is visual scope creep on a catch-all page. Mitigation: keep each section on its existing
  API/client logic, use existing shadcn primitives, and reject unrelated behavior additions such as
  token rename, new Google endpoints, or relocating prime time.
- Secondary risk is a route rename breaking old links. Mitigation: keep `/settings` as a redirect and
  preserve search/hash.
- Visual exactness is partly manual. Mitigation: run full checks plus direct light/dark desktop/mobile
  comparison against old-focal `Integrations.tsx` and the two Google sync components.
- Rollback plan: revert the frontend files listed above. Because there are no schema/server changes,
  rollback is a client-only revert.

# Scope check

- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting when reviewed by the implementation slices above.
- [x] Size smell checked: the production diff touches one route file, one nav component, the existing
      settings feature sections, and two locale files. Any need to edit APIs, backend code, generated
      OpenAPI, shared primitives, package files, or unrelated pages should split out or be blocked.

# Out of scope

- Any server, API, schema, OpenAPI generation, database migration, auth, billing, or offline queue
  change.
- Behavior changes to Google OAuth/sync/import/delete/convert, push subscriptions, token CRUD, webhook
  management, backup import/export, iCal import/export, account deletion, or prime-time persistence.
- Removing or relocating `PrimeTimeSection`; this plan keeps it because relocation is a separate
  product decision.
- The `/calendars` `GoogleSyncPanel`, shared-calendar flows, calendar page behavior, and broader shell
  nav reconciliation beyond this one item.
- Porting old-focal's Tailwind 3 config, query client, toast system, auth provider, API request layer,
  or old page component wholesale.
- New dependencies, new shadcn primitives, visual snapshot infrastructure, or checked-in screenshots.
