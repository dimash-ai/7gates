# Problem

The **Tasks** page is the most-broken area in the parity audit: it is a read + quick-add + delete +
complete-toggle list with two header selects. The whole edit/detail surface is gone — the row pencil
is hardcoded `disabled` (`features/tasks/TasksPage.tsx`), there is no create/edit dialog
(`TaskDialog`), no detail dialog (`TaskInfoDialog`), the "Filter" button toggles nothing (no filter/
search panel rendered), and there is no schedule-to-calendar or inline tag-create.
old-focal's `components/TaskDialog.tsx` + `TaskInfoDialog.tsx` + `pages/Tasks.tsx` are the binding
spec. Slice 4 (focal-parity epic) restores task editing + filtering parity.

This slice **consumes the two foundation slices already merged**: slice 2 added `canEdit`/`dataOwnerId`
read-only gating + `calendarId` scoping to the Tasks page and the task API (`api/tasks.ts` already
threads `calendarId`); slice 3 added the timezone provider. Tasks use **wall-clock** `dueDate`/
`dueTime` strings, so timezone conversion is essentially N/A here — a task's due time is not zone-
bound (flag any place that turns out otherwise at design).

**Unlike most parity work, this slice is not fully frontend-only.** old-focal's task editor sets two
things the new FastAPI task contract lacks (confirmed in `server/app/schemas/tasks.py` +
`models/tasks.py`):
1. **Recurrence** — `none|daily|weekly|monthly|yearly` (no interval; that is an events-only concept).
2. **Multi-participant** — CRM `contactIds[]` **and** free-text `otherParticipants`; the new model has
   only a single `contact_id` and no `other_participants`.

Everything else the old-focal dialog edits already exists in the backend: title, description,
`due_date`, `due_time`, `project_id`/`product_id`/`activity_id`, `tags`, `status`/`completed`.
(old-focal deliberately **removed manual priority** — it's auto-derived from project type — so the
parity dialog has **no** priority control; the new quick-add's manual priority is cosmetic since the
backend recomputes `priority_level`.) So the editor, filter panel, schedule-as-event, and tag-create
are **frontend-only**; recurrence + multi-participant are a small, isolated **backend handoff**.

# Assumptions

- **[confirmed — `models/tasks.py` + `schemas/tasks.py`]** new `tasks` has description, due_date,
  due_time, tags (JSONB), single `contact_id`, goal_id, project_id, product_id, activity_id, status,
  completed, priority (auto). **Absent: recurrence, multi-participant.** No `other_participants`; only
  one `contact_id`.
