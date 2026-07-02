# Review Verdict

Reviewer: GPT Codex
Step: review
Score: 8.1 / 10
Status: BLOCKED

## Reason
The change is mostly scoped correctly and preserves the core task API paths, but there are concrete parity/accessibility defects in the row/header implementation. The tests cover happy-path parity but miss these regressions.

## Must Fix
- `apps/focal/client/src/features/tasks/TasksPage.tsx:104`: active rows always render a project-type badge and fall through to `provision` for `projectType === null` or any unknown string. The plan/design said `projectType` is `string | null` and to render no badge for values other than `mission`/`provision`; this mislabels untyped/orphan tasks as "Other".
- `apps/focal/client/src/features/tasks/TasksPage.tsx:204`: `colorFor` checks `productId` first and never falls back to `projectId` when the product id is absent from the `listProjects()` map. Product-linked tasks can lose their backed project color and show the primary fallback instead.
- `apps/focal/client/src/features/tasks/TasksPage.tsx:301`: the orphan-filter select uses `aria-label={t('focal.tasks.orphanFilters.all')}` ("All"/"Все") rather than a descriptive control name. `TasksPage.test.tsx:76` locks in that weak label, so screen-reader users cannot tell what the select controls.

## Should Consider
- `TasksPage.test.tsx` does not assert mutation invalidation, Add-button focus, null/unknown `projectType`, or project/product stripe color behavior.
- Removed tab/event behavior left stale `focal.tasks.tabs.*`, `weekEvents`, `summaryAll`, `summaryEvents` locale keys with no production usage.

## Tests Reviewed
Inspected task/plan/design, `TasksPage.tsx`, `TasksPage.test.tsx`, EN/RU locale keys, targeted OpenAPI snippets, old-focal references. `pnpm test:run` attempted but blocked by read-only sandbox EPERM.

## Release Risk
Medium
