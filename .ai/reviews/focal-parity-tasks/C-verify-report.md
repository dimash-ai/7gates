# Verify report — focal-parity slice 4 (Tasks editor/filters parity)

3-gate C. Scope verified: the full slice 4 = `git diff origin/feature/focal-migration...HEAD`
(base `0b4acd3`) — 4a (tasksFilters, TaskDialog, TaskInfoDialog, TasksPage filter/search panel) +
4b (recurrence + multi-participant backend, migration, gen:api, dialog wiring). 8 commits.

Verification was run as an adversarial multi-agent pass (2 suite runners + 4 scrutiny lenses
[security, data-integrity/migration, contract-regression, parity-vs-old-focal] + a coverage-gap
analysis, then a refute-pass over must-fix candidates), followed by builder-side fixes.

## What was scrutinized

- **Security & tenant-scoping** — new fields (`recurrence`, `contact_ids` JSONB, `other_participants`),
  the `TaskRead` after-validator, JSONB element-type coercion, the legacy `contact_id`→`contactIds`
  fallback, `user_id` filtering in `services/tasks.py`. No cross-tenant leak; Pydantic `list[str]`
  rejects non-string `contactIds` (422); the after-validator mutates only `self` and is idempotent.
- **Data-integrity & migration** — `9288e60e47ce` is additive (3 nullable columns) + reversible
  (downgrade drops in reverse), no server default; existing rows read NULL→normalized; update's
  `exclude_unset` setattr loop persists the 3 fields; the enriched LIST path
  (`_enrich` → `TaskRead.model_validate(...).model_dump()` → `EnrichedTaskRead.model_validate`) runs
  the same normalization idempotently. `alembic check` = "No new upgrade operations detected".
- **Contract-sync & regression** — `openapi.d.ts` matches the backend schema for
  TaskRead/Create/Update/EnrichedTaskRead; the events feature is unaffected. The CRM `ContactPicker`
  is intentionally UI-only (mirrors `CalendarPage.tsx:194-196`'s crm-boundary deferral): the save
  payload never sends `contactIds`, editing can't clobber a stored `contact_id`, and the crm/other
  toggle persists `otherParticipants` only in `other` mode (clears to null in `crm`). No silent loss,
  no half-wired state.
- **Parity vs old-focal** — TaskDialog/TaskInfoDialog/filters/recurrence/participants match
  old-focal; documented deferrals (drag-onto-calendar = slice 6, AI button = slice 12, contactIds
  persistence = crm-boundary ADR) are in scope per the design.

## Findings

26 findings raised across the lenses; **0 must_fix** after the refute pass (0 confirmed).
One real production parity defect surfaced and was fixed builder-side (gate-B in-session):

- **FIXED — project-type badge dropped on null `projectType` rows.** `TasksPage.tsx:163` rendered the
  type badge only when `projectType ∈ {mission, provision}`, so an orphan / project-less task (the
  common `projectType === null` row) showed **no** badge, whereas old-focal
  (`pages/Tasks.tsx:1324`) always renders one (mission, else the gray provision/"Other" badge).
  Fixed to always render, defaulting non-mission → provision — matching old-focal and the
  `TaskInfoDialog` default. Commit `5101eba`.

## Tests added / strengthened (verify doer)

- **Backend** `test_list_path_normalizes_recurrence_and_legacy_contact_id` — proves the enriched LIST
  path applies the same read-normalization as single-GET (recurrence→'none', legacy
  `contact_id`→`[contact_id]`), closing a coverage gap (only single-GET was covered). Commit `3fcd406`.
- **Client** `leaves the task untouched and keeps the dialog open when the schedule event fails to
  create` — covers the schedule create-before-delete failure branch (createEvent rejects →
  `errors.schedule` localized, `deleteTask` never called, dialog stays open), distinct from the
  already-covered partial-failure (delete-after-create) path. Commit `3fcd406`.
- **Client** the existing `projectType is null or unknown` row test was updated from asserting badge
  **absence** (which had locked in the regression) to asserting the provision badge **renders** for
  both null and unknown types, with mission absent. Commit `5101eba`.

The other 13 coverage observations were confirmed already covered (recurrence
invalid/null/clear/omit, contactIds null/non-string/[]/omit/legacy-both-set, otherParticipants
clear-with-null, schedule partial-failure, filter-options failure, filtered-to-zero, canEdit gating,
recurrence prefill, participant-toggle persistence, save-error draft retention, filter
storage/migration/corruption). One should_consider (list-path normalizer) was closed by the new
backend test above.

## Suite results (counts)

- **Backend** (`DATABASE_URL=...:5433`): `1711 passed, 13 failed, 1 skipped`. All 13 failures are
  PRE-EXISTING and NOT slice-4-caused — proven by the diff: none of the failing files
  (`test_ai_chat_routes_db.py` ×12, needing Redis/LLM env; `test_schemas.py::test_project_read_serializes_camelcase`
  ×1, the ProjectRead.icon fixture bug) nor their subject modules are in
  `git diff origin/feature/focal-migration...HEAD`. Slice-4 task tests all pass. `alembic check`
  clean; `ruff check` clean; `mypy app` clean (171 files). After the verify additions, the touched
  backend tests re-run `75 passed`.
- **Client**: `tsc --noEmit` clean; `biome check src` clean (268 files); `vitest run` =
  `78 files, 924 passed, 0 failed`; `vite build` OK (only the pre-existing repo-wide
  chunk-size advisory). i18n en/ru parity for slice-4 keys is exact (focal.tasks.* 103/103,
  focal.calendar.recurrence 5/5, contactPicker 11/11); the 18 ru-only keys are long-standing
  `_few/_many` plural forms, none in slice-4 scope.

## Verdict input

No must-fix defects remain. One parity bug found and fixed; three tests added/strengthened to back
the risky paths the per-slice gates missed. Whole change is green. Ready for the release gate.
