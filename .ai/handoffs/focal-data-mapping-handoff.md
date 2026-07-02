# Stage

Gate 5 — final release review for the `focal-data-mapping` feature
([task](../tasks/focal-data-mapping.md) · [plan](../plans/focal-data-mapping-plan.md)). The change is the
contract-freeze **`tables` inventory**, added under `superapp/apps/focal/docs/contract-freeze/` on
`feature/focal-migration` (additive; no app code touched).

# What changed

The frozen, column-level legacy→`focal.*` **data mapping** — the binding contract every Phase-1+ port
slice and the Phase-6 ETL build against — built to the existing `contract-freeze/` convention (it fills the
⏳ "Tables" row, mirroring the `routes` inventory):

- **`capture_schema_snapshot.py`** — read-only introspection of the legacy Focal **dev** DB catalog
  (`SET default_transaction_read_only = on`; never writes; password never persisted).
- **`schema-snapshot.json`** — the captured authoritative catalog: **39 tables / 536 columns**, per-table
  columns/types/nullability/defaults/PK/FK/indexes + rowcount band; provenance `{host_port_db, pg_version,
  captured_at}` (no credentials).
- **`_tables_mapping.py`** — the authored decisions (disposition / target / reason / `blocked_by`, model
  assignment, ownership ETL + RLS-visibility paths, identity, per-column overrides).
- **`make_tables_inventory.py`** — generator: derives each column's type/nullable/default/index_unique from
  the snapshot and applies the mapping → `tables.json` (cannot drift from the catalog).
- **`tables.json`** — the generated inventory (39 tables).
- **`_tables_discovery.py`** + **`_check_tables.py`** + **`check_tables.sh`** — the checker (`default` /
  `--coverage` / `--selftest`): re-derives from the snapshot, asserts table+column coverage, enum/conditional
  integrity, per-column completeness, **model reconciliation** of the 18 modeled tables against
  `app/models/*.py` (incl. inherited `TimestampMixin`), provenance match, and secret-scan.
- **`_fixtures/tables/`** — synthetic snapshot + models for the tamper-based selftest.
- **README.md / CONVENTIONS.md** — Tables row marked built; kept/broken counts; `tables.json`
  code-provenance vs the (deferred) DB-derived prod snapshot.

**Disposition split:** **37 kept** (31 ported to `focal.*` — incl. the 18 modeled tables — + 6 AI
logs/tokens deferred to Phase 7 via `blocked_by: ai-log-ownership`) · **1 relocated** (`help_embeddings` →
`qdrant`) · **1 dropped** (`sessions` — express-session store, unused under stateless JWT). 17 of the 18
modeled tables are 1:1 with legacy; only `users` drops 5 auth columns (`username`/`password`/`first_name`/
`last_name`/`profile_image_url` — Supabase owns identity).

# Files touched

13 files under `superapp/apps/focal/docs/contract-freeze/` (additive): `capture_schema_snapshot.py`,
`schema-snapshot.json`, `_tables_discovery.py`, `_tables_mapping.py`, `make_tables_inventory.py`,
`tables.json`, `_check_tables.py`, `check_tables.sh`, `_fixtures/tables/{schema-snapshot.json,
models/base.py, models/widgets.py}`, and modified `README.md` + `CONVENTIONS.md`.

# Tests run

```sh
cd superapp/apps/focal/docs/contract-freeze
./check_tables.sh --selftest     # tamper-based: one tamper per validate() rule
./check_tables.sh                # full: 39 tables match snapshot + reconciliation + secret-scan
cd ../../server && make verify   # app untouched
```

# Verification output

```
SELFTEST OK: clean fixture passes; all 36 checks caught.
check_tables OK (full): 39 tables match snapshot.
======================= 114 passed, 2 warnings in 5.09s ========================
```

# Still needs review / deferred

- **`schema-snapshot.json` is the legacy *dev* catalog** (read-only). The **prod** snapshot is deferred (no
  prod access at this stage). Drizzle-vs-DB drift is noted, not gated (per the README's known limits).
- **Open ADRs are recorded, not decided** — `crm-boundary` (CRM tables kept focal-local for now),
  `ai-log-ownership` / `ai-model` (Phase-7 AI tables), `sessions-table`, `help-embeddings-store`. The
  inventory states proposed dispositions + `blocked_by[]`.
- **Non-blocking gate-test follow-ups:** isolate two selftest tampers via pending tables; add a
  generator-roundtrip check (regenerate `tables.json` and diff vs committed).
- No secrets/PII in the inventory (snapshot provenance excludes the password; secret-scan clean).

# PR / release notes (for reviewers)

**Focal tables contract-freeze — column-level legacy→`focal.*` data mapping.**

Freezes the 39-table legacy Focal schema (sourced read-only from the live dev catalog) into a checked
`tables.json` inventory: per table, its disposition (kept/transformed/relocated/dropped) + ownership + RLS
paths + identity, and per column, its legacy→focal mapping with type/nullability/default/index fidelity. The
18 already-modeled tables are reconciled against the shipped SQLAlchemy models. A `check_tables.sh` gate
(with `--selftest`) keeps the inventory honest — no table or column can be silently dropped. This is the
contract the Phase-1+ ports and the Phase-6 data ETL build against. No app code or migrations change; no
secrets in the artifacts.

# Status

CODEX APPROVED (9.2 / 10) — final gate cleared. All gates ≥ 9.0 (task 9.2 · plan 9.3 · code 9.2/9.3 ·
test 9.1 · final 9.2). Committed to `feature/focal-migration` (not pushed). Non-blocking follow-up: the
generator-roundtrip checker path (gate-test + gate-final Should-Consider).
