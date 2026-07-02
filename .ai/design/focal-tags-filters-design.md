# Design: focal-tags-filters

<!-- The complete pre-build design for the 3-gate flow (gate A). -->

Traces to `.ai/notes/tags-page.md` (explore gate, decision **A3**, 2026-06-29).

## Problem & decision

The new Focal **Tags page** (`apps/focal/client/src/features/tags/TagsPage.tsx`) is management-only:
a list of name+color rows with create/edit/delete and a **single name-search** box
(`TagsPage.tsx:84-88`). The user wants it to have "filters like the Events page" — the Events page
has a rich persisted filter toolbar (`features/events/eventsFilters.ts:18-31`,
`EventsPage.tsx:545-832`).

The Events filter set keys on attributes an **event** has (sphere / project / product / activity /
date / priority / tag membership). A **tag carries only `{id, name, color}`** end-to-end — the model
also has `created_at` and `user_id`, but `TagRead` exposes neither (`server/app/models/tags.py:10-22`,
`schemas/tags.py`, `services/tags.py:74-81`). So the request cannot be a literal port; it must be the
same filter **UX language** applied to **tag-native axes**.

**Decision (A3, confirmed by the user):** build an Events-style filter toolbar on the Tags page over
the axes a tag actually has — **search + color + sort** (slice 1), then **usage (used/unused/count) +
sort-by-usage** (slice 2), then **created-date filter + sort-by-recent** (slice 3). Filtering stays
**client-side** over the already-authorized `GET /api/tags` list, exactly like Events/Tasks. The new
per-page filter module mirrors the existing `tasksFilters.ts` / `eventsFilters.ts` precedent.

**Alternatives rejected.** (1) *Literal port of the event axes* (sphere/project/date/priority onto
tags) — meaningless; a tag has none of those fields. (2) *Interpretation B — "browse entities by
tag"* (pick a tag → see its events/tasks with event filters) — this is a different, larger feature
and is **already covered**: the Events page (`EventsPage.tsx:730-739`, `NO_TAG`) and Tasks page
(`tasksFilters.ts`) already filter their lists by tag. (3) *Server-side tag filtering / a denormalized
stored usage column* — unnecessary surface and a migration; the list is small and counts compute live.

## Assumptions & scope

- Assumption (confirmed): Tag is `{id,name,color}` end-to-end; `created_at` exists on the model
  **`nullable=False`** (`models/tags.py:18-21`) — always present — and the SQL repo already orders by
  it (`services/tags.py:79`). Adding `usageCount` / `createdAt` to `TagRead` is **additive, needs no
  Alembic migration**.
- Assumption (confirmed): the wire is **camelCase**. Sibling Read schemas use a camel base
  (`ConfigDict(alias_generator=to_camel, populate_by_name=True, from_attributes=True)`, e.g.
  `schemas/tasks.py:15,116`), but the current `TagRead` does **not** (`schemas/tags.py` —
  `from_attributes` only; harmless while fields are single-word). Slices 2–3 must switch `TagRead` to
  that camel base so `usage_count`/`created_at` serialize as **`usageCount`/`createdAt`** to match the
  client. `to_camel` leaves `id`/`name`/`color` unchanged → backward-compatible.
- Assumption (confirmed): `MultiSelect` (`components/ui/multi-select.tsx` — `{value,label,color?}`
  options), `Select`, and `lib/datePresetRange` are reusable as-is; `tasksFilters.ts`
  (`STORAGE_KEY 'focal-tasks-filters'`) is the precedent for a new `tagsFilters.ts`.
- Assumption (confirmed): tags are referenced as JSONB string arrays in `calendar_events.tags`
  (`models/calendar.py:39`), `calendar_event_overrides.tags` (`:105`), `tasks.tags`
  (`models/tasks.py:25`), `bookings.tags` (`models/bookings.py:26`); legacy rows may store the tag
  **name** instead of its id (`eventsFilters.ts:177-184` normalises this).
