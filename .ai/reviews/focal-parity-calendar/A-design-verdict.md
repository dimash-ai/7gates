# Review Verdict

Reviewer: GPT Codex
Step: design
Score: 8.2 / 10
Status: BLOCKED

## Reason
The scope and deferral choices are mostly sound: the API type has the needed read fields, the all-day convention matches old-focal, and the risky drag/timezone/write-path work is kept out. However, the design is not yet a safe handoff because it encodes the wrong event field names, changes old-focal color precedence, and proposes mini-month dots from a data window that cannot satisfy its acceptance criteria.

## Must Fix
- Correct the event contract names in the design. `.ai/design/focal-parity-calendar-design.md:48-49`, `:71-72`, and `:107-108` specify `project_color` and `start_time`/`end_time`, but the actual generated client exposes `projectColor`, `startTime`, and `endTime` in `superapp-slice6/apps/focal/client/src/api/openapi.d.ts:3032-3035` and `:3094-3099`; implementing the design literally would miss/compile-fail the color and all-day paths.
- Fix color precedence to match old-focal instead of always preferring project color. The design says `project_color ?? event.color` at `.ai/design/focal-parity-calendar-design.md:32` and `:71-72`, but old-focal uses `event.projectColor` first only for product events, and otherwise preserves `event.color` before `projectColor` at `superapp/apps/old-focal/client/src/components/CalendarViews.tsx:886-890`.
- Redesign the mini-month event-count data source or explicitly narrow the behavior. The design says to derive markers from "already-loaded events" with no extra fetch at `.ai/design/focal-parity-calendar-design.md:68-70` and requires days with events to show markers at `:105-106`, but the new page fetches only the active main-view window in `superapp-slice6/apps/focal/client/src/features/calendar/CalendarPage.tsx:178-187`, while `MiniMonth` can browse an independent displayed month at `superapp-slice6/apps/focal/client/src/features/calendar/MiniMonth.tsx:20-24` and `:64-75`; old-focal's markers were built from an expanded event set, not just the current viewport, at `superapp/apps/old-focal/client/src/pages/Calendar.tsx:543-569` and `:1777-1784`.

## Should Consider
- Specify where scroll-to-now writes `scrollTop`: `TimeGrid` currently has only an `overflow-x-auto` wrapper, while vertical scrolling is owned by the surrounding calendar card (`CalendarPage.tsx:472`), so the implementation needs an explicit scroll container/ref plan.

## Tests Reviewed
N/A (design review; inspected charter/rubric and relevant source files)

## Release Risk
Medium
