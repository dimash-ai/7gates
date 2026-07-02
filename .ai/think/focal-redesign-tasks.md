# Problem

Re-skin the new Focal **Tasks page** (`apps/focal/client/src/features/tasks`, ~1.1k lines) to **exact
parity with `apps/old-focal`'s Tasks page** (`pages/Tasks.tsx`, 1465 lines + `TaskItem`/`TaskDialog`),
over the new app's **existing** tasks API, on top of the shell foundation (slice 0). Per the
`focal-redesign-pages` epic decision, old-focal is the binding contract.

Unlike slice 0 (a token cascade), this is a **structural** delta — old-focal and the new app draw the
Tasks page differently:

- **Tabs.** old-focal Tasks is **tasks-only**; the new app folds `all`/`events`/`tasks` into a 3-tab
  UI that mixes in week-events. Parity ⇒ remove the tabs (events get their own page — a later slice).
- **Filters.** old-focal has an **advanced collapsible panel** (search + sphere/project/product/
  activity/tag MultiSelect + 14 date presets + custom range); the new app has 3 header dropdowns.
- **Rows.** old-focal rows carry a **dual stripe** (left priority + top project-color), a **project-
  type badge** (mission/provision), and **edit + delete** buttons; the new app's rows are simpler
  (one stripe, a TaskLinkChips pill, delete only, no edit).
- **Create/edit.** old-focal uses a rich 26 KB **TaskDialog**; the new app uses an inline quick-add
  form and has no edit dialog.

The decisive de-risking fact: **the rows + filters are fully backable on the existing contract; the
only backend-blocked items are the dialog's `recurrence` + multi-participant fields (deferred with
this slice's dialog follow-up).** Verified `EnrichedTaskRead` exposes `isOrphan`, `orphanReason`, `projectName`,
`projectType`, `sphere`, `priority`/`priorityLevel`, `dueDate`/`dueTime`, `tags`, `projectId`/
`productId`/`activityId`, `isWorkTime`, `projectHasProducts`; and `api/{projects,products,activities,
tags,spheres}.ts` all exist. So the **rows and the advanced filters are fully backable**; the
create/edit **dialog is backable except** old-focal's `recurrence` and multi-participant
(`contactIds`/`otherParticipants`) fields, which the new **task** write-contract (`TaskCreate`/
`TaskUpdate`) does **not** carry — those live on *events*, not tasks — a **flagged backend gap** for
the dialog follow-up, not faked. The only real question is **how much to take in one slice** without
producing a diff too large to review at the ≥9.0 bar.

# Assumptions

