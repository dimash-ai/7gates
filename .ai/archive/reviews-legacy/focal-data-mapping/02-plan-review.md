# Codex Review Verdict

Score: 8.7 / 10
Status: BLOCKED

## Reason
The plan is mostly aligned with the task and actual codebase: the paths exist, the legacy schema has 39 `pgTable`s, the target models expose 18 modeled tables, and the proposed scope stays to docs/tooling with verification. It is blocked by one concrete spec mismatch in how `relocated` tables would be checked.

## Must Fix
- `.ai/plans/focal-data-mapping-plan.md:13-17` says `relocated` tables are treated like `deferred`/`retired` with disposition only and no column table, but `.ai/tasks/focal-data-mapping.md:43-46` defines `retained` / `transformed` / `relocated` as migrating tables that must carry the full header block and column table, and `.ai/tasks/focal-data-mapping.md:104-108` requires migrating completeness checks. Either remove `relocated` from the valid table path for this slice or make the checker enforce the migrating-table requirements for it.

## Should Consider
- `superapp/apps/focal/docs/contract-freeze/README.md:17` and `superapp/apps/focal/docs/contract-freeze/CONVENTIONS.md:51-65` still describe a future DB-catalog `tables.json` / `schema-snapshot.json` inventory using `check_tables.sh`; the plan should explicitly update or reconcile those docs so the new `DATA_MAPPING.md` checker is not confused with the older pending tables inventory.
- The checker self-test plan is good, but the implementation should keep the route-freeze precedent of a `--selftest` mode so negative fixtures can be exercised by one command, not only by manual temporary edits.

## Tests Reviewed
Read `.ai/tasks/focal-data-mapping.md`, `.ai/plans/focal-data-mapping-plan.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, `focal/shared/schema.ts`, `superapp/apps/focal/server/app/models/`, and the route-freeze tooling. Ran `rg -c "pgTable\\(" focal/shared/schema.ts` → 39; `rg "__tablename__ =" superapp/apps/focal/server/app/models/*.py | wc -l` → 18; `bash superapp/apps/focal/docs/contract-freeze/check_routes.sh --selftest` → passed, with sandbox xcrun cache warnings.

## Release Risk
Low
