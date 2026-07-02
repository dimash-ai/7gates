# Stage

Step 7 — ship (final gate) for `focal-redesign-integrations`, a slice of the `focal-redesign-pages` epic.

# What changed

Re-skinned the new Focal app's settings/integrations surface to **exact visual parity with
old-focal's `Integrations.tsx`**, and renamed the page identity from `/settings` to `/integrations`
(nav «Интеграции», with a `/settings` redirect). Frontend-only; behavior and APIs unchanged.

Per the plan's slices:
1. **Route + nav identity** — added the `/integrations` route, made `/settings` a `<Redirect>` that
   preserves `location.search` + `location.hash`, and repointed the sidebar item to «Интеграции»
   (lucide `Plug`).
2. **Page frame + order** — page header «Интеграции» + icon; sections reordered to old-focal's
   order: Google → Push → Backup → iCal → AI agents → Prime time → Delete account (delete last).
3. **Section re-skins** — `GoogleCalendarSection`, `PushSection`, `AgentTokensSection` converted from
   the hardcoded dark-slate palette to the token-based `Card` chrome (light + dark), matching
   old-focal: gradient icon squares, status badges, muted info/warning panels, a Push active/inactive
   badge + `Switch` main control, and the `#ai-agents` anchor on the tokens card.
4. **Backup warning** — added old-focal's muted import-warning panel.
5. **i18n** — added `focal.app.nav.integrations`, the «Интеграции» page title/subtitle,
   `push.active`/`push.inactive`, and `backup.warning` in both `ru` + `en`; removed the now-unused
   `nav.settings` and `push.disable` keys.

No API call, query key, mutation, URL builder, or backend contract changed. Preserved: Google
`available === false` → render nothing; one-shot token/iCal/webhook secret reveal (shown once,
dismissed on revoke); HTTPS-only webhook guard before the API; delete-account confirm-word gate;
account device list rendering whenever the account has subscriptions.

# Files touched

- `apps/focal/client/src/App.tsx` — `/integrations` route + `/settings`→`/integrations` redirect (query/hash preserved)
- `apps/focal/client/src/App.test.tsx` *(new)* — route render, redirect (exact `replaceState`), unknown-route→NotFound
- `apps/focal/client/src/components/AppSidebar.tsx` — nav item Settings→Integrations (`Plug`)
- `apps/focal/client/src/components/AppShell.test.tsx` — nav identity (Интеграции present, /settings gone)
- `apps/focal/client/src/features/settings/SettingsPage.tsx` — header + section order + backup warning panel
- `apps/focal/client/src/features/settings/SettingsPage.test.tsx` — title, order, `#ai-agents`, backup warning, import error
- `apps/focal/client/src/features/settings/GoogleCalendarSection.tsx` — token `Card` re-skin
- `apps/focal/client/src/features/settings/PushSection.tsx` — token `Card` re-skin + active/inactive badge + `Switch`
- `apps/focal/client/src/features/settings/PushSection.test.tsx` — subscribe/unsubscribe via switch, devices-when-inactive
- `apps/focal/client/src/features/settings/AgentTokensSection.tsx` — token `Card` re-skin + `id="ai-agents"`
- `apps/focal/client/src/features/settings/AgentTokensSection.test.tsx` — one-shot reveal, revoke-dismiss, HTTPS rejection
- `apps/focal/client/src/i18n/locales/ru.json` — nav/title/push/backup keys (add) + nav.settings/push.disable (remove)
- `apps/focal/client/src/i18n/locales/en.json` — same

# Tests run

```sh
cd .worktrees/focal-redesign-integrations/apps/focal/client
pnpm lint        # biome — 218 files, 0 diagnostics
pnpm typecheck   # tsc -b — exit 0
pnpm test:run    # 50 files, 375 tests passed, 0 failed
pnpm build       # vite — built OK
```

# Verification output

```sh
 Test Files  50 passed (50)
      Tests  375 passed (375)
$ biome check .  → Checked 218 files. No fixes applied.
$ tsc -b         → (clean, exit 0)
$ vite build     → ✓ built
```
(The `ECONNREFUSED ::1:3000` lines in test output are pre-existing stub noise from an unrelated
suite; the run is green.)

# Still needs review

- **Visual QA pending** — pixel/colour parity vs old-focal in **light + dark**, desktop + mobile,
  has not been eyeballed in a running client (the gates verified structure/behavior, not pixels).
  Recommend a quick authed local pass on `/integrations` before merge.
- Non-blocking notes carried from the gates (no action required): `App.test` stubs `SettingsPage`,
  so the real page mounting at the real route is proven only transitively (covered directly in
  `SettingsPage.test`); the section-order test uses text-position indexing (fine — all titles are
  distinct today).

# PR / release notes (for users)

**Integrations settings, redesigned.** The settings page is now **«Интеграции» / Integrations** and
lives at `/integrations` — restyled to match Focal's design in both light and dark themes. Manage
everything from one place: connect/disconnect Google Calendar and tune two-way sync, enable push
notifications and manage your devices, create and revoke AI-agent API tokens (with one-time secret
reveal, iCal feed links, and delivery webhooks), export/import a full backup, import/export iCal, set
your prime-time window, and delete your account. Old `/settings` links (including `#ai-agents` deep
links) redirect automatically. No data or behavior changes — only the look, the page name, and the
URL. Fully localized (Russian + English).

_Confirmed: contains no secrets, tokens, keys, or PII._

# Status

MERGED — PR #66 (https://github.com/Allosta-Group/superapp/pull/66) into `feature/focal-migration`
on 2026-06-23 (merge commit `d7b6a5f`), by the user. Slice branch + worktree removed.

Gate-7 automated final review was green on **code / tests / security / i18n** (8.7 — no regressions,
no secret leak, all locale keys present in both `ru`+`en`). The one item it flagged — the human
**visual-QA** light/dark screenshot-parity pass — was **not formally recorded before merge**; the
user merged ahead of it. Recommend a quick light/dark `/integrations` parity pass on the dev
environment post-merge.
