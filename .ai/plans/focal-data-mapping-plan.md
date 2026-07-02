> **AMENDMENT (2026-06-02) — DB-catalog sourcing.** Source is the live legacy-**dev** DB catalog
> (read-only), not the Drizzle regex parser. Slice 1 adds `capture_schema_snapshot.py` (read-only
> introspection → committed `schema-snapshot.json`: per-table columns/types/nullable/defaults/PK/FK/indexes +
> rowcount bands; provenance sans password); `_tables_discovery.py` reads that **snapshot JSON** (stable)
> rather than `schema.ts`; the checker validates `tables.json` against the committed snapshot (offline at
> check time — no live DB in CI). This removes the Drizzle-parser risk. Everything else (vocabulary, slices,
> `--selftest`, `--coverage`, reconciliation, docs) stands. Proceeding to implementation (review at gate-code).

# Summary

Build the contract-freeze **`tables` inventory** as a JSON file + tooling that **mirrors the existing
`routes` inventory** (`_routes_discovery.py` → `make_routes_inventory.py` → `_check_routes.py` ←
`check_routes.sh`), in four small slices, **checker-first** so every later slice has a green-bar target.
The disposition model, enums, `source`/secret-scan, and `--selftest` come from
[`CONVENTIONS.md`](../../superapp/apps/focal/docs/contract-freeze/CONVENTIONS.md); the structure is derived
from the legacy Drizzle schema `focal/shared/schema.ts` (the prod `schema-snapshot.json` is deferred — no
DB access this stage). No app code, models, or migrations change. Task:
[focal-data-mapping.md](../tasks/focal-data-mapping.md).

## Decisions (resolving the Gate-1 r7 Should-Considers + the gate-plan r1 items)

- **Extension fields are scoped to the 31 ported tables.** `columns[]`/`model`/`ownership`/`identity` are
  emitted/validated only for `disposition ∈ {kept, transformed}` mapped to `focal.*`; the 8 non-ported
  records (`dropped` `sessions`, the 7 Phase-7 AI tables) carry standard fields only. The checker enforces
  "extension fields present **iff** ported".
- **Provenance is validated like routes.** `_check_tables.py` re-computes `{repo, branch, commit}` via the
  discovery module and fails on mismatch (mirrors `_check_routes.py:118-121`), and runs the same
  `SECRET`-regex scan over `tables.json`.
- **`--selftest` is mandatory** (per the convention + gate-plan r1): in-memory clean fixture + one tamper
  per failure mode, each asserted non-zero — no temp files (read-only-sandbox safe), exactly like
  `_check_routes.py:selftest`.
- **Model reconciliation is mixin-aware.** For `modeled` tables the checker resolves each model's columns
  **including `TimestampMixin`-inherited `created_at`/`updated_at`** (`app/models/base.py:16`) before
  comparing to `columns[].focal`.

# Files to change

