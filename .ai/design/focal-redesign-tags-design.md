# Design — focal-redesign-tags (slice 1)

Rewrite `apps/focal/client/src/features/tags/TagsPage.tsx`'s presentation + UI affordances to match
`apps/old-focal/client/src/pages/Tags.tsx`, **keeping** `api/tags.ts`, the React Query mutations, and
`TAGS_KEY = ['tags']` exactly (re-skin, not rebuild). Source of truth: old-focal `Tags.tsx`. Runs in
the `feat/focal-redesign-tags` worktree (slice-0 tokens present in the base).

## 1. Header — bespoke desktop-one-row / mobile-two-row, matching old-focal exactly

**Refinement of the plan** (which proposed the shared `PageHeader`): `PageHeader`'s outer row is a
**non-wrapping** flex row (`PageHeader.tsx:48`) and only its inner right group wraps
(`PageHeader.tsx:89`), so it **cannot** produce old-focal's required mobile **two-row** header
(`old-focal Tags.tsx:173`). The task mandates desktop-one-row / mobile-two-row (exact-old-focal wins
over the shell pattern), so the tags page keeps a **bespoke `<header>`** (it already has one) and
restyles it to old-focal's structure — rendering `<SidebarTrigger className="h-8 w-8 shrink-0">` (the
collapse toggle, sized per slice 0) and `<PageToolbar />` in the right cluster. **PageToolbar is how
the AI button (+ theme/lang) is preserved here, instead of via `PageHeader`** — so the gate-1/2 "keep
the AI button" requirement still holds.

Structure — a **single responsive container** (`flex flex-col … md:flex-row md:items-center
md:justify-between`), **not** duplicated desktop/mobile blocks (duplicated `hidden`/`md:hidden`
blocks both render in the test DOM — no CSS is loaded there — yielding duplicate controls + two
`PageToolbar`s that break role queries; a single container avoids that and stays DRY):
- **Title group** (`flex items-center gap-2`) = `SidebarTrigger` + `<h1>` `t('focal.tags.manageTitle')`
  (`truncate font-bold text-xl md:text-2xl lg:text-3xl`) + count `Badge`.
- **Controls group** (`flex flex-wrap items-center gap-2`) = `<PageToolbar />` + search
  (`flex-1 md:flex-none`) + Add `Button`.
- On **desktop** the two groups sit on one row (`md:flex-row` + `justify-between`); on **mobile**
  they stack into **two rows** (`flex-col`) — row 1 = toggle + title + count, row 2 = AI + search +
  add — matching old-focal's mobile two-row (`old-focal Tags.tsx:124,173`). The only minor deviation
  from old-focal: on **desktop** the count sits next to the title rather than at the far right (it
  rides in the title group so mobile row 1 is exact) — a visual-QA nit, not a structural one.
- **No icon badge** — old-focal's tags header has none.
- **Search**: an `Input` with a leading `Search` icon (`absolute left-2.5`), `pl-8 h-9 w-56` desktop /
  full-width mobile; a clear `X` ghost button (aria `focal.tags.clearSearch`) when `searchQuery` is
  non-empty. Drives `searchQuery`.
- **Add**: a primary `Button` (`Plus` + `t('focal.tags.add')`) → `setIsAdding(true)`.
- **Count**: `<Badge variant="secondary">{filteredTags.length}</Badge>`.

This is a deliberate, surgical reintroduction of the page's own header (the file already owns one); it
does **not** modify or fork the shared `PageHeader`/`PageToolbar` (those stay untouched — `PageToolbar`
is only *rendered*).

## 2. Search filter (client-side — `listTags()` takes no params)

`const filteredTags = useMemo(() => { const q = searchQuery.toLowerCase().trim(); return q ?
(tags.data ?? []).filter(t => t.name.toLowerCase().includes(q)) : (tags.data ?? []) }, [tags.data,
searchQuery])`. The count Badge and the list both read `filteredTags`. No API change.

## 3. Inline "Add tag" toggle (replaces the always-visible form)

State: `isAdding`, `newName`, `newColor` (init `PRESET_COLORS[0]`). The create `Card` renders **only
when `isAdding`**: `CardHeader` (`Plus` + `t('focal.tags.createNew')`) + `CardContent` with the swatch
grid (§5) + a name `Input` + an icon-only `Check` (confirm) and `X` (cancel). Confirm → existing
`createMutation.mutate({ name: newName.trim(), color: newColor })`; its `onSuccess` already resets +
invalidates `['tags']` — extend it to also `setIsAdding(false)`. Cancel → collapse + reset, no API.
Guard: `Check` disabled while `!newName.trim()` or `createMutation.isPending`.

## 4. List + edit-in-place

