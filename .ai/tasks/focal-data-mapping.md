> **AMENDMENT (2026-06-02) — DB-catalog sourcing (supersedes the Drizzle/deferred-snapshot premise below).**
> The user granted read-only access to the legacy Focal **dev** DB (Railway). The inventory is now sourced
> from the **live DB catalog** via read-only introspection (`SET default_transaction_read_only = on`; no
> writes/DDL/migrations) — the authoritative source per `CONVENTIONS.md`. **`schema-snapshot.json` is
> captured now (no longer deferred)**; discovery is catalog introspection, not Drizzle-TS regex (removing the
> parser-edge-case risk the plan flagged). Drizzle `schema.ts` is a cross-check (drift noted, not gated). The
> DB password is never persisted; snapshot provenance = `{host_port_db, pg_version, captured_at}`. Per the
> user's choice, the specs are amended for record and we proceed straight to implementation — review at
> gate-code, not a task/plan re-gate.

# Goal

Build the **`tables` inventory** of the Focal contract freeze — the column-level legacy→`focal.*` data
mapping — following the **established** `contract-freeze/` convention
([`CONVENTIONS.md`](../../superapp/apps/focal/docs/contract-freeze/CONVENTIONS.md) + the `routes` inventory
it mirrors). Deliverables sit beside the route freeze: `tables.json` (a source-grounded JSON inventory),
a `make_tables_inventory.py` generator, and a `check_tables.sh` / `_check_tables.py` checker with
`--selftest`. This fills the ⏳ **Tables** row in
[`contract-freeze/README.md`](../../superapp/apps/focal/docs/contract-freeze/README.md) and is the binding
contract every Phase-1+ port slice and the Phase-6 ETL build against; it operationalizes
[`MIGRATION_PLAN.md` §3a](../../superapp/apps/focal/docs/MIGRATION_PLAN.md).

> **Realignment.** This supersedes the earlier Markdown `DATA_MAPPING.md` design (gate-task r1–r5): the
> freeze must match the existing JSON-inventory convention — disposition model, enums, `source`/secret-scan,
> `--selftest` — not a parallel format/vocabulary. `check_tables.sh` is the name the convention already
> reserves for this inventory.

> **Source at this stage.** Sourced from the legacy **Drizzle schema** `focal/shared/schema.ts` (39
> `pgTable`s). The convention's DB-derived `schema-snapshot.json` (prod PG catalog: rowcounts, live
> columns) is **deferred** — no Supabase/prod access at this local stage; Drizzle-vs-DB drift is "noted,
> not gated" per the README's *Known discovery limits*. Everything is local Docker; no Supabase.

> **Paths are relative to the pipeline root** (where `.ai/` lives).

# Scope

**`CONVENTIONS.md` is the authority — do not redefine the vocabulary.** Reuse its disposition model
(`kept`/`transformed`/`relocated`/`dropped` + `target`/`reason`/`blocked_by[]`), the relocation-`target`
enum, the ADR-slug `blocked_by[]` enum, the `source`/provenance rule, and the secret-scan + `--selftest`
conventions.

- **`tables.json`** — JSON inventory `{ "tables": [...], "source": {...} }`, mirroring `routes.json`:
  - `source` = code-derived provenance `{repo:"focal", branch, commit}` (per CONVENTIONS §source).
  - One record per legacy `pgTable`, carrying the **standard inventory fields**: `name`, `source`
    (`focal/shared/schema.ts:<line>`), `disposition` ∈ {`kept`,`transformed`,`relocated`,`dropped`},
    `target` (required iff `transformed`/`relocated` — a **change note** for `transformed`, a value from
    the **relocation enum** for `relocated`), `reason` (required **only** for `dropped`), `blocked_by[]`
    (ADR-slug enum) — exactly per CONVENTIONS.
  - Plus the **`tables`-specific extension fields** below — required **only for the 31 tables ported to
    `focal.*` in Phases 0–5** (`disposition` `kept`/`transformed`). The 8 non-ported records (`dropped`
    `sessions`, the 7 Phase-7 AI tables, any `relocated`) carry the **standard fields only** and omit
    these; `model.status` ∈ {`modeled`,`pending`} applies only to the 31:
    - `columns[]` — **every legacy DB column**: `{legacy, focal, type, nullable, default, index_unique,
      disposition (kept/transformed/dropped), notes}`. DB column names (snake_case in Postgres, not the
      Drizzle TS property). `default` and `index_unique` are explicit (`null` or the value, never
      omitted); `notes` required for `transformed`/`dropped` columns.
    - `model` — `{status: "modeled" | "pending", focal_table, phase}`: `modeled` = one of the 18 tables
      in `app/models/`; `pending` = one of the 13, with its port phase.
    - `ownership` — `{etl: <owner column or FK path + null/orphan rule>, rls_visibility: [<all access
      paths>]}`. Record **all** access paths, not one — e.g. `shared_calendar_participants` lists calendar
      membership **and** role-based access; `contacts` notes nullable `created_by`/`updated_by` + the
      orphan rule; `interactions` is derived via `contact_id` → `contacts`; `event_contacts` is a join
      table scoped via `event_id`/`contact_id`.
    - `identity` — IDs retained (`focal.users.id == auth.users.id`, no FK into the `auth` schema), FKs
      retargeted to `focal.*`.