- Assumption (confirmed): `GET /api/tags` is scoped to the active `calendarId` → owner server-side
  (`api/tags.ts:11-12`, dependency in `api/tags.py`).
- Decision (from explore, confirmed defaults for the usage count): count across **events (master +
  overrides) + tasks + bookings**; **exclude** CRM `contacts.tags`/`role_tags` (CRM relocates to PRIMA
  per the crm-boundary ADR); count a recurring series **once** (stored rows, not expanded
  occurrences); scope every count to the same owner as the tag list.
- **Reference-attribution rule (resolves the duplicate-name ambiguity).** Tag names are **not unique**
  (`tests/test_tags_db.py::test_duplicate_tag_names_allowed`). A stored reference is attributed to
  exactly one tag: an **id** reference → that tag id; a **name** reference that is not itself a tag id
  → the **most-recently-created tag sharing that name** (max `created_at`). This is exactly the
  precedence the client already uses to render legacy tags (`normalizeEventTags` builds a
  name→id `Map`, last-write-wins over the `created_at`-ascending list — `eventsFilters.ts:178-184`),
  so per-tag `usageCount` and the on-screen tag agree, and no reference is double-counted.
- **Date convention (slice 3).** Reuse the Events page convention exactly: the reference "today" is
  `toIsoDate(new Date())` (`EventsPage.tsx:111`), a tag's date is `toIsoDate(new Date(tag.createdAt))`,
  and the range comes from `getDateRangeFromPreset(preset, todayYmd)` (`lib/datePresetRange.ts`). No
  display-timezone math is introduced (Events itself uses the local browser date); `todayYmd` is
  passed into `filterTags` for testability. There is **no null-`createdAt` case** (column is NOT NULL).
- Out of scope: interpretation B (entities-by-tag view); CRM tag counting; per-occurrence recurring
  counts; server-side tag filtering; tag merge / bulk ops; any DB migration.
- Open questions: None blocking.

## Success criteria

<!-- These become the gate-C tests. -->
- [ ] **S1** Color filter narrows the visible tags to the selected colors; clearing restores all.
- [ ] **S1** Sort orders the list by name A→Z and Z→A; the active-filter badge and Reset behave like
      Events (reset clears advanced filters, keeps nothing tag-specific stale).
- [ ] **S1** Filters persist across reload via `localStorage 'focal-tags-filters'`; a corrupt/hand-edited
      entry falls back to defaults without crashing the page.
- [ ] **S1** Read-only (viewer) users can still filter/sort (read-only ops); create/edit/delete stay gated.
- [ ] **S2** `TagRead` serializes a camelCase **`usageCount`** that counts references across events
      (master+overrides) + tasks + bookings, attributes a legacy **name** reference to the
      newest same-named tag (per the attribution rule), is owner-scoped (no cross-owner leak), and
      counts a recurring series once.
- [ ] **S2** "Used / Unused / All" filter and sort-by-usage work off `usageCount`.
- [ ] **S3** `TagRead` serializes a camelCase **`createdAt`** (non-null); a created-date preset/custom
      filter narrows the list and sort-by-recent orders by it, using `todayYmd = toIsoDate(new Date())`
      passed into `filterTags`.
- [ ] Each slice leaves the tree green: client `lint && typecheck && test:run && build`; backend
      `make verify`; `openapi.d.ts` regenerated; `alembic check` clean (no migration).

