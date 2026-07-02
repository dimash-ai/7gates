# Stage

Stage 7: ship — `focal-parity` slice 2 (assistant-mode data scoping + read-only gating). PR from
`feat/focal-parity-data-scope` into the integration branch `feature/focal-migration`.

# What changed

Shared calendars let one user act inside another user's calendar. Before this slice, the backend
resolved every request to the *caller's own* data and gated writes only by a single uniform check —
so a shared participant either saw the wrong (their own) data on the owner's calendar, or could
write where their role shouldn't allow. This slice makes the **calendar owner** the effective data
owner for shared requests and authorizes each request by the caller's shared-calendar role, with the
client honoring the same boundary.

Backend (the authorization boundary):

- **Effective-owner resolution.** A new `data_scope` dependency resolves the effective data owner
  from an optional `calendarId` plus the caller's accepted shared-calendar role, gated per domain
  and action. With no `calendarId` it returns the caller and never touches the DB — own-data
  behavior is unchanged. The gates are **set-membership, not rank** (`developer`/`viewer`/`requester`
  share a rank but differ in what they may see/do).
- **Two gate domains.** *Calendar* data (events / calendar-init / bookings / meeting-requests):
  read = any accepted participant, write = `can_edit` (owner/full_access/editor). *Other pages*
  (tasks/projects/activities/mindmap/goals/spheres/time-budgets/tags/habits/…): read =
  `can_view_other_pages` (owner/full_access/developer), write = owner/full_access. This closes an
  `editor` over-grant (an editor can edit calendar events but cannot read or write the owner's
  non-calendar data).
- **Calendar scope invariant.** Shared-mode event/booking reads are filtered by the calendar's saved
  filter; a by-id read outside the filter returns 404 and a write returns 403. Series writes validate
  the effective recurrence occurrence, the master, and every override in the affected range; a
  `scope=all` delete additionally validates the entire recurrence group so a shared editor cannot
  cascade-delete an out-of-filter sibling master. Meeting-requests are scoped by `shared_calendar_id`.
- **AI IDOR fix.** The AI chat data-owner is now resolved through the same RBAC gate with a
  per-intent write gate, and owner-only calendar management is denied to delegated AI callers. (Full
  shared-calendar AI assistant mode is intentionally deferred to a later AI slice; this slice is the
  IDOR closure only.)
- **Delegated-write FK validation.** Other-pages writes validate that payload FK links
  (project/product/activity/parent-goal) belong to the effective owner, so a delegated write cannot
  inject the caller's own foreign keys into the owner's rows.
- **Non-mutating delegated reads.** A delegated time-budget read no longer get-or-creates the owner's
  settings + default categories; only an own-data read seeds.
- **Closed-partition guard.** A route-introspection test fails the build if any scoped router reverts
  to the raw caller or a new router is added without being classified.

Client (honoring the boundary):

- The selected shared calendar's id is threaded into the api wrappers and React Query keys, so
  cross-page data fetches request the owner's data and cache per-calendar.
- `canEdit` read-only gating across the affected pages disables mutating controls and skips the
  mutating call when the viewer lacks edit access on the shared calendar.

# Files touched

88 files (`+3992 / -787`): 34 server, 54 client.

- **Server — new:** `app/data_scope.py` (owner resolution + gates), `tests/test_data_scope_db.py`,
  `tests/test_calendar_scope_db.py`, `tests/test_route_scope_partition.py`.
- **Server — modified:** `app/api/*` routers (calendar, calendar_init, bookings, meeting_requests,
  ai, ai_chat, tasks, projects, activities, activity_instances, goals, spheres, mindmap, habits,
  habit_entries, tags, time_budgets, analytics, stats), `app/services/*` (shared_calendars, calendar,
  activities, activity_instances, goals, meeting_requests, calendar_init, time_budgets),
  `app/ai/chat_support.py`, and `tests/test_time_budgets_db.py`.
- **Client — modified:** `src/api/*` wrappers + `queryKeys.ts` + regenerated `openapi.d.ts`; the
  affected feature pages and their tests (calendar, events, calendars, tasks, projects, spheres,
  goals, habits, heatmap, meetings, budgets, analytics) plus shell/sidebar and the `ru`/`en` locales.

# Tests run

```sh
# Slice DB suites (local Docker Postgres + Redis)
cd apps/focal/server && uv run pytest \
  tests/test_data_scope_db.py tests/test_calendar_scope_db.py \
  tests/test_route_scope_partition.py tests/test_time_budgets_db.py \
  tests/test_time_budgets_crud_db.py -q
# -> 59 passed

# Full backend suite
cd apps/focal/server && uv run pytest -q
# -> 1704 passed, 13 failed  (all 13 pre-existing — see "Still needs review")

# Lint + types
cd apps/focal/server && uv run ruff check . && uv run mypy app
# -> All checks passed!
```

# Verification output

```sh
=== full backend suite ===
13 failed, 1704 passed, 5 warnings in 114.08s

=== slice DB suites ===
59 passed, 1 warning in 12.12s

=== closed-partition guard ===
tests/test_route_scope_partition.py: 3 passed

=== ruff ===
All checks passed!
```

# Still needs review

- **Security boundary is the whole point.** The domain service sessions bypass RLS, so the app-layer
  `WHERE user_id == effective_owner` filter is the only tenant boundary and `resolve_data_owner`
  picks that owner. Look hardest at: the role-set gates (accepted participation only; read vs write
  thresholds; set-membership not rank), the calendar scope-filter escapes (recurrence series,
  override range, delete-all group), and that **every** scoped endpoint routes through the resolver
  (the closed-partition guard enforces this).
- **The 13 failing tests are pre-existing**, not regressions: 12 in `tests/test_ai_chat_routes_db.py`
  require `OPENAI_API_KEY` (the chat classifier returns an error body without it), and 1 —
  `tests/test_schemas.py::test_project_read_serializes_camelcase` — is the base `ProjectRead.icon`
  missing-field bug. Both reproduce on the base branch and neither file is touched by this slice.

# PR / release notes (for users)

**Shared calendars now show and protect the right person's data.**

- When you open a calendar someone shared with you, every page now shows **that owner's** data — their
  events, tasks, goals, time budgets, habits — instead of your own, and only the events that the
  calendar's filter is set to show.
- What you can change depends on the access you were given: read-only roles can view but not edit;
  an "editor" can edit calendar events but cannot see the owner's non-calendar pages; full-access and
  the owner can do everything. Controls you're not allowed to use are disabled, and the app won't send
  a change it knows you can't make.
- Recurring-event edits and deletes on a shared calendar stay within what the filter shows — you can't
  accidentally reach or delete hidden occurrences of the owner's series.
- The AI assistant can no longer be used to read another user's data by supplying their id.
- **No change to your own calendars.** Working in your own data behaves exactly as before.

This is backward compatible and ships **no database migration**; rollback is reverting the code.

# Status

CODEX APPROVED (9.1) — final release gate passed. PR opened:
https://github.com/Allosta-Group/superapp/pull/94 (base `feature/focal-migration`).

Gate history: build 9.2 · review 9.2 · test 9.3 (after an 8.7 block fixed a test-isolation
collision) · ship 9.1. Client verification (biome/tsc/Vitest 828 passed/build) green before merge.