| path | change | why |
|------|--------|-----|
| `superapp/apps/focal/docs/contract-freeze/_tables_discovery.py` | add | parse `focal/shared/schema.ts` → tables + columns (DB name, type, nullable, default, index/unique) + provenance; the structural truth, mirrors `_routes_discovery.py` |
| `superapp/apps/focal/docs/contract-freeze/make_tables_inventory.py` | add | generator: discovery + an authored disposition/mapping layer (a `MAPPING` table like routes' `DISPO`, column-overrides for transformed/dropped) → `tables.json`; mirrors `make_routes_inventory.py` |
| `superapp/apps/focal/docs/contract-freeze/_check_tables.py` | add | validator + `--selftest`; re-derive from source, assert exact table/column coverage, enum + conditional-field integrity, model reconciliation, provenance, secret-scan; mirrors `_check_routes.py` |
| `superapp/apps/focal/docs/contract-freeze/check_tables.sh` | add | thin runner (`exec python3 _check_tables.py "$@"`, sets `FOCAL_SRC`); modes: **default** (full), **`--coverage`** (structural only — JSON validity + source table/column coverage + enum well-formedness + provenance + secret-scan, skipping authored-completeness/reconciliation), **`--selftest`**; mirrors `check_routes.sh` |
| `superapp/apps/focal/docs/contract-freeze/tables.json` | add | the inventory (`{source, tables}`) |
| `superapp/apps/focal/docs/contract-freeze/_fixtures/tables/` | add | synthetic `schema.ts` + minimal models + a clean `tables.json` for the in-memory selftest (parallels the routes `_fixtures/src`) |
| `superapp/apps/focal/docs/contract-freeze/README.md` | modify | flip the **Tables** row ⏳→built, fill the tables row in "Kept vs broken contracts", note `schema-snapshot.json` deferred, and clarify (per `CONVENTIONS.md` §source) that the Drizzle-derived `tables.json` carries **code-provenance** `{repo,branch,commit}` while the DB-derived `schema-snapshot.json` stays DB-derived/deferred |
| `superapp/apps/focal/docs/contract-freeze/CONVENTIONS.md` | modify | one-line §source addition listing Drizzle-derived `tables.json` among the **code-derived** inventories (the DB-derived `schema-snapshot.json` stays deferred) — removes the future ambiguity |

No files under `server/app/`, `alembic/`, or any model/migration.

# Implementation slices

Each slice is independently reviewable (gate-code → fix loop) and has an **executable green command**
(below). Two invariants hold green every slice: `check_tables.sh --selftest` and `make verify` (no app
code). The full `check_tables.sh` (content completeness + reconciliation) is the slice-4 target; slices 2–3
gate on `--coverage` (structural), which is the per-slice green bar that earlier was missing.

1. **Discovery + checker + fixtures.** Add `_tables_discovery.py` (regex-parse `schema.ts` per `pgTable` +
   columns — DB name from the quoted arg, type, `.notNull()`→nullable, `.default(...)`, `.unique()`/index;
   `provenance()` = `{repo,branch,commit}` via `git -C focal`; **fail loud** on unparseable constructs),
   `_check_tables.py` (reuse `DISPOSITIONS`/`RELOCATION`/`ADR`/`SECRET`; `validate()` = source coverage
   (tables + columns) + standard-field enum/conditional integrity + **per-column field presence**
   (`legacy`/`focal`/`type`/`nullable` non-empty for non-dropped rows, explicit `default`/`index_unique`,
   `notes` on transformed/dropped) + `model` presence (`status` valid, `focal_table` non-empty for all
   ported, `phase` for `pending`) + `ownership`/`identity` presence + extension-fields-iff-ported +
   mixin-aware model reconciliation + provenance + secret-scan; `selftest()` = one tamper per validate()
   rule), `check_tables.sh` (with the
   `default` / `--coverage` / `--selftest` modes), and `_fixtures/tables/`. **Green:** `check_tables.sh
   --selftest` exits 0; `check_tables.sh` with no `tables.json` exits non-zero listing all 39 tables missing
   (the checker provably works before content exists).
2. **Generator + skeleton `tables.json`.** Add `make_tables_inventory.py`: discover, apply a `MAPPING`
   table (default `disposition: kept`, columns 1:1 legacy→focal), emit `tables.json` =
   `{source: provenance, tables:[…39…]}` sorted deterministically. **Green:** `check_tables.sh --coverage`
   exits 0 (valid JSON; all 39 tables + every column match source; enums well-formed; provenance; secret).
   (Full `check_tables.sh` still non-zero until authoring is complete — expected.)
3. **Author the 31 ported tables.** Fill `disposition` (`kept`/`transformed`), `target` (change-note for
   transformed), `model` (`status` + `focal_table` for **all 31** ported, `phase` for the 13 `pending`), `ownership`
   (ETL owner/path + null-orphan rule; `rls_visibility` lists all paths — `shared_calendar_participants`
   membership+role, `contacts` nullable owners, `interactions` derived via `contact_id`, `event_contacts`
   join), `identity`, and per-column `columns[]` (each tagged `kept`/`transformed`/`dropped`, explicit
   `default`/`index_unique`, `notes` on transformed/dropped). Set the **D4** focal-local CRM tables
   `contacts`/`interactions`/`meeting_requests` to `kept` + `blocked_by: ["crm-boundary"]`. **Green:**
   `check_tables.sh --coverage` still 0, and the full checker's mixin-aware reconciliation passes for the 18
   `modeled` tables (the 8 non-ported still pending → full run non-zero until slice 4).
4. **Author the 8 non-ported + reconcile docs.** `sessions` → `dropped` (+`reason`, `blocked_by:
   ["sessions-table"]`); the 7 AI tables → `help_embeddings` → `relocated`, `target:"qdrant"`,
   `blocked_by:["help-embeddings-store"]`, the rest `kept` + `blocked_by:["ai-log-ownership"]` (add
   `ai-model` where relevant), standard-fields-only; update `README.md` (Tables row built; snapshot
   deferred; `tables.json` code-provenance vs DB-derived snapshot). **Green:** full `check_tables.sh` 0;
   `check_tables.sh --selftest` 0; `make verify` for the Focal service green.

# Tests

- **`check_tables.sh --selftest`** is the executable proof the gate bites: it builds a clean in-memory
  fixture (passes), then applies **one tamper per rule `_check_tables.py:validate()` enforces** — each must
  exit non-zero. `validate()` enforces a rule for **every required field** in the task's acceptance
  criteria, so the tamper set is exhaustive: missing table, extra table, duplicate table; column drift
  (missing/extra legacy column); invalid table `disposition`; missing `target` on transformed/relocated,
  invalid relocated `target`, `target` on a non-transformed/relocated record; missing `reason` on
  `dropped`, `reason` on a non-`dropped` record; unknown ADR slug; **missing/empty `columns[].focal` on a
  non-dropped column**, missing/empty `columns[].legacy`, missing/empty `type`, missing/empty `nullable`,
  empty `default`, empty `index_unique`, invalid column `row-disposition`, missing `notes` on a
  transformed/dropped column; invalid/missing `model.status`, **missing/empty `model.focal_table` on any ported table (incl.
  `pending`)**, missing `phase` on a `pending` table; **missing `ownership.etl`**, **empty `ownership.rls_visibility`**, **missing `identity`**; extension
  fields present on a non-ported record, extension fields missing on a ported record; model/doc column
  mismatch (incl. a missing inherited `created_at`); provenance mismatch; leaked secret. *Proves every
  check is real — and that nothing in the acceptance criteria is left unenforced.*
- **Real run** (`check_tables.sh`, slices 1→4): non-zero while content is incomplete, zero only when all 39
  tables + columns are covered and reconciled. *Proves no silent table/column loss.*
- **`make verify`** stays green throughout — the guard that this is doc/tooling only.

# Error & rescue map

No runtime/app failure paths (no app code). The only failures are the checker's, surfaced to the
developer/CI, never to an end user.

| failure mode | error | caught where | what the developer sees |
|--------------|-------|--------------|--------------------|
| `pgTable`/column in `schema.ts` absent from / extra in `tables.json` | non-zero | `validate()` coverage | `table in source missing from inventory: <t>` / `column drift in <t>: <cols>` |
| Bad `disposition` / missing `target`/`reason` / `target` on non-relocated / `reason` on non-dropped | non-zero | `validate()` enum integrity | `<t>: bad disposition` / `<t>: relocated requires target` … (mirrors routes) |
| Extension field on a non-ported record, or missing on a ported one | non-zero | `validate()` ported-iff check | `<t>: extension fields present but disposition=dropped` |
| `columns[].focal` ≠ model `mapped_column` (incl. inherited) | non-zero | `validate()` reconciliation | `<t>: doc/model column mismatch: <cols>` |
| `blocked_by` slug not in the ADR enum | non-zero | `validate()` | `<t>: unknown ADR slug '<s>'` |
| provenance mismatch / credential-shaped token in JSON | non-zero | `validate()` provenance / secret-scan | `provenance mismatch …` / `credential-shaped token present` |
| `schema.ts` construct the parser can't read | non-zero + explicit parse error | `_tables_discovery` | `PARSE ERROR at <table>` (fail loud, never silently skip) |

# Review lenses (pre-answer)

- **Scope / strategy.** Minimum viable: clone the **proven** routes-inventory tooling for tables — no new
  pattern, no app code, no models/migration. Fully reversible (delete the added files). Checker-first makes
  the authored mapping goal-driven. `schema-snapshot.json` deliberately deferred (no DB access).
- **Architecture.** Three-source cross-check (legacy `schema.ts`, target `app/models/*.py`, the inventory),
  exactly like routes' source↔inventory equality. Structural/semantic split is explicit (script = coverage
  + enums + reconciliation; gate = disposition/ownership/type correctness). Unhappy path: unparseable
  Drizzle construct **fails loud**, never under-counts.
