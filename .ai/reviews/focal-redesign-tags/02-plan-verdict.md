# Review Verdict

Reviewer: Opus
Step: plan
Score: 9.4 / 10
Status: APPROVED

## Reason
This is the minimum viable change for old-focal parity and every load-bearing claim checks out against source: `PageHeader` accepts `rightActions` and unconditionally renders `<PageToolbar />`, which contains the AI button (`PageHeader.tsx:24,91-92`, `PageToolbar.tsx:32-35`), so the "AI preserved, no duplicate" design is verified not assumed; the `isViewingOtherCalendar` deferral is correctly grounded (0 refs to `CalendarFilterContext`/`currentCalendar`/`dataOwnerId` in the new client, and `listTags()` takes no params → client-side search is forced); `PRESET_COLORS` match old-focal byte-for-byte (`Tags.tsx:22-23`). Scope is surgical (4 files), `api/tags.ts` + the `['tags']` key + OpenAPI types are explicitly untouched, i18n covers ru+en reusing existing keys, and the error/rescue map names each failure mode with where it's caught and what the user sees.

## Must Fix
None.

## Should Consider
- The plan adds `aria-label`s to the icon-only Pencil/Trash2/Check/X buttons (slices 3 & 4) that old-focal does **not** have — old-focal's icon buttons carry only `data-testid` (`old-focal Tags.tsx:352-368`). This is a justified a11y improvement (and necessary so tests can target buttons by role+name), and the plan localizes the labels, but it is a small deviation from literal "exact parity." Worth a one-line note in the design step so it isn't mistaken for drift.
- The existing test's `getByRole('listitem')` (`TagsPage.test.tsx:91`) depends on the current `<ul>/<li>` markup; old-focal renders rows as `<div>` (`old-focal Tags.tsx:300`). The plan's "update tests for changed markup" covers this, but the `<li>` → `<div>` structural change isn't called out by name — a trivial clarification.

## Tests Reviewed
Read existing `TagsPage.test.tsx` (12 cases) and the plan's proposed test list; each new test names a concrete assertion (search filters + count follows `filteredTags.length`, clear-X restores the list with no API call, add-toggle hidden until clicked, swatch value flows into create/update, cancel is local-only, mutation error preserves the active draft, blank guards). Validated against the binding contract and `api/tags.ts`. No suite executed (plan step).

## Release Risk
Low
