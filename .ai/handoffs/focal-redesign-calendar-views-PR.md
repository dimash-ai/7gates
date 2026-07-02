# PR draft — slice 3 (calendar views)

**Branch:** `feat/focal-calendar-views` → `feature/focal-migration`
**Title:** `feat(focal): calendar day / 3-day / month views + mini-month navigator`

---

## Summary

The Focal calendar now opens in **Week** view as before, and you can switch it to **Day**, **3-day**,
or **Month** from the view switcher in the header. A **mini-month** navigator in the left rail lets you
jump to any date while keeping your current view, and **keyboard shortcuts** drive the whole surface —
the same interactions Google Calendar users already know.

## What you can do now

- **Switch views** — Day / 3-day / Week / Month, from the header switcher or with `d` / `3` / `w` / `m`.
- **Navigate** — the prev/next arrows step by the active view's unit (a day, three days, a week, or a
  month); **Today** (or `t`) jumps back to now; `n`·`j` = next, `p`·`k` = prev.
- **Month view** — a 6-week grid showing up to three events per day with a "+N more" overflow; click a
  day to zoom into it.
- **Mini-month** — browse months with its own chevrons without moving the main grid; click a day to
  move the grid there in whatever view you're in.
- Creating, editing, deleting, and the recurring-scope prompt work in every time-grid view, unchanged.

Keyboard shortcuts stay out of your way while you're typing in the event editor or a dialog is open.

## Scope

Frontend-only. No backend, database, schema, migration, or API change. The events API, mutations, the
recurring-scope flow, and the event editor popover are untouched — this change reuses them. The week
grid was extracted into a shared `TimeGrid` so the day / 3-day / week views render from one component;
the month grid and mini-month are read-only views over the same event data.

## Tests

`pnpm lint`, `pnpm typecheck`, `pnpm test:run` (47 files / 353 passing; calendar 6 files / 73), and
`pnpm build` all green; `pnpm check:i18n` reports no locale drift. New coverage: per-view query
windows, month-grid rendering + day-zoom, mini-month isolation + date pick, keyboard shortcuts with
both the typing-guard (focused popover input) and the dialog-guard (recurring-scope dialog open), the
now-line "only when today is visible" invariant across day / 3-day / month, and the month-step day
clamp. Both `en` and `ru` locales updated (with Russian plural forms).

**Visual QA (reviewer, local):** the per-view light/dark screenshot pass is done from an authenticated
local session (`pnpm --dir apps/focal/client dev`) — the hosted preview is login-gated, so it isn't
part of the automated checks above. Please eyeball each view + the mini-month in light + dark against
the prototype before merging.

## Risk & rollback

**Low.** Presentational, additive, no persisted state or contract change. Rollback = revert this PR
(the three new components, the `CalendarPage` controller refactor, the three `dates.ts` helpers, the
locale additions, and the test delta).
