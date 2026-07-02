# Stage

Stage 7: ship — `focal-redesign-calendars` (a slice of the `focal-redesign-pages` epic).

# What changed

Re-skinned the new Focal **Calendars page** (`/calendars`) to exact visual parity with old-focal's
`pages/Calendars.tsx` shared-calendar manager, reproduced on the new stack (React 19 / Tailwind 4 /
shadcn) over the **existing** `api/sharedCalendars.ts` — **no server / API / schema change**. Built
on the merged shell foundation (`afaaeba`). Covers the plan's slices 1–7:

- **Page frame** — bespoke desktop-one-row / mobile-two-row header (sidebar toggle + icon + title +
  subtitle + the shared `PageToolbar` AI/theme/lang cluster), the two-column **«Мои календари» /
  «Доступные мне»** layout, and loading / error / empty states.
- **Owned calendar accordion card** — color dot, name + «Календарь-фильтр» badge, **«Владелец»** role
  badge, rename + delete, and three collapsible sections: **«Что показывается»** (the filter editor),
  **«Участники и их права»** (participants + roles), **«Правила синхронизации с Google»**.
- **«Что показывается» filter editor** — full **6-type** old-focal parity (`all` · work/personal time
  · sphere · project · product · mission/provision), wired onto the already-backed
  `filterType`/`filterValue` fields (the page previously hardcoded `all` on create). Editable in-card
  for owners (Save → `updateCalendar`, only the two filter fields) and at create. A stored filter
  outside the six is shown read-only and never overwritten; a value-backed type with no value chosen
  cannot be saved.
- **Participants** — invite (dialog), role change, remove, **copy pending invite code** (clipboard),
  the «Ожидание» state.
- **«Доступные мне»** — role badge, participant count, and **leave-calendar** (self-removal) for
  calendars the viewer participates in but doesn't own; the self participant id resolves from
  `listParticipants` + the auth user id, then the existing `removeParticipant`.
- Added a thin frontend `listMyParticipation()` wrapper over the existing
  `GET /api/shared-calendars/my-participation` (no server change). All strings via i18next (`ru` + `en`).

# Files touched

- `apps/focal/client/src/features/calendars/CalendarsPage.tsx` (modified — the re-skin)
- `apps/focal/client/src/features/calendars/calendarFilters.ts` (added — pure filter encode/decode + guard)
- `apps/focal/client/src/features/calendars/GoogleSyncPanel.tsx` (modified — drop redundant title, add loading state)
- `apps/focal/client/src/api/sharedCalendars.ts` (modified — `listMyParticipation` wrapper + `MyParticipation` type)
- `apps/focal/client/src/features/calendars/CalendarsPage.test.tsx` (modified — re-skin + risky-path tests)
- `apps/focal/client/src/features/calendars/calendarFilters.test.ts` (added)
- `apps/focal/client/src/api/sharedCalendars.test.ts` (added)
- `apps/focal/client/src/i18n/locales/ru.json`, `en.json` (modified — calendars keys)

# Tests run

```sh
cd apps/focal/client
pnpm typecheck        # tsc -b → 0 errors
pnpm lint             # biome → 220 files, 0 errors
pnpm test:run         # vitest → 51 files, 376 passed
pnpm build            # vite → built OK
```

# Verification output

```sh
=== TYPECHECK ===  tsc -b --pretty            # clean
=== LINT ===       Checked 220 files. No fixes applied.
=== FULL TESTS ===  Test Files  51 passed (51)
                        Tests  376 passed (376)
=== BUILD ===      ✓ built (chunk-size warning only, pre-existing)
```

# Still needs review

- **Visual QA — the final human gate (needs an authed session).** Run the client against superapp-dev,
  log in, and screenshot `/calendars` in **light + dark** against old-focal: the multi-open accordion
  card + three sections, «Владелец» badge, «Мои» / «Доступные» layout, create / join dialogs, the «Что
  показывается» editor, empty states. As with the prior slices, this is the one step the automated
  pipeline can't perform itself — it requires a logged-in session.
- **Resolved at gate 7:** the accordion is now **independent multi-open** (was single-open), matching
  old-focal + the design; `GoogleSyncPanel` now renders **exclusive** loading / error / connected /
  connect states (no Connect button during load/error).
- The «Что показывается» editor ships **all 6** filter types (the plan initially scoped 3); this was
  the gate-3 design decision (exact old-focal, all types backed) and the gate-2/3 reviewers ratified it.

# PR / release notes (for users)

**Calendars page redesigned to match Focal.** The `/calendars` screen now looks and works like the
calendars manager you know from Focal:

- Each of **your calendars** is a card you can expand to **«Что показывается»** (choose what the
  calendar shows — everything, work/personal time, a life sphere, a project or product, or
  mission/provision), **«Участники и их права»** (invite people, set their role, copy a pending invite
  code, remove them), and **«Правила синхронизации с Google»**.
- **Create** a new calendar with a name, colour, and filter; **join** one by invite code.
- **«Доступные мне»** lists calendars shared with you, with your role and a **«Покинуть»** (leave)
  action.
- Works in **light and dark**, in **Russian and English**.

No data is migrated and nothing about how calendars work changes — this is a visual + interaction
refresh of the existing feature. Contains no secrets, tokens, keys, or PII.

# Status

CODEX APPROVED (9.1) — all 7 gates passed (think 9.2 · plan 9.3 · design 9.4 · build 9.1 ·
review 9.4 · test 9.5 · ship 9.1). Committed as `871fc1a` on `feat/focal-redesign-calendars`.
Pre-merge: user visual QA (light + dark vs old-focal).

---
Cleared for release pending the user visual-QA gate above.
