# Summary
Reskin the new Focal Tags page to the old-focal interaction model while preserving the new app's typed tags API, React Query mutations, and `['tags']` invalidation key. The header will adopt the shared `PageHeader` with `icon={Tags}` and `rightActions` containing search, add, and count controls; `PageHeader` renders `PageToolbar` after those actions, so the existing AI-assistant button stays present without adding a duplicate per-page AI button. The old-focal `isViewingOtherCalendar` branch remains deferred because the new app has no backing calendar-filter context.

# Files to change
| path | change | why |
|------|--------|-----|
| `/Users/allosta/Desktop/superapp-tags-wt/apps/focal/client/src/features/tags/TagsPage.tsx` | Replace the bespoke header/body markup with old-focal-style search, inline add toggle, preset swatches, icon-only actions, filtered list, and `PageHeader` `rightActions`; keep `api/tags.ts`, mutation functions, and `TAGS_KEY = ['tags']` unchanged. | This is the binding UI surface for the tags redesign. |
| `/Users/allosta/Desktop/superapp-tags-wt/apps/focal/client/src/features/tags/TagsPage.test.tsx` | Update component tests for changed markup and add coverage for search/clear, add-toggle collapse, swatch selection, icon-only edit/delete, and mutation error retention. | The existing tests prove API behavior; they need to prove the new interactions too. |
| `/Users/allosta/Desktop/superapp-tags-wt/apps/focal/client/src/i18n/locales/en.json` | Extend `translation.focal.tags` with search/add-toggle/count/swatch accessible-label strings, reusing existing keys where they already fit. | New user-facing and accessible text must be localized. |
| `/Users/allosta/Desktop/superapp-tags-wt/apps/focal/client/src/i18n/locales/ru.json` | Add the same `translation.focal.tags` keys in Russian. | Keeps i18next complete for both supported locales. |

# Implementation slices
1. Add locale keys only.
   - Add the missing `translation.focal.tags` keys for search placeholder, clear search, count badge label, create card title, confirm add/edit labels, and color swatch labels.
   - Reuse existing `title`, `form.name`, `form.namePlaceholder`, `form.submit`, `actions.edit/delete/save/cancel`, `empty`, `loading`, and `errors.*` where they match.
   - Build should stay green because no component consumes the keys yet.

2. Move the page header onto `PageHeader` and add client-side search.
   - Import `PageHeader` and render it at the top of `TagsPage` instead of the local `<header>`.
   - Add `searchQuery` state and `filteredTags = useMemo(...)` over `tags.data ?? []`, using case-insensitive trimmed name matching like old-focal.
   - Pass `rightActions` as a responsive cluster: Search-icon input with clear `X`, Add tag button, and count `Badge` showing `filteredTags.length` when the query has loaded. `PageHeader` then appends `PageToolbar`, preserving AI/dark-mode/language controls.
   - Keep all API calls and mutations exactly as they are.
   - Update tests for rendered count, filtering, clear search, and toolbar/header-visible behavior via existing accessible controls rather than brittle class assertions.

3. Replace the always-visible create card with the old-focal inline add toggle.
   - Add `isAdding`, `newName`, and `newColor` state initialized from `PRESET_COLORS[0]`.
   - Add the exact old-focal `PRESET_COLORS` values: `#3b82f6`, `#22c55e`, `#ef4444`, `#a855f7`, `#f59e0b`, `#06b6d4`, `#ec4899`, `#8b5cf6`, `#14b8a6`, `#f97316`, `#64748b`, `#84cc16`.
   - The header Add tag button sets `isAdding(true)`; the inline card renders only while adding, shows 12 swatches with the selected swatch ringed, and uses icon-only Check/X buttons with accessible labels.
   - On successful create, keep the existing `createTag(input)` mutation and `invalidateQueries({ queryKey: TAGS_KEY })`, then collapse the card and reset name/color. On cancel, collapse and reset without a mutation.

4. Convert edit and row actions to the old-focal interaction pattern.
   - Replace native color inputs with the same swatch grid in edit mode.
   - Convert normal row actions to icon-only ghost `Pencil`/`Trash2` buttons and edit confirm/cancel to icon-only `Check`/`X` buttons with accessible labels.
   - Keep `startEdit`, `updateTag(id, { name, color })`, `deleteTag(id)`, and invalidation behavior intact. Cancel edit resets edit state without touching the server.
   - Use the filtered list for rendering, loading/empty/error states, and count. A no-match search uses the same empty copy as old-focal.

5. Final parity polish and verification.
   - Keep the existing mutation error banner because it only appears on failures and preserves the new app's robustness.
   - Confirm the `isViewingOtherCalendar` gate is not added or faked.
   - Run the focused test file first, then the full required client checks. Capture light and dark screenshots against the old-focal binding contract for visual parity.