## Build approach (slices)

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| 1 | **FE filter toolbar** (search+color+sort, persist, reset, badge) | `features/tags/tagsFilters.ts` (new), `features/tags/tagsFilters.test.ts` (new), `features/tags/TagsPage.tsx`, `TagsPage.test.tsx`, `client/src/i18n/locales/{en,ru}.json` (tag-filter keys) | corrupt localStorage crashes the page; color options drift from real tag colors | `filterTags` per axis + `load/saveTagFilters` validation/fallback; color-option derivation; sort; reset/active-count; component: color filter narrows + persists |
| 2 | **Usage count + used/unused** | `schemas/tags.py` (camel base + `usage_count`), `services/tags.py` (+ `StoredTag`, SQL aggregate; in-memory repo), `server/tests/test_tags*.py`, `client/src/api/openapi.d.ts` (regen), `tagsFilters.ts`/`TagsPage.tsx` (used/unused + sort-by-usage + count badge), tests | ambiguous dup-name attribution; cross-owner leak; N+1 / slow scan | backend: count across events+overrides+tasks+bookings, **dup-name → newest-wins**, owner-scoped, recurring-once, wire field is `usageCount`; FE: used/unused filter + sort |
| 3 | **Created-date filter** | `schemas/tags.py` (`created_at`, non-null, camel base), `services/tags.py` (mapping), `client/src/api/openapi.d.ts` (regen), `tagsFilters.ts`/`TagsPage.tsx` (date-preset via `lib/datePresetRange` + sort-recent), tests | local-date conversion of `created_at` | wire field `createdAt` exposed; `filterTags(...,todayYmd)` date-preset narrows via `toIsoDate`; sort-recent orders |

Slices are independently shippable and independently valuable (the build may stop after slice 1).
**Release shape:** one feature branch `feat/focal-tags-filters` (the dedicated worktree
`superapp-tags-filters`), one slice-commit each, a single PR into `feature/focal-migration` at gate C.

## Architecture & contracts

```
TagsPage  ── useQuery(listTags, calendarId) ──> GET /api/tags  (owner-scoped)
   │  filters state (useState<TagFilters>, persisted)
   │  showFilters toggle ─ MultiSelect(colors) · Select(usage) · Select(sort) · date-preset · Reset · badge
   └─ filterTags(tags, filters, todayYmd) ──> rendered rows   (client-side, like Events/Tasks)

tagsFilters.ts (new, mirrors tasksFilters.ts):
   TagFilters · DEFAULT_FILTERS · STORAGE_KEY 'focal-tags-filters'
   loadTagFilters/saveTagFilters (validate+fallback) · filterTags(tags,filters,todayYmd) · sortTags
   colorOptions(tags) · activeFiltersCount · resetFilters    (todayYmd = toIsoDate(new Date()))
```

| entity / interface | change | notes |
|--------------------|--------|-------|
| `features/tags/tagsFilters.ts` | **new** | `TagFilters { searchQuery; colors: string[]; usage: 'all'\|'used'\|'unused'; datePreset; dateFrom; dateTo; sort: 'name-asc'\|'name-desc'\|'usage-desc'\|'recent' }`; pure predicate + persist, shaped like `tasksFilters.ts` |
| `features/tags/TagsPage.tsx` | edit | add `showFilters` toggle + `MultiSelect`(colors) + `Select`(usage/sort) + date-preset + Reset + active badge; reuse existing search; **read-only gating unchanged** (filters are reads) |
| `TagRead` (`schemas/tags.py`) | **switch to the camel base** `ConfigDict(alias_generator=to_camel, populate_by_name=True, from_attributes=True)`; **+`usage_count: int`** (slice 2) → wire `usageCount`; **+`created_at: datetime`** non-null (slice 3) → wire `createdAt` | additive + backward-compatible (`to_camel` leaves id/name/color); `StoredTag` + `services/tags.py` mapping extended; in-memory repo updated for tests |
| `services/tags.py` SQL repo | edit (slice 2) | `list_for_user` computes `usage_count` per tag — a single owner-scoped aggregate over `calendar_events.tags`, `calendar_event_overrides.tags`, `tasks.tags`, `bookings.tags`. A reference matching a tag **id** → that tag; a **name** reference (not an id) → the **newest** same-named tag (max `created_at`), per the attribution rule. One round-trip (no N+1) |
| `GET /api/tags` | response grows | no new endpoint, no param change; regen `client/src/api/openapi.d.ts` (`pnpm gen:api`) so client types match |
| data model | **None** | no new tables/columns/indexes; `created_at` already exists; `usage_count` is computed. **No Alembic migration.** |
| reuse ladder | — | `MultiSelect`, `Select`, `lib/datePresetRange`, the `events/tasksFilters` pattern, and the page's existing search + calendar scope + count badge are reused; only `tagsFilters.ts` is new surface |