- **[confirmed — slice 2 / `api/tasks.ts`]** `canEdit`/`dataOwnerId` gating and `calendarId` query
  scoping already landed on the Tasks page and the task API. The new dialog/filters/actions must
  consume them (disable + early-return on `!canEdit`; thread `calendarId`; project/product/activity/
  tag lookups must be `dataOwnerId`/`calendarId`-scoped like old-focal's `TaskDialog` queries).
- **[confirmed — slice 3]** timezone foundation exists; tasks are wall-clock, no tz conversion of due
  times. (old-focal `TaskDialog` does no tz math.)
- **[confirmed — audit + old-focal source]** the parity surface = `TaskDialog` (title, participants
  CRM/other toggle, due date + time, project→product→activity cascade, recurrence, single tag +
  inline create with color, notes, schedule-as-event), `TaskInfoDialog` (read + edit/delete/complete/
  inline-date), the filter panel (search; project-type / sphere / project / product / activity / tag
  incl. no-tag multi; date presets all/today/…/custom; `localStorage` `focal-tasks-filters` persist).
  The old Tasks page renders plain sorted rows (`taskSort`) with **no** drag reorder.
- **[confirmed — repo rules]** the recurrence/multi-participant model + Alembic migration is a
  **developer-owned** change; **I (interactive Claude Code) generate it under the user's review** at
  the gates (unattended agents may edit models only). Target = local Docker PG, applied manually after
  merge (per [[focal-superapp-db-wiring]]).
- **[unverified — settle at design]** whether to add `contact_ids` (list) **alongside** the existing
  single `contact_id` (back-compat) or migrate single→list; the exact recurrence column shape
  (a single nullable `recurrence` string, mirroring the source — no end-date for tasks).

# Options considered

| # | Option | What it is | Pros | Cons |
|---|--------|-----------|------|------|
| **A — split 4a frontend-only, then 4b backend handoff (chosen)** | 4a: `TaskDialog`+`TaskInfoDialog`+filter/search panel+schedule-as-event+inline tag-create over **existing** fields (recurrence + participant controls omitted until 4b). 4b: add recurrence + `contactIds`/`otherParticipants` (model+migration+schema+service+`gen:api`) and wire the two controls in. | 4a is shippable, no schema risk, big visible win, independently reviewable; isolates the DB change to a small focused 4b. Mirrors slice 2's proven 2a/2b split. | Two PRs; the dialog ships once without recurrence/participants, then gains them. |
| **B — backend-first, one slice** | Migration + full dialog incl. recurrence/participants in one PR. | One PR, dialog complete on first land. | Couples schema-migration risk with the large UI; blocks the whole visible win on the migration + `gen:api` cycle; a bigger, harder-to-review diff. **Rejected.** |
| **C — frontend-only, drop recurrence + participants** | Build the editor/filters but never add the two backend fields. | Smallest, zero backend. | Leaves a real old-focal behavior gap — contradicts the epic's "100% parity" goal. **Rejected.** |

# Recommendation

**Option A.** Ship **4a** (the editor + filter/search panel + schedule-as-event + inline tag-create,
all `canEdit`-gated and `calendarId`-scoped, on existing fields) first — it is the
bulk of the user-visible parity and carries no schema risk. Then **4b** adds the two missing backend
fields (task `recurrence` + multi-participant) as a small developer-owned model + Alembic migration +
schema/service + regenerated `openapi.d.ts`, and wires the recurrence + participants controls into the
dialog. Exact sub-slice boundaries (e.g. is the filter panel its own sub-slice) settle at the plan
gate; 4a may itself split if the diff is too large to review in one PR.

# Out of scope

- AI-assistant header button (slice 12); offline/optimistic mutations (slice 11). **No drag-drop on
  the Tasks page** — the old Tasks list is sorted via `taskSort`, not user-reorderable, and old-focal's
  draggable `TaskItem` lives in the **calendar** task panel (`TaskPanel`, drag-a-task-onto-the-grid),
  which belongs to the calendar slice (6), not here.
- Manual priority field (old-focal removed it).
- Event custom-recurrence with interval (events concept).
- Auth/landing (shared `@allosta/auth`).

# Open questions

- **4b ownership** — confirm I (interactive Claude Code) do the recurrence + multi-participant model +
  migration under your review (recommended), vs you do it and 4b only wires the client once it lands.
- **`contact_id` vs `contact_ids`** — keep the existing single column for back-compat and add a list +
  `other_participants`, or migrate single→list. Settle at 4b design.
- **Did old-focal persist these?** — confirm whether old-focal's own task backend actually stored
  `recurrence` / `contactIds` / `otherParticipants` (vs the dialog sending UI-only fields). 4b adds
  real persistence either way, but this decides whether it's a 1:1 port or a persistence enhancement.
  Verify at 4b design.

# Success criteria

- [ ] Framed as 4a (frontend-only, shippable) + 4b (backend handoff), each a 7-gate sub-slice tracing
      to this think doc; backend change explicitly developer-owned model + migration.
- [ ] At completion the Tasks page matches old-focal: create/edit dialog (all fields incl. recurrence
      + participants after 4b), detail dialog + actions, working filter/search panel with persistence,
      schedule-as-event, inline tag-create — all `canEdit`-gated + `calendarId`-scoped.
- [ ] 4b: recurrence + multi-participant land via model + autogenerated Alembic migration (`alembic
      check` clean) + schema/service + regenerated `openapi.d.ts`; no faked client fields before it.
- [ ] Each sub-slice green: client `pnpm lint && pnpm typecheck && pnpm test:run && pnpm build`;
      backend sub-slice also `make verify` + `alembic check`; ru + en; surgical diff.