# Tests
- `renders tags from the API`: proves `listTags()` still feeds the page and rendered rows use API data.
- `shows the empty state when there are no tags`: proves the empty list path still renders localized copy.
- `shows an error state when the list fails to load`: proves a rejected `listTags()` still reaches the localized load-error state.
- `filters tags by search query and clears the filter`: proves search is client-side over fetched data, the count follows `filteredTags.length`, and the clear `X` restores the full list without an API call.
- `keeps the add form hidden until Add tag is clicked`: proves the always-visible create card was replaced by the old-focal `isAdding` toggle.
- `creates a tag with the entered name and selected swatch color`: proves the create flow uses the swatch value and still calls `createTag({ name, color })`.
- `collapses and resets the add form after a successful create`: proves success clears add state and invalidates/refetches `['tags']`.
- `cancels add without calling the API`: proves the X button is local-only and resets draft state.
- `updates a tag through the inline editor with a selected swatch`: proves edit mode uses swatches, calls `updateTag(id, { name, color })`, exits edit mode on success, and refetches.
- `cancels edit without calling updateTag`: proves edit cancellation is local-only.
- `deletes a tag and refetches the list`: proves icon-only delete still calls `deleteTag(id)` and invalidates/refetches.
- `shows an alert when a mutation fails and preserves the active form/editor`: proves create/update/delete failures are caught by `onMutationError`, show the backend detail, and do not silently discard user input.

# Error & rescue map
| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
| `tags.list.failed` | `listTags()` rejects through React Query | `tags.isError` branch in `TagsPage` | Centered localized `focal.tags.errors.load`; no add/edit/delete mutation is attempted by the page. |
| `tag.create.failed` | `createTag(input)` rejects | `createMutation.onError -> onMutationError` | Existing alert banner with `focal.tags.errors.save` and backend detail; add card stays open with the drafted name/color. |
| `tag.update.failed` | `updateTag(id, patch)` rejects | `updateMutation.onError -> onMutationError` | Existing alert banner with backend detail; edit row stays available so the user can retry or cancel. |
| `tag.delete.failed` | `deleteTag(id)` rejects | `deleteMutation.onError -> onMutationError` | Existing alert banner with backend detail; the row remains because deletion is not optimistic. |
| `tags.search.noMatches` | None; filtered result is empty | `filteredTags.length === 0` render branch after a successful query | Same localized empty message as old-focal, with the search clear button available while a query is present. |
| `tag.blankCreate` | None; whitespace-only draft is invalid input | Add confirm button disabled and/or guarded before `createMutation.mutate` | The Check button cannot submit until the name has non-whitespace content. |
| `tag.blankEdit` | None; whitespace-only edit draft is invalid input | Save handler guard before `updateMutation.mutate` | The editor stays open and no PATCH request is sent. |

# Review lenses (pre-answer before gate2-plan)
- **Scope / strategy** — This is the minimum viable change for old-focal parity: one presentation component, its tests, and locale keys. Existing `api/tags.ts`, generated OpenAPI types, mutation functions, and `TAGS_KEY` remain the behavioral base. The decision is reversible by reverting these four files.
- **Architecture** — State stays local to `TagsPage`: `searchQuery`, `isAdding`, draft create fields, and edit fields. Data still enters through `useQuery({ queryKey: TAGS_KEY, queryFn: listTags })`; mutations still invalidate `['tags']`. Search is derived with `useMemo` and never changes the API contract.
- **Design** — `PageHeader` owns the page header and preserves `PageToolbar`, including the AI button. The tags-specific `rightActions` cluster supplies search, add, and count; it must wrap cleanly on mobile while remaining a single row on desktop. Loading, empty, load-error, mutation-error, add, edit, and no-match states are all explicit.
- **DevEx** — No new packages, routes, API modules, contexts, or abstractions. Constants and helper handlers stay inside `TagsPage.tsx` unless the implementation becomes unreadable; tests should prefer accessible names and visible behavior over class snapshots.

# Risks & migrations
- No database migrations, server changes, API schema changes, generated client changes, environment variables, or data backfills.
- Main risk: `PageHeader`'s generic flex wrapping may need careful `rightActions` classes to match old-focal's mobile two-row header while preserving `PageToolbar`. Rescue is to adjust only the `TagsPage` right-actions wrapper/classes; do not fork or edit `PageHeader`.
- Rollback plan: revert the four planned files; no persistent data shape changes are introduced.

# Scope check
- [x] Matches the task's Scope and Out of scope.
- [x] Small enough to review in one sitting.
- [x] Size smell checked: the page diff will be substantial because the binding contract changes structure, but it remains contained to one component plus tests and locale keys.

# Out of scope
- `isViewingOtherCalendar` gating, `CalendarFilterContext`, `currentCalendar`, `dataOwnerId`, or calendar-scoped tag queries; the new app has no backing concept for this branch.
- Any change to `api/tags.ts`, generated OpenAPI types, backend routes, schemas, or React Query key shape.
- A per-page AI button; `PageHeader` already renders `PageToolbar`, which contains the AI-assistant action.
- Other Focal pages, shell components, foundation tokens, or unrelated redesign cleanup.