The list `Card` (`CardHeader`: `Tags` icon + title; `CardContent`) renders `filteredTags`. **Rows are
`<div>`, not `<ul>/<li>`** — matching old-focal `Tags.tsx:300` (so the existing test's
`getByRole('listitem')` at `TagsPage.test.tsx:91` must move to role+name / text queries; called out
here so it isn't mistaken for accidental drift).
- **View row**: color dot (`h-4 w-4 rounded-full`, `style={{ backgroundColor: tag.color }}`) + name +
  icon-only ghost `Pencil` (→ `startEdit`) and `Trash2` (→ `deleteMutation.mutate(tag.id)`).
- **Edit row** (`editingId === tag.id`): the swatch grid (§5) + a name `Input` + icon-only `Check`
  (→ `updateMutation.mutate({ id, name: editName.trim(), color: editColor })`, guard `!editName.trim()`)
  and `X` (→ cancel, local-only). Mutations + invalidation unchanged.
- States: `tags.isLoading` → centered `t('focal.tags.loading')`; `tags.isError` → centered
  `t('focal.tags.errors.load')`; `filteredTags.length === 0` → centered `t('focal.tags.empty')` (same
  copy for an empty list **and** a no-match search, like old-focal).

## 5. PRESET_COLORS swatch grid (verbatim from old-focal `Tags.tsx:22-23`)

`['#3b82f6','#22c55e','#ef4444','#a855f7','#f59e0b','#06b6d4','#ec4899','#8b5cf6','#14b8a6','#f97316',
'#64748b','#84cc16']`. Each swatch: `w-6 h-6 rounded-full border-2`, selected → `border-foreground`,
else `border-transparent`, `style={{ backgroundColor }}`, `onClick` sets the draft color. Replaces the
native `<input type="color">` in both add and edit.

## 6. a11y (deliberate, localized — NOT drift)

old-focal's icon-only buttons carry only `data-testid`. We **intentionally** add localized `aria-label`s
to every icon-only button (swatches, `Pencil`/`Trash2`/`Check`/`X`, the search clear `X`) — an a11y
improvement and what lets the tests target buttons by role+name instead of brittle testids. Reuse
`actions.edit/delete/save/cancel`; add `colorOption` (with the hex) and `clearSearch`.

## 7. i18n — `focal.tags.*` keys (ru + en) — copy must match old-focal, not the new app's current strings

**Add** under `translation.focal.tags` (verified absent in `en.json`/`ru.json` — no collision):
| key | ru | en |
|---|---|---|
| `manageTitle` | Управление тегами | Manage tags |
| `searchPlaceholder` | Поиск | Search |
| `clearSearch` | Очистить поиск | Clear search |
| `add` | Добавить тег | Add tag |
| `createNew` | Создать новый тег | Create new tag |
| `colorOption` | Цвет {{color}} | Color {{color}} |

**Change** the value of the existing `empty` key to match old-focal `tasks.noTags` — ru **"Нет тегов"**,
en **"No tags"** (it currently reads a longer "create your first one" message; only the *string*
changes, the key + its test reference stay). **Page title** uses the new `manageTitle` ("Управление
тегами"), because the existing `focal.tags.title` is "Метки"/"Tags" — that key is **kept, unchanged**,
for the **list-card** title (§4). Reuse existing `form.name/namePlaceholder`,
`actions.{edit,delete,save,cancel}`, `loading`, `errors.*`.

## 8. Keep the error banner

Retain the existing `errorMessage` + `onMutationError` banner (renders only on mutation failure;
doesn't conflict with old-focal's look) — a justified robustness retention over literal parity.

## 9. Tests (`TagsPage.test.tsx`) — prove the new interactions + preserved behaviour

Keep the existing API/invalidation proofs (list / empty / load-error / create-calls-API /
refetch-after-create / edit / delete / mutation-alert) and add: search filters + count follows
`filteredTags.length`; clear-`X` restores the list with **no** API call; add-card hidden until "Add tag";
swatch selection flows the chosen hex into `createTag`/`updateTag`; cancel add/edit is local-only (no
mutation); blank-name guards block submit. Target controls by role+accessible-name (the new aria-labels)
and visible text, not class/testid snapshots.

## 10. Verification + visual QA

`cd <worktree>/apps/focal/client && pnpm lint && pnpm typecheck && pnpm test:run && pnpm build` green.
Screenshot light + dark, desktop + mobile vs old-focal: the swatch grid, the inline add-toggle, the
search + clear, icon-only row actions, the count, and the **desktop-one-row / mobile-two-row header**
(§1) — the mobile two-row split is the thing to eyeball.

## 11. Failure modes / rollback

Carries the plan's Error & rescue map (`tags.list.failed`, `tag.{create,update,delete}.failed` →
existing `onMutationError` banner; `tags.search.noMatches` → empty copy; `tag.blank{Create,Edit}` →
disabled/guarded submit). **Rollback** = revert the four files (`TagsPage.tsx`, `TagsPage.test.tsx`,
`en.json`, `ru.json`); no API/data/contract state. Diff stays within those four files; `api/tags.ts`,
the `['tags']` key, OpenAPI types, `PageHeader`, and other pages are untouched.