## Flow (happy + unhappy)

| path | trigger | handled where | result |
|------|---------|---------------|--------|
| happy — color filter | user picks color(s) in `MultiSelect` | `filterTags` (client) | list narrows to those colors; persisted to localStorage |
| happy — sort | user changes sort `Select` | `sortTags` | rows reorder (name asc/desc, usage-desc, recent) |
| happy — usage filter | user picks Used/Unused | `filterTags` over `usageCount` | list narrows; count badge shown per row |
| empty — no tags | account has no tags | existing empty state (`TagsPage.tsx:298-300`) | "no tags" message; toolbar inert |
| empty — filtered to zero | filters exclude all | existing empty branch | localized "no tags match" message; Reset restores |
| corrupt localStorage | bad/hand-edited JSON | `loadTagFilters` try/catch → defaults (mirrors `eventsFilters.ts:133-135`) | defaults applied, no crash, no banner |
| upstream — list error | `GET /api/tags` fails | existing `tags.isError` branch (`TagsPage.tsx:293-297`) | localized load-error; toolbar hidden/disabled |
| created-date filter | user picks a date preset (slice 3) | `filterTags(...,todayYmd)` compares `toIsoDate(new Date(tag.createdAt))` to `getDateRangeFromPreset(preset, todayYmd)` | list narrows by created date; `createdAt` is non-null so every tag has a comparable date |
| legacy name ref, duplicate names | an event/task/booking is tagged by a **name** shared by 2+ tags | repo aggregate resolves the name to the **newest** same-named tag (attribution rule) | the reference is counted once, toward the same tag the client renders (`eventsFilters.ts:178-184`) |
| security — viewer | read-only user filters | filters are reads; `canEdit` only gates mutations (unchanged) | filtering allowed; create/edit/delete still disabled |

## Test strategy, security & rollback

- **Test strategy.** *Unit (Vitest):* `tagsFilters.test.ts` mirrors `eventsFilters.test.ts` — each
  filter axis, `load/saveTagFilters` validation+fallback, `colorOptions`, `sortTags`,
  `activeFiltersCount`/`resetFilters`. *Component (Vitest + Testing Library):* `TagsPage.test.tsx` —
  color filter narrows, sort reorders, reset clears, filters persist across remount, a read-only user
  can still filter while create/edit/delete stay disabled. *Backend (pytest, real-DB rollback
  fixtures):* `usageCount` correctness across events (master+overrides)+tasks+bookings, a **legacy
  name-tagged row attributed to the newest of two same-named tags** (the attribution rule), a
  **cross-owner row that must NOT be counted**, recurring-counted-once, plus an assertion the wire keys
  serialize **camelCase** (`usageCount`/`createdAt`). *CI gate:* the client/server OpenAPI-drift check
  stays green (regen committed). **"Verified"** = `cd apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run &&
  pnpm build` green; `cd apps/focal/server && make verify` green; `uv run alembic check` clean.
- **Security.** The usage aggregate **must** be scoped to the tag owner / active `calendarId` exactly
  as `listTags` is — counting another owner's events/tasks/bookings is a cross-tenant leak (RLS is the
  second line). Queries are parameterized SQLAlchemy (no string-built SQL → no injection). No secrets,
  no PII, no new external surface; filtering runs client-side over already-authorized data.
- **Rollback.** Slice 1 is pure frontend → revert the commit. Slices 2–3 add **additive** `TagRead`
  fields → revert the commit and regen `openapi.d.ts`; there is **no migration to reverse**. No
  feature flag needed (additive, low blast radius); each slice is its own revertible commit.
