# Codex Review Verdict

Score: 8.2 / 10
Status: BLOCKED

(Round 6 — first review of the realigned JSON-convention task, superseding the Markdown design of r1–r5.)

## Reason
The task is mostly bounded and aligned with the JSON inventory/checker convention, but a few structural requirements contradict `CONVENTIONS.md` or make the 39-table inventory impossible to validate cleanly.

## Must Fix
- `.ai/tasks/focal-data-mapping.md:44-45` requires every record’s `model.status` to be only `modeled` or `pending`, covering 18 + 13 tables, but `.ai/tasks/focal-data-mapping.md:86-94` requires all 39 `pgTable`s to have the extension fields. That leaves `sessions` plus the 7 AI tables with no valid `model` state.
- `.ai/tasks/focal-data-mapping.md:36-37` says `target` is “from the relocation enum” for both `transformed` and `relocated`, but `CONVENTIONS.md:15-16` defines transformed `target` as a change note and only relocated `target` as the enum.
- `.ai/tasks/focal-data-mapping.md:56-58` asks for Phase-7 AI context in `reason`, including `help_embeddings` as `relocated`, but `CONVENTIONS.md:19` allows `reason` only for `dropped` records.

## Should Consider
- Clarify the intentional split between D4 table disposition as `kept` in `.ai/tasks/focal-data-mapping.md:59-60` and existing CRM route disposition as `relocated` to `prima` in `routes.json:1443-1452` / `routes.json:1525-1534`.
- Explicitly mention the `help-embeddings-store` ADR slug for `help_embeddings`; it is present in `CONVENTIONS.md:37` but not named in the AI table guidance.

## Tests Reviewed
Inspected `.ai/tasks/focal-data-mapping.md`, `CONVENTIONS.md`, `routes.json`, `make_routes_inventory.py`, `_check_routes.py`, `check_routes.sh`, `README.md`, `MIGRATION_PLAN.md` §3a/6/8, `focal/shared/schema.ts`, and `superapp/apps/focal/server/app/models/`. Verified source counts: 39 Drizzle `pgTable`s and 18 SQLAlchemy model tables.

## Release Risk
Medium
