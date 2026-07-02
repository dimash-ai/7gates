## What & why

Re-skins the new Focal settings surface to **exact visual parity with old-focal's Integrations page**, and renames the page identity **`/settings` → `/integrations`** (nav «Интеграции», with a `/settings` redirect that preserves query + hash). A slice of the `focal-redesign-pages` epic. **Frontend-only** — no API, behavior, schema, or dependency changes; the page already composed all of old-focal's Integrations content, so this changes presentation + the route/nav identity only.

## What you can now do

The settings page is now **«Интеграции» / Integrations** at `/integrations`, restyled to match Focal's design in both light and dark themes — one place to connect/disconnect Google Calendar and tune two-way sync, manage push notifications and devices, create/revoke AI-agent API tokens (one-time secret reveal, iCal feed links, delivery webhooks), export/import a full backup, import/export iCal, set your prime-time window, and delete your account. Old `/settings` links (including `#ai-agents` deep links) redirect automatically. Fully localized (ru + en).

## Scope

- **Route + nav:** `/integrations` route; `/settings` → `/integrations` redirect (preserves search + hash); sidebar item → «Интеграции» (lucide `Plug`).
- **Page:** header «Интеграции» + icon; old-focal section order — Google → Push → Backup → iCal → AI agents → Prime time → Delete account.
- **Sections re-skinned** from the hardcoded dark-slate palette to token-based `Card` chrome (correct in light **and** dark): Google Calendar, Push (active/inactive badge + `Switch`), AI-agent tokens (`#ai-agents` anchor) + old-focal's backup warning panel.
- **i18n:** `ru` + `en` (added nav/title/push/backup keys; removed the now-unused `nav.settings` + `push.disable`).
- Preserved behavior: Google `available===false` → renders nothing; one-shot secret reveal (once, dismissed on revoke); HTTPS-only webhook guard before the API; delete-account confirm-word gate; account device list whenever the account has subscriptions.

## Verification

`pnpm lint` ✅ · `pnpm typecheck` ✅ · `pnpm test:run` ✅ (50 files / 375 tests) · `pnpm build` ✅.

## Pipeline (`.ai/` 7-gate)

think 9.1 · plan 9.1 · design 9.0 · build 9.2 · review 9.4 · test 9.5. Final ship review is green on code / tests / security / i18n; **visual QA (light/dark, desktop/mobile screenshot parity vs old-focal) is pending — to confirm on this PR before merge.**

No data/behavior change; rollback = revert the frontend files.