- **[confirmed — epic decision]** Binding contract = old-focal Tasks page, exact, in light + dark,
  reproduced on the new stack (Tailwind 4 / React 19), over the existing API. Inherits slice 0's
  tokens (already on this worktree's base `afaaeba`).
- **[confirmed — openapi.d.ts]** `EnrichedTaskRead` carries every field old-focal's Tasks **rows +
  filters** read (orphan/orphanReason, projectName, projectType, sphere, priority/priorityLevel, due
  date/time, tags, project/product/activity ids, isWorkTime, projectHasProducts). **Caveat (write
  side):** `TaskCreate`/`TaskUpdate` lack `recurrence` + `contactIds`/`otherParticipants` (those are
  on the **event** schemas) → the *dialog*'s recurrence + multi-participant fields are a backend gap,
  flagged below. Rows + filters have **no** gap.
- **[confirmed — fs]** Filter-data clients exist: `api/{projects,products,activities,tags,spheres}.ts`
  → the advanced filter panel is backable (it's a frontend build, not a backend dependency).
- **[confirmed — inspection]** The new `features/tasks` is functional over `api/tasks`
  (`list/create/update/delete` + toggle) with `taskSort.ts` already a 1:1 parity port of old-focal's
  shared sort → this is a **re-skin + restructure over working data**, not a data rebuild. `taskSort`
  stays.
- **[confirmed — inspection]** The new app's Tasks page mixes in **week events** via its tab UI
  (`listEvents`); old-focal Tasks does not. Removing the tabs removes that coupling — events are a
  separate page (the epic's `focal-redesign-events` slice).
- **[confirmed — fs]** The new app has **no** task create/edit **dialog** (only the inline quick-add
  form); old-focal's `TaskDialog` is 26 KB. Full dialog parity is a large, separable chunk.
- **[unverified — settle at design gate]** the exact orphan grouping old-focal uses (orphans inline
  within "Active" via the amber treatment vs a separate section), the precise header desktop/mobile
  breakpoints, and whether `TasksPage.test.tsx` asserts the tab UI (it will need updating when tabs
  are removed). None blocks the framing.

# Options considered

The source is decided; the real fork is **how much Tasks parity fits one reviewable slice**.

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — Core slice now, filters + dialog as named follow-ups (chosen)** | This slice = page structure (drop tabs) + old-focal rows + Active/Completed grouping + header, on the existing CRUD (quick-add kept as an interim create path). Defer the advanced filter panel (`…-tasks-filters`) and the full TaskDialog (`…-tasks-dialog`) to dependent slices. | Each piece is surgical + independently reviewable at ≥9.0; delivers a recognizably-old-focal Tasks page immediately; the two deferrals are genuinely large + self-contained (MultiSelect panel; 26 KB dialog) and backable, so nothing is faked. | Full parity spans 3 slices, not 1; an interim quick-add diverges from old-focal until the dialog slice. |
| **B — One mega-slice (full parity at once)** | Rewrite TasksPage + add the filter panel + port the full TaskDialog in a single slice. | "Exact old-focal" in one shot. | 800–1000+ line diff across rows, a 5-query MultiSelect panel, and a 26 KB dialog — very hard to land at the ≥9.0 holistic-review bar; high regression surface; violates the slice discipline that worked for slice 0. |
| **C — Keep the new app's tabs, just restyle** | Recolor/round the existing tabbed page. | Smallest diff. | Not old-focal (old-focal has no tabs and is tasks-only) — fails the binding contract. Rejected. |

# Recommendation

**Option A.** Scope `focal-redesign-tasks` to the **Tasks page core**: remove the all/events tabs
(tasks-only, like old-focal); reproduce old-focal's **task rows** — **active** rows: dual stripe
(priority + project-color) + orphan amber treatment + **project-type badge** + **edit + delete**;
**completed** rows: `opacity-60` + line-through + **delete only** (no edit, no project-type badge,
per old-focal `Tasks.tsx:1415`) — the **Active/Completed** card grouping; and the **old-focal
header**: title + Add + help + **Filter** toggle + count badge **+ the always-visible orphan & priority
selects** (`Tasks.tsx:948`/`:960`), **explicitly deferring** the **AI-assistant button** (`:930` — AI
integration) and the **tag-manager button** (`:971` → the tags/filters follow-up). Wired to the
existing `api/tasks` CRUD + `taskSort` (unchanged). Keep the existing quick-add as the interim create
path. Defer two backable, self-contained chunks to named
dependent follow-ups so each stays reviewable:

1. `focal-redesign-tasks-filters` — old-focal's advanced collapsible filter panel
   (search + sphere/project/product/activity/tag MultiSelect + date presets/custom range), on the
   existing filter-data APIs; hangs off this slice's header Filter toggle.
2. `focal-redesign-tasks-dialog` — old-focal's TaskDialog create/edit for the **backable** fields
   (title, due date/time, priority, tags incl. create, project→product→activity, single `contactId`,
   description), replacing the quick-add. old-focal's **`recurrence` + multi-participant
   (`contactIds`/`otherParticipants`)** are a **flagged backend gap** (on the event contract, not
   `TaskCreate`/`TaskUpdate`) — a named backend handoff before those fields, not faked.

This mirrors the slice-0 lesson: small, surgical, gated. The rows + filters are capability-complete
on the contract; the dialog is too **except** its recurrence/multi-participant fields (the one real
backend gap, surfaced not faked). Each deferral is its own 7-gate slice.

# Out of scope

- The advanced **filter panel** and the full **TaskDialog** (the two named follow-ups above).
- The standalone **Events** page; per-task **tag/recurrence/participant** chips on the row (old-focal's
  Tasks row doesn't render them either — they live in the dialog).
- Any **server / API / schema / behaviour** change; re-deriving slice-0 tokens; the design/focal mockup.

# Open questions

- **Orphan grouping** — confirm at the design gate whether old-focal shows orphans inline within
  "Active" (amber dashed) or as a separate section; reproduce whichever old-focal does (inline,
  per inspection).
- **Interim create path** — keep the existing quick-add form (functional, lightly styled) until
  `…-tasks-dialog`, or hide create entirely behind an Add button that opens a minimal dialog now?
  Recommend keeping the quick-add as the interim (no lost capability); settle at plan.
- **Test impact** — `TasksPage.test.tsx` likely asserts the tab UI; removing tabs requires updating
  it (Step 6 authors the new assertions: rows, grouping, orphan/edit/delete, no events on the page).
- **Header breakpoints** — match old-focal's desktop/mobile split exactly; settle at design.

# Success criteria

- [ ] From `superapp-tasks/apps/focal/client`: `pnpm lint && pnpm typecheck && pnpm test:run &&
      pnpm build` green, with updated `TasksPage.test.tsx`.
- [ ] Tasks page matches old-focal in light + dark: tasks-only (no tabs), dual-stripe rows with
      orphan + project-type treatment + edit/delete, Active/Completed cards, old-focal header —
      screenshot-verified vs `apps/old-focal`.
- [ ] Behaviour preserved: list/create/toggle/delete work on real data; `taskSort` order unchanged;
      no regression beyond the intentional tab removal.
- [ ] Diff surgical to `features/tasks/*` (+ any new local row component); no API change; i18next
      ru + en; the deferred filters/dialog are flagged as backable follow-ups, not faked.
