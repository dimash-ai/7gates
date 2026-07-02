# Findings: tags-page

> Output of the **explore gate** (`/gate-explore tags-page`). Two independent takes — Opus and GPT —
> synthesized. Small and findings-first; raw per-model answers live in `.ai/scratch/` (gitignored).
> Not scored. Date: 2026-06-29.

Goal: give the **Tags page** "filters like the Events page." What exists, what's missing.

## Questions

1. What are the Events-page filters, and how are they implemented (model, predicate, options, UI, persistence)?
2. What does the Tags page have today, and what does a Tag carry end-to-end (model → API → client)?
3. What does "filters like the events page" mean for a list of tags — which interpretation?
4. What's reusable vs missing (frontend + backend) for the recommended interpretation; is a migration needed?
5. Smallest viable PR slice vs the fuller version.

## Consensus

> Both models agree on every factual point and on the recommendation. Confidence High unless noted.

- **Events filters = a persisted client-side toolbar over events.** Model `EventFilters` (orphan, priority, projectType, sphere/project/product/activity ids, tagIds, search, datePreset, custom range) — `features/events/eventsFilters.ts:18-31`. Client-side predicate `filterEvents` over **server-enriched** events — `eventsFilters.ts:195-267`. Options derive from `projects`/`activities`/`tags` queries — `EventsPage.tsx:130-144`. UI = `showFilters` toggle + `Select`s + shared `MultiSelect` (`components/ui/multi-select.tsx`) + date-preset + active-count badge + reset — `EventsPage.tsx:545-832`. Persisted to localStorage with validation/migration — `eventsFilters.ts:80-145`.
- **Tags page today = CRUD + name-search only.** `features/tags/TagsPage.tsx:84-88` (search), `:240-369` (rows). End-to-end a Tag is **only `{id,name,color}`**: model has `id,user_id,name,color,created_at` (`server/app/models/tags.py:10-22`) but `TagRead` drops everything except id/name/color (`server/app/schemas/tags.py`; `services/tags.py:73-81`; `client/src/api/tags.ts:3-12`; `openapi.d.ts`). **`created_at` and `user_id` exist on the model but aren't exposed.** Old-focal's Tags page was also name-search-only — so the new page is already at legacy parity; the *Events page* is the real reference.
- **The Events filter set does NOT map onto a tag list.** Event filters key on attributes events/tasks have (date, priority, orphan, project hierarchy, tag membership); a tag row has only name + color. So "filters like events" must be reinterpreted, not literally ported.
- **Recommended interpretation: tag-native, Events-style filter *UX*** — same toolbar language (filter toggle, persisted state, active badge, reset, count) but axes limited to what a tag has: **search + color** now; **usage (used/unused/count)** and **created-date** as later add-ons. Both models rank this first.
- **"Filter events by tag" already exists** on the Events page (`EventsPage.tsx:730-739`, `NO_TAG`) and the Tasks page (`tasksFilters.ts`), so a "browse entities by tag" reading is largely redundant and should stay a separate, bigger feature — not this slice.
- **Reuse / missing / migration:** Reuse `MultiSelect`+`Select`, the localStorage validate pattern (`eventsFilters.ts:80-145`), the active-count/reset helpers (`eventsFilters.ts:270-299`), and the panel structure. Missing (frontend): a `tagsFilters.ts` model+predicate, the toolbar/panel in `TagsPage`, color-option derivation, **i18n keys** (none exist yet for tag filters — `en.json` tag block is CRUD/search only), and tests. **No DB migration is needed for any tier** — `created_at` already exists (expose = schema/service/OpenAPI only); a usage count is computed live from existing JSONB tag arrays. `EventFilters`/`filterEvents` themselves are event-specific and not reusable.
- **Slice plan (independently shippable):** **(1)** frontend-only — search + color filter + reset/active-count + persistence (`feat/focal-tags-filters`); **(2)** usage — backend exposes `usageCount`, page adds used/unused + sort-by-usage (no migration); **(3)** created-date — expose `created_at`, add date-preset via `lib/datePresetRange`; **(4)** the larger "entities-by-tag / analytics" view, kept separate.

## Decision (settled 2026-06-29)

> The models did not disagree; the one fork was a product-intent depth choice. **User chose A3.**

- **Depth = A3** — the full tag-native, Events-style filter set, built as 3 cumulative slices:
  **(1)** search + color filter + sort + reset/active-count + persistence (frontend-only);
  **(2)** `usageCount` + used/unused filter + sort-by-usage (backend aggregate, no migration);
  **(3)** created-date filter via `lib/datePresetRange` (expose `created_at`; schema/service/OpenAPI, no migration).
- **B (browse entities by tag) is out of scope** — separate, larger feature; the per-tag drill-down
  already partly exists on Events/Tasks.
- Because A3 includes usage (slice 2), the Open points below are now **required design inputs**, not optional.

## Open

- **Usage-count semantics** (if A2 chosen) — to close: decide *which* tag-bearing tables count and how recurrence is handled. GPT enumerated the surface: `calendar_events.tags` + `calendar_event_overrides.tags` (`models/calendar.py:39,105`), `tasks.tags` (`models/tasks.py:25`), `bookings.tags` (`models/bookings.py:26`), and CRM `contacts.tags`/`role_tags` (`models/contacts.py:43-44`). Open: do CRM `role_tags` belong to the same tag registry, and do recurring events count once (master/override rows) or per expanded occurrence?
- **Legacy name-vs-id tagging** — events/tasks may store tag *names*, not ids (`eventsFilters.ts:177-184`); any usage count must normalise id-or-name or it undercounts. Scope every count to the same `calendarId`/owner as `listTags` (no cross-owner leak).

## Next

- **Depth chosen = A3.** Seed **`/gate-design feat/focal-tags-filters`** (slice 1, frontend-only), then
  `feat/focal-tags-usage` (slice 2) and `feat/focal-tags-created-date` (slice 3). No Alembic migration on any.
- Proposed defaults to confirm at the slice-2 design (close the Open points): count usage across
  `calendar_events` (master + overrides) + `tasks` + `bookings`; **exclude** CRM `contacts`/`role_tags`
  (CRM is relocated to PRIMA per the crm-boundary ADR); count a recurring series **once** (stored
  master/override rows, not expanded occurrences); normalise id-or-name before counting; scope every
  count to the active `calendarId`/owner.
