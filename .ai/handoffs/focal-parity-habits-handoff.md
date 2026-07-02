# Stage

3-gate · slice 7 of the `focal-parity` epic: **Habits parity**. Branch `feat/focal-parity-habits`
→ base `feature/focal-migration` (one commit). Frontend-only; no server/API/schema/migration.

# What changed

Brings Habits to old-focal parity (all fields/endpoints already existed on the API — this only wires
them):
- `HabitCreateDialog` is now **create + edit** (the row Edit button opens it pre-filled) and gains
  **category**, **description**, **project link**, and an **8-chip recommended-presets** row.
- `HabitJournal` gains a per-habit **expand panel** with a per-day **note**, explicit **Yes / No /
  Skip / Erase** buttons, and a **delete-confirmation** dialog; the existing week-cell tracking and
  chevron reorder are unchanged.
- All entry writes are **serialized + gated on the entries refetch window** (`isSuccess &&
  !isFetching` + an in-flight guard) so cycling a day or saving a note can never overwrite a
  just-saved note mid-refetch; future-dated panel writes are blocked; delete-confirm stays open on a
  rejected delete. Every write is `canEdit`-gated and `calendarId`-scoped.

# Files touched

- `apps/focal/client/src/features/habits/HabitCreateDialog.tsx` (+ test)
- `apps/focal/client/src/features/habits/HabitJournal.tsx` (+ test)
- `apps/focal/client/src/features/habits/HabitsPage.tsx` (+ test)
- `apps/focal/client/src/i18n/locales/en.json`, `ru.json`

# Tests run

```sh
cd apps/focal/client
pnpm typecheck   # 0 errors
pnpm lint        # biome: 0 errors
pnpm test:run    # 80 files, 947 tests passed
pnpm build       # ✓
```

# Still needs review

- **Frontend-only** — no schema/migration. Client scoping is not security; slice-2 backend RBAC + RLS
  enforce shared-calendar writes.
- Deferred (tracked): **dnd-kit drag-reorder** (the chevron reorder is at functional parity).

# PR / release notes (for users)

The habit editor now lets you **edit an existing habit** (not just create), and set a **category**, a
**description**, and **link it to a project**; a row of **recommended habits** fills the form in one
click. In the journal you can open a habit to write a **per-day note** and set an explicit **Yes / No
/ Skip** (or **Erase**) for the selected day, and deleting a habit now asks you to **confirm** first.

(No secrets, tokens, keys, or PII — client components, locale strings, and tests.)

# Status

OPUS VERIFY/RELEASE-GATE APPROVED (9.5). Gate-A design APPROVED 9.3 · Gate-B build APPROVED 9.4
(4 passes — hardened a note-write data-loss race). Cleared for release; open the PR.