- **Design.** No UI. N/A.
- **DevEx.** `check_tables.sh` sits beside `check_routes.sh` with the identical shape + `--selftest`, so
  zero new cognitive load; `README.md` documents it; the inventory becomes the single reference for Phase-1+
  ports and the Phase-6 ETL.

# Risks & migrations

- **No DB migration, no app code, no data movement** — risk surface is the Drizzle parser only.
- **Regex parsing of `schema.ts`** could miss an unusual column/table construct. Mitigation: mirror the
  proven `_routes_discovery.py` approach; **fail loud** on unparseable constructs; the `_fixtures/tables/`
  schema includes the real edge shapes (multi-line `uniqueIndex(...).on(...)`, expression indexes like
  `focal/shared/schema.ts:1599`) so the fail-loud path is exercised before the real pass; slice-1's real
  run asserts all **39** tables are found (a miscount surfaces immediately); `--selftest` proves the checks.
  Rollback: pure additive docs/tooling — delete the files; the running service is unaffected.
- **`schema-snapshot.json` deferred** — the inventory's dispositions are Drizzle-sourced now; prod rowcount
  signals + live-column drift wait for DB access (noted in README, per the existing *Known discovery
  limits*). Not a regression — it matches the convention's "DB catalog is authoritative … drift noted, not
  gated."

# Scope check

- [x] Matches the task's Scope / Out of scope (JSON inventory + checker mirroring routes; semantics → gate;
      no models/RLS/ETL/Supabase/AI/route-mapping; snapshot deferred).
- [x] Small enough to review in one sitting — **per slice**; four slices, each leaving `check_tables.sh` in
      a known state.
- [x] Size smell: `tables.json` is large (39 tables) but that's irreducible inventory content; the tooling
      is a clone of an existing, reviewed pattern — no new service/abstraction.

# Out of scope

- `schema-snapshot.json` / prod PG catalog (deferred — no DB access); creating/changing SQLAlchemy models,
  migrations, RLS; any ETL / data movement (Phase 6); Supabase provisioning/deploy or D1/D2; the AI
  subsystem + `foc_` API (Phase 7); route/contract mapping (already frozen in `routes.json`); resolving the
  open ADRs (the inventory records proposed dispositions + `blocked_by[]`, it doesn't decide them).
