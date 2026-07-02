# Goal

**Slice 1 of the `focal-redesign-calendar` epic** (parent roadmap:
`.ai/think/focal-redesign-calendar.md`). Restyle the Focal calendar's **week time-grid** to the
design prototype and Google-Calendar look — the **visual + structural base every later calendar slice
builds on**. After this slice the week view *looks* like Google Calendar / the prototype (styled hour
grid, now-line, today highlight, day headers, and event blocks with their state variants laid out in
overlap lanes) while keeping **all current behavior** (the real events API, week navigation, and the
existing create/edit/delete forms) intact.

> **Visual contract** = `design/focal/screens/Calendar.jsx` (the `CalendarScreen` grid ~`:931`-`1051`,
> the `Ev` event block `:152`-`184`, `CAL_PALETTE` `:7`, the now-line `:1044`) + `design/focal/app.css`
> + the merged foundation tokens/primitives (PR #50). **Interaction contract** = **Google Calendar**
> for the behaviors in this slice's scope (Today + prev/next week, now-line, today highlight,
> click-empty-slot to start an event, side-by-side overlap). **Behavioral base** = the current
> `features/calendar/CalendarPage.tsx` (the real `api/events.ts` + recurrence scope it already drives).

> **Frontend-only, behavior-preserving.** No server/API/schema change. The existing events week query,
> `create/update/delete` + recurrence scope, `ContactPicker`, and error/loading states are **kept**;
> only the calendar's *appearance* and the event-block structure change. The existing
> `CalendarPage.test.tsx` (week request, prev-week nav, create-from-form, delete plain, delete/edit
> recurring with scope) **stays green** — updated only for structural class changes. All strings via
> i18next (`ru` + `en`).

# Scope

**Top bar** (`CalendarPage.tsx:199`-`227` today: a bare `<h1>` + nav buttons)

- Bring it onto the shared, foundation-restyled `PageHeader` (which already matches the prototype
  TopBar): the calendar accent **icon badge** + title, the **week date-range stepper** (prev / range
  label / next) and **Today** as `leftActions`/`centerActions`, and the standard right cluster
  (`PageToolbar`: AI button, theme, language) — restyled per the prototype `Stepper`/`TopBar`.
- **No multi-view switcher in this slice.** Day/3-day/month + the switcher land in slice 3 (`…-views`),
  when more than one view exists — shipping dead view buttons now would be non-functional chrome
  (explicitly avoided). Week is the only view here.

**Time grid** (`CalendarPage.tsx:425`-`504` today)

- Restyle the hour gutter (00:00–23:00), the hour grid lines, the day-column headers (weekday + date),
  the **today** column highlight, and add the prototype's **now-line** (a 2px accent/red line + dot at
  the current time, `Calendar.jsx:1044`) on today's column. Keep `HOUR_HEIGHT = 48` (matches the
  prototype `HOUR_PX`). Mon–Sun week.

**Event block** (extract `features/calendar/EventBlock.tsx` from the inline block at
`CalendarPage.tsx:472`-`498`)

- A reusable styled block matching the prototype `Ev` (`:152`-`184`) with the state variants, driven
  by the **real `EnrichedEventRead` fields**:
  - **orphan** — `event.isOrphan === true` (the contract field, `openapi.d.ts` EnrichedEventRead) →
    danger ring + tinted danger bg (overrides color).
  - **tentative** — `status === 'tentative'` → dashed border, muted.
  - **confirmed** — `status === 'confirmed'` → filled `event.color`, white text.
  - **planned / default** — tinted `event.color` bg + colored text (today's create default is
    `'planned'`). *(The exact `status` → variant map is confirmed at this slice's design gate; `status`
    is a free-form string and only `'planned'` is in use today.)*
  - Title (truncate), time line, repeat marker when recurring; `color` from `event.color` or a palette
    fallback.
- **Overlap lanes:** concurrent events render side-by-side (port the prototype `_lane`/`_lanes` math,
  `Calendar.jsx:128`-`149`) into a small pure helper (`dates.ts` or a new `lanes.ts`) with a unit test.
- Click a block → opens the **existing** edit form (unchanged behavior; the popover is slice 2).

**Keep (lightly restyled, not rebuilt)**

- The inline **create** form and **edit** card (`CalendarPage.tsx:229`-`423`) — restyled to the
  foundation primitives, but kept (the popover replaces them in slice 2; the tests depend on them).

**Google Calendar behaviors in scope**

- Today + prev/next **week** navigation (exists — keep), the **now-line**, **today** highlight,
  click an empty slot to **prefill a new event** (exists — keep), side-by-side **overlap**. **Keyboard
  shortcuts are deferred to slice 3** (they land as one coherent set with the view shortcuts), keeping
  this slice strictly behavior-preserving.

# Out of scope

- The event **popover** + recurring-scope **dialog** (slice 2 — this slice keeps the inline forms).
- **Day / 3-day / month** views, the **view switcher**, and the **mini-month** (slice 3).
- **Drag / move / resize** of events and **15-min drag snap** (slice 4).
- The **side panel** (5), **cross-DnD** (6), **bookings** strip (7), **prime-time** bands (8).
- The **all-day** lane and single-day **marks** (backend-blocked — epic out-of-scope).
- **Keyboard shortcuts** (deferred to slice 3 with the view shortcuts — this slice adds no new behavior).
- Any server / API / schema change.

# Acceptance criteria

- [ ] `cd superapp/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`
      all green.
- [ ] The week grid matches the prototype `Calendar.jsx` in **light and dark**: styled hour gutter +
      grid lines, day headers, **today highlight**, the **now-line**, and event blocks with the
      **confirmed / planned / tentative / orphan** variants — orphan driven by `event.isOrphan`.
- [ ] Concurrent events render **side-by-side in overlap lanes** (pure helper, unit-tested).
- [ ] The top bar uses the foundation `PageHeader` with the week stepper + Today; **no dead view-
      switcher buttons** are shipped.
- [ ] **Behavior preserved:** the existing `CalendarPage.test.tsx` stays green (week request,
      prev-week nav, create-from-form, delete plain, delete/edit recurring with scope) — updated only
      for structural class changes. Today + prev/next nav and the now-line are exercised.
- [ ] No hardcoded strings (i18next `ru` + `en`); the diff is surgical — only `features/calendar/*`
      (+ a new `EventBlock.tsx` / lane helper) and, if a new label is needed, `i18n/locales/{ru,en}.json`.
- [ ] Before/after screenshots (week grid + event-block states, light + dark) against the prototype.

# Verification commands

```sh
cd superapp/apps/focal/client
pnpm install --frozen-lockfile
pnpm lint && pnpm typecheck && pnpm test:run && pnpm build
```