- **Dispositions for the non-ported tables** (using the real vocabulary, *not* "deferred"/"retired"):
  - `sessions` → `dropped`, `reason` = "express-session store; unused under stateless JWT" (`reason` is
    the `dropped`-only field; add `blocked_by: ["sessions-table"]` if that ADR is still open).
  - the **7 AI tables** (Phase 7) → a proposed disposition + `blocked_by` ADR slugs, **no `reason`**
    (`reason` is `dropped`-only): `ai_conversations` / `ai_agent_tokens` / `ai_agent_logs` /
    `ai_gateway_logs` / `ai_question_stats` / `ai_retrieval_logs` → proposed `kept`, `blocked_by`
    `["ai-log-ownership"]` (add `ai-model` where relevant); `help_embeddings` → `relocated`,
    `target: "qdrant"`, `blocked_by: ["help-embeddings-store"]`. Phase-7 context goes in a note field,
    **not** `reason`. Exact call per §6/§8 — gate-reviewed.
  - **D4** focal-local CRM **tables** (`contacts`/`interactions`/`meeting_requests`) → `kept`, `blocked_by:
    ["crm-boundary"]` (kept focal-local for parity now). Note the deliberate split: the CRM **routes** are
    `relocated` → `prima` in `routes.json` under the **same** `crm-boundary` ADR — the tables stay while
    the boundary is decided; that ADR reconciles both.
  - `dashboard_cohort_retention` is a **materialized view, not a `pgTable`** → it stays a *known limit* in
    the README (already noted), not a `tables.json` record.
- **`make_tables_inventory.py`** — derives the table+column skeleton from `focal/shared/schema.ts` via a
  shared discovery helper (mirror `_routes_discovery.py`); the disposition/target/model/ownership/identity
  layer is authored on top (exactly as `routes.json` layers auth + disposition over discovered routes).
- **`check_tables.sh` + `_check_tables.py`** (mirror `check_routes`): re-derive tables+columns from
  `focal/shared/schema.ts` and assert the inventory covers **exactly** them (no drift, as `check_routes`
  asserts call-site equality); validate the `disposition`/`target`/`reason`/`blocked_by` enums and the
  conditional-field rules per CONVENTIONS; run the secret-scan over `tables.json`; reconcile each
  `model.focal_table`’s columns against `app/models/*.py` **including `TimestampMixin`-inherited
  `created_at`/`updated_at`** (`base.py`); support `--selftest` (one tamper per failure mode → non-zero,
  clean copy → zero).
- **Reconcile docs**: flip the README **Tables** row from ⏳ to built, fill the Tables row in "Kept vs
  broken contracts", and state that `schema-snapshot.json` is deferred (no DB access yet).

# Out of scope

- **`schema-snapshot.json` / prod PG catalog** — deferred (no DB access at this stage).
- **Creating/changing SQLAlchemy models, RLS, ETL, Supabase, the AI subsystem/`foc_` API (Phase 7), route
  mapping** (already frozen in `routes.json`).
- **Deciding the open ADRs** (`crm-boundary`, `sessions-table`, `ai-*`): the inventory records *proposed*
  dispositions + `blocked_by[]`; it does not resolve them.

# Acceptance criteria

- [ ] `tables.json` exists, validates as JSON, and covers **all 39** `pgTable`s — each a well-formed
      record per CONVENTIONS (`disposition` from the enum; `target` = change-note for `transformed` /
      relocation-enum for `relocated`; `reason` only for `dropped`; `blocked_by[]` from the ADR-slug enum).
      The **31 ported** tables additionally carry the `columns[]`/`model`/`ownership`/`identity` extension
      fields; the 8 non-ported carry standard fields only. `source` = `{repo, branch, commit}`.
- [ ] Every legacy DB column appears in its table's `columns[]`, tagged `kept`/`transformed`/`dropped`,
      with `type`+`nullable` for non-`dropped`, explicit `default`/`index_unique`, and `notes` for
      `transformed`/`dropped`.
- [ ] The 18 `modeled` tables reconcile against `app/models/*.py` (incl. inherited timestamps); the 13
      `pending` tables each carry their phase; `sessions`/AI/D4 use real dispositions + `blocked_by[]`.
- [ ] `check_tables.sh` re-derives from `schema.ts`, asserts exact table+column coverage, validates the
      enums/conditional-fields, runs the secret-scan, and reconciles modeled tables against the models;
      `check_tables.sh --selftest` passes (non-zero on each tamper, zero clean).
- [ ] `contract-freeze/README.md` (+ CONVENTIONS if needed) reconciled: Tables row built, `schema-snapshot.json`
      noted deferred.
- [ ] `make verify` for the Focal service stays green (no app code changed).
- [ ] **Semantic correctness** (disposition choices, ownership/RLS paths, type mappings, ADR routing) is
      **gate-reviewed**, not asserted by the script (the script proves structure/coverage/enum-validity).

# Verification commands

```sh
# structural: re-derive from source, assert coverage + enums + model reconciliation + secret-scan
bash superapp/apps/focal/docs/contract-freeze/check_tables.sh

# the checker catches what it claims (tamper → non-zero, clean → zero)
bash superapp/apps/focal/docs/contract-freeze/check_tables.sh --selftest

# the running service is untouched
cd superapp/apps/focal/server && make verify
```
