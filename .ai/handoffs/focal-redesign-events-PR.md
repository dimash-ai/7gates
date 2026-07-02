# feat(focal): add the Events page at old-focal parity

## What you can now do

Focal now has a dedicated **События (Events)** page alongside the calendar — open it from the sidebar
(Исполнение → События) or at `/events`. It's the list view of your events, distinct from the calendar
grid.

- **Browse** your events grouped into **upcoming** and **past**, each row showing time, project
  colour, priority, recurrence, and orphan/status badges.
- **Filter & search:** by title; by date range (Today, Yesterday/Tomorrow, This/Last/Next week,
  This/Last/Next month, This/Next quarter, This year, or a custom from–to range); by mission vs
  provision; and by life sphere, project, product, activity, and tags (including "no tag"). Quick
  orphan and priority filters sit in the header. Your filter choices are remembered between visits.
- **Create, edit, and delete** events directly from the list — including the "this event / this and
  following / all events" choice when you change or delete a repeating event — using the same event
  editor as the calendar.

Available in **Russian and English**, in **light and dark** themes.

## Notes

- Frontend-only: no API, database, or calendar-grid changes; the page runs on the existing events
  endpoints.
- Viewing another person's shared calendar from this page is not included yet (it follows when
  shared-calendar context lands); the page shows your own events.
