# Review Verdict

Reviewer: GPT Codex
Step: build
Score: 9.4 / 10
Status: APPROVED

## Reason
The prior MiniMonth i18n Must Fix is resolved: the accessible label now goes through
`focal.calendar.miniMonth.day` with a localized `Intl.DateTimeFormat` date and matching en/ru
keys/tests. The build preserves the extracted week-grid behavior, derives per-view windows cleanly,
keeps the now-line invariant, adds the non-week popover path, and stays within the requested
frontend/calendar scope.

## Must Fix
None

## Should Consider
Month day-cell accessible labels still interpolate ISO dates; consider using the same localized-date
pattern as MiniMonth for consistency.

## Tests Reviewed
Inspected `CalendarPage.test.tsx` and `dates.test.ts`; reviewed reported `pnpm lint`, `pnpm typecheck`,
`pnpm test:run`, `pnpm build`, and `pnpm check:i18n`.

## Release Risk
Low

---
_Iteration log: first build pass scored **8.8 / BLOCKED** — one Must Fix (`MiniMonth.tsx` hardcoded the
day-button accessible label with `toIsoDate(day)` instead of routing it through i18next with ru/en
coverage). Fixed: label now `t('focal.calendar.miniMonth.day', { date: <localized> })` + the
`miniMonth.day` key added to en/ru; the two mini-month tests query via a `miniDay()` helper; and a
non-week popover test was added (the Should-Consider from that pass). Re-review scored **9.4 /
APPROVED** (above). Post-approval, the remaining Should-Consider (localize the MonthView `dayCell`
date too) was also applied for consistency — MonthView now formats the cell date with the same
`Intl.DateTimeFormat` pattern, and the month-grid test counts the 42 cells by role within the main
region (locale-robust). All checks green afterward: lint 0, typecheck 0, full suite 351 passed
(calendar 71), build OK, check:i18n no drift._
