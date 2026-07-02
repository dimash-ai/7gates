# Findings: focal-migration-assessment

> Output of the **explore gate** (`/gate-explore`). Two independent takes — Opus and GPT —
> synthesized. Small and findings-first; raw per-model answers in `.ai/scratch/` (gitignored).
> Not scored. Date: 2026-06-27.

Topic: «что думаешь насчёт нашей миграции со старого фокал (`apps/old-focal`, Express/Node/Drizzle)
на новый фокал (`apps/focal`, FastAPI/Python/SQLAlchemy), folded into the 8-app superapp monorepo».

## Questions

1. Is the strategy (full Express→FastAPI rewrite + one-shot freeze→ETL→validate→flip cutover, no
   dual-write) the right call vs. alternatives?
2. Is the new architecture sound? Red flags?
3. How complete is it really (backend vs the two frontend epics), and what's on the critical path to cutover?
4. What are the top migration risks, ranked?
5. Is the timeline realistic (non-AI cutover ~2026-06-28, in-app AI fast-follow by 2026-07-10)?
6. Is the heavy `.ai` 7-gate / dual-model / per-slice process proportionate, or the bottleneck?

## Consensus

> Both models reached these independently. High confidence unless noted.

- **The strategy is the right default for this scale.** Full rewrite is *strategically* forced (the
  monorepo mandates one stack — `superapp/CLAUDE.md` Tooling), not aesthetic. One-shot
  freeze→ETL→flip beats dual-write/strangler here because blast radius is small (~163 users, ~800k
  rows) and a short freeze window is accepted; dual-write would add consistency risk across auth/DB/
  Google-watches/push/schedulers for little gain. Evidence: `docs/CUTOVER_RUNBOOK.md:29`,
  `docs/MIGRATION_PLAN.md:82`. Confidence: Medium-High (both).

- **The architecture is modern and sound — but app-layer authorization, not RLS, is the real
  load-bearing tenant boundary.** Both models independently flagged that the "RBAC + RLS two-layer"
  story oversells RLS: domain service sessions open fresh and only pin the RLS GUC when
  `TENANT_SCOPE_KEY` is set (`app/db.py:66`; services like `app/api/tasks.py:14` don't), so on the
  hot path the **only** boundary is the app-layer `WHERE user_id == effective_owner` chosen by
  `app/data_scope.py`. RLS is a dormant backstop there, not a live second line. **Implication both
  drew:** the single highest-value review is an independent audit of `resolve_data_owner` /
  `data_scope` correctness — it is the security boundary. Evidence: `app/rls.py`,
  `app/data_scope.py`, `focal-parity-data-scope-design.md:70,229`. Confidence: High (code).

- **Other architecture choices are correct.** Local ES256 JWT verification is fail-closed, checks
  iss/aud/claims (`app/auth.py:61`), PyJWT not python-jose. Celery Beat for all cron is right
  *provided exactly one Beat runs* — advisory-lock leader election was deliberately removed
  (`apps/focal/CLAUDE.md:65`, `app/celery_app.py`). Typed `AppError`, OpenAPI→TS generated client
  types, structlog+correlation-id are upgrades over legacy. Confidence: High.

- **Backend is ~done; the two frontend epics are at very different stages; "re-skin ≠ behavior
  parity."** Backend: 31 core tables migrated, full router surface incl. a *real* Google sync engine
  (`app/services/google_sync.py` — not a stub), ~1704 tests. Frontend splits into the **redesign**
  epic (re-skin, mostly done, visual-QA pending — `focal-redesign-*-handoff.md`) and the **parity**
  epic (functional-gap closure, **3 of 13 slices shipped**: shared-calendar context, data-scope,
  timezone foundation). Functional parity is explicitly *not* done — Tasks lacks editor/filter/
  recurrence/multi-participant (`focal-parity-tasks-design.md:11`), Events defers shared-calendar
  scoping (`client/src/features/events/EventsPage.tsx:117`). Confidence: Medium-High.

- **Critical path to cutover is execution, not backend features** — near-identical lists from both:
  (1) deploy + verify RLS on dev **and** prod (the RED blocker, `CUTOVER_RUNBOOK.md:16-17`; dev done,
  prod pending), (2) close cutover-relevant frontend functional gaps, (3) wire deploy/CI (ALL-210:
  Railway pre-deploy `alembic upgrade head`, Dockerfile uv/alembic fix, proxies, Supabase redirect
  URLs), (4) **rehearse the freeze** (only the forward ETL is rehearsed — `CUTOVER_RUNBOOK.md:104`),
  (5) rehearse rollback, (6) honor external-identity invariants. Confidence: Medium-High.

- **Top risks rank the same.** Highest: the authz/data-scope boundary (above). Then: RLS-not-on-prod;
  frontend functional parity gaps; freeze mechanics (unrehearsed read-only freeze + the **unguarded
  `--reset`** that truncate-cascades the target, `CUTOVER_RUNBOOK.md:39`); **external-identity hard
  invariants** — legacy Google OAuth client + VAPID keypair MUST be reused or every migrated refresh
  token / push subscription dies silently (`CUTOVER_RUNBOOK.md:71-78`); AI in-app deviation +
  provisioning (Qdrant/OpenAI env, corpus backfill). **Lowest: data fidelity** — ETL is rehearsed,
  idempotent, with documented skips (29 ownerless rows, 3 orphan users). Confidence: High (except
  external-service/ops state, which neither model can verify from the repo).

- **The non-AI 06-28 cutover is optimistic→unrealistic; the 07-10 AI fast-follow is more plausible.**
  The cutover gate (`CUTOVER_RUNBOOK.md:10-27`) demands full frontend migration + non-AI E2E + RLS
  dev&prod + deploy/CI + rollback rehearsal — several non-trivial items still open one day out.
  Phase-7 AI is largely backend-ported, so 07-10 is feature-plausible (pending provisioning/seeding).
  (Opus: "optimistic-to-slipping, two readings"; GPT: "unrealistic." Same direction.) Confidence:
  Medium.

- **The `.ai` pipeline is right for the irreversible tier and a likely bottleneck if applied
  uniformly.** Both: keep the full 7-gate adversarial flow for security / data / cutover / auth / RLS
  (it *found* the IDOR and hardened the data-scope design over 9 passes — real value); downshift
  reversible per-page parity slices to the 3-gate lite flow + a single cutover burndown. The plan
  itself flags one-engineer-vs-date risk (`MIGRATION_PLAN.md:688`) while mandating the heavy gates
  (`:706`). Confidence: High.

## Divergence

- **Is the `/api/ai/chat` IDOR live or fixed?** *(the headline — and it reconciles to an action)*
  - **Opus:** Fixed and merged — PR [#94](https://github.com/Allosta-Group/superapp/pull/94)
    (`0b4acd3`, data-scope slice 2) replaced the UUID-trusting resolver with an RBAC-gated one.
  - **GPT:** Live — `app/ai/chat_support.py:148` still accepts any UUID-shaped `userId` with no RBAC;
    GPT hedged *"if the fix is in unpulled commits, reassess."*
  - **Reconciled (verified):** Both are right about what they saw. The local working tree
    (`feature/focal-migration` @ `3e9fdd3`) is **2 commits behind** `origin` (`0b4acd3`). The fix
    commit is fetched into the object store but **not checked out** — so `chat_support.py:148-153` in
    the working tree still returns `body_user_id` unchecked → **IDOR live locally, fixed on origin.**
    A `git pull --ff-only` is blocked by 4 uncommitted files (`.gitignore`, `en.json`, `ru.json`,
    `dev.sh`).
  - **Decision/action for the user:** stash-or-commit those 4 files and `git pull --ff-only` so the
    local tree carries the security fix + all of slice 2. Until then, anything run locally (`dev.sh`,
    local testing) executes the vulnerable resolver. **This is the one concrete to-do this gate
    produced.**

- **How firm is "06-28 won't make it"?** Opus left two readings (benign: "full frontend migration" =
  the *redesign* epic, done, and parity is post-cutover polish → 06-28 tight-but-possible;
  concerning: audit-flagged parity gaps are user-visible regressions → slip). GPT was firmer
  ("unrealistic"). **Decision for the user:** make explicit *which* parity slices block the flip vs.
  are post-cutover hardening — that single mapping resolves the disagreement.

## Open

> Neither model could close these from the repo alone.

- **ALL-204 → parity-slice mapping.** Exactly which of the 10 remaining parity slices are pre-flip
  vs post-flip blockers. To close: the user's / Linear's definition of "full frontend migration done."
- ~~**Actual prod ops state.**~~ **RESOLVED via Railway (2026-06-27) — see "Live ops state" below.**
  Prod deploy is actively *failing*, RLS not applied.
- **Freeze + rollback drills.** Whether they've actually been rehearsed (runbook says only the
  forward ETL has). To close: confirm with the user.
- **Process-proportionality premise.** The "dial down the pipeline" recommendation assumes a ~solo
  migration. If the heavy gates double as a probation portfolio / learning artifact, the calculus
  shifts. To close: the user's intent.

## Live ops state (Railway `superapp`, checked 2026-06-27)

> Closes the "actual prod ops state" Open item. Read-only inspection of the Railway project.

- **🔴 `focal-prod` is FAILING to deploy — RLS is NOT applied on prod (the RED blocker is actively
  broken, not merely "pending").** All three prod services (`focal-prod`, `-worker`, `-beat`) are in
  FAILED state; latest attempt 2026-06-26 15:24 UTC deploying commit `0b4acd3` (the PR #94 IDOR-fix
  merge). `focal-prod` has **0 active deployments** — the new backend has never successfully run on prod.
- **Root cause (single, identical across all 3 services):** `asyncpg.ConnectionDoesNotExistError:
  connection was closed in the middle of operation` on `[SQL: GRANT focal_app TO CURRENT_USER]` — the
  RLS role bootstrap (migration `…5e7104e1aa66_focal_rls_core.py:63` and runtime `app/rls.py:163`).
  Both `focal-prod` and `focal-dev` have `DATABASE_URL` on the **`:6543` Supabase transaction pooler**,
  which the team's own runbook forbids: `CUTOVER_RUNBOOK.md:35` — *"Use the SESSION pooler (port 5432),
  NOT the transaction pooler (6543) — 6543 breaks asyncpg/alembic prepared statements."*
- **Why dev masks it:** `focal-dev` (web) = SUCCESS only because dev's DB is already at head (RLS
  applied manually 06-11), so its `alembic upgrade head` is a no-op and never runs the `GRANT`. But
  `focal-dev-worker` + `focal-dev-beat` are **also FAILED** on the same statement. Latent on dev, fatal
  on prod.
- **Confirmed on `superapp-prod` (read-only SQL, 2026-06-27):** `focal` schema exists with **34
  tables** (all created), but **0 RLS policies, 0 tables with RLS enabled, and the `focal_app` role
  does not exist**. `alembic_version` is stuck at `d8b68f67f1d5` (`user_activity_logs`, the last
  pre-RLS migration) — the next revision `5e7104e1aa66` (focal_rls_core, which creates `focal_app` +
  runs the failing `GRANT`) rolled back, so the RLS trio (core/rollout/sharing) + everything after
  never applied. Data tables are **empty** (0 rows in users/tasks/calendar_events/participants) —
  correct pre-cutover (ETL is a freeze-day step). `auth.users` = **169** (was 163 at the 06-08 auth
  migration; +6 since → a final auth delta may be needed at cutover).
- **⚠️ CORRECTION (2026-06-27, after the port flip): the pooler port was NOT the root cause.** The
  user set `DATABASE_URL` → `:5432` (session pooler) on prod; redeploy still **FAILED with the identical
  error** on `GRANT focal_app TO CURRENT_USER`. So `:5432` is correct per the runbook but was not the
  bug. **Real root cause:** the migration's `_grant_app_role()` (`…5e7104e1aa66_focal_rls_core.py:63`)
  + runtime `app/rls.py:163` run `GRANT focal_app TO CURRENT_USER` **as `postgres`** (the Supabase pooler
  role). On a fresh DB Supabase's `supautils` **kills the connection** on that privileged self-grant.
  **Proven by dev's `pg_auth_members`:** dev's `focal_app` has `postgres` as a member via TWO grants —
  one **`grantor=supabase_admin, admin_option=true`** + the migration's own `grantor=postgres`. So dev
  only worked because `supabase_admin` pre-granted membership WITH ADMIN OPTION first; the fresh prod DB
  never got that bootstrap. (Prod is PG 17.6.)
- **Real fix (dev-proven, no code change):** on `superapp-prod`, run the same privileged bootstrap used
  on dev — via the **write-mode Supabase MCP / Management API (executes as `supabase_admin`)**, NOT a
  plain `postgres` psql (which hits the same block): `CREATE ROLE focal_app NOLOGIN NOBYPASSRLS;` then
  `GRANT focal_app TO postgres WITH ADMIN OPTION;`. Then redeploy `focal-prod` → alembic's idempotent
  CREATE-ROLE is a no-op, the self-grant is now permitted, the RLS migrations apply, policies get
  created. This also unblocks worker/beat (their runtime self-grant then succeeds too). Build itself was
  always fine (Dockerfile uv/alembic fix present). A more durable alternative (developer-owned) is to
  change the migration so it doesn't depend on a `postgres` self-grant on a fresh Supabase DB.
- **Prod env is under-provisioned vs dev (runbook Step 2 hard invariants).** `focal-prod` is missing
  `GOOGLE_CLIENT_ID/SECRET`, `GOOGLE_REDIRECT_URI`, `WEBHOOK_BASE_URL`, `VAPID_PUBLIC_KEY/PRIVATE_KEY/
  SUBJECT`, `DASHBOARD_USER_EMAILS` — all present on dev. ⚠️ Per `CUTOVER_RUNBOOK.md:71-78` prod must
  reuse the **legacy** Google OAuth client + VAPID keypair (not dev's), or every migrated refresh token
  / push subscription dies — so these can't just be copied from dev.
- Net: makes Q5 firmer — a 06-28 non-AI cutover is not viable while prod can't even boot the backend.

## Round 2 refresh (2026-06-27, tool-verified — no new model round)

> Gate re-invoked with the same question. Round 1 was thorough and same-day, so this layer is a
> factual re-verification of the time-sensitive action items (git / Railway / Supabase), not a new
> Opus+GPT round — GPT runs offline and cannot see live ops state, so a second take adds nothing to
> a pure state check. Round-1 findings preserved above.

- **✅ Divergence #1 (the IDOR) is CLOSED.** Local `feature/focal-migration` is fully in sync with
  `origin` (`0 0` ahead/behind), HEAD `d9f9549` (PR #101 calendar-polish — *past* the `0b4acd3`
  IDOR-fix merge), working tree clean. The lingering `chat_support.py:148` `memory_scope_owner` is the
  *intentionally* unauthenticated conversation-cache keyer; its docstring now defers RBAC to
  `app.data_scope.resolve_ai_data_owner`. Round 1's one concrete to-do ("pull the local tree") is done.
- **🔴 The RED blocker (RLS on prod) is STILL OPEN — prod tried twice more, then went quiet.** After
  round 1's FAILED on `0b4acd3` (06-26 15:24Z), `focal-prod` FAILED twice more (19:39/19:43Z, commit
  `1bb4fa9`), then every deploy since — incl. HEAD `d9f9549` (06-27 03:33Z) — is **SKIPPED**: the
  failing auto-deploy loop was *silenced* (auto-deploy disabled / manual), not fixed.
- **Supabase-prod re-verified (read-only):** `focal_app` role **still absent**, **0** RLS policies,
  **0** RLS-enabled tables, `alembic_version` **still `d8b68f67f1d5`** (pre-RLS), `focal.users` 0
  rows, `auth.users` **169** (unchanged). The dev-proven privileged `focal_app` bootstrap (run as
  `supabase_admin` via the write-mode Supabase Management API) has **not** been applied — nothing
  about the blocker changed except that the noisy failures stopped showing.

## Round 3 (2026-06-29) — RED blocker RESOLVED ✅

> The prod RLS/deploy blocker is closed — verified live. The round-2 `supabase_admin` root cause was wrong.

- **✅ Prod RLS applied; all 4 prod services green.** `superapp-prod`: `alembic_version` moved
  `d8b68f67f1d5` → **`9288e60e47ce`** (head, == dev), **43 policies / 38 RLS-enabled tables**,
  `focal_app` exists, `postgres` has USAGE (`SET ROLE` works). `focal-prod` web/worker/beat/flower all
  **SUCCESS** on commit `d2d6600`; `focal-prod /health` → `{db:ok,redis:ok}`; **prima-prod unaffected**
  (200). `focal.users`=0 — correct (data ETL is the separate freeze-window step).
- **❌ The round-2 `supabase_admin` root cause was WRONG.** Proven on prod (rolled-back probes): the
  grant needs no `supabase_admin`. `supautils` kills `GRANT … TO postgres` **only over the
  asyncpg/SQLAlchemy prepared-statement protocol** (which alembic uses); over the **simple protocol**
  (psql/JDBC/DataGrip/raw asyncpg) it passes — *every* clause (plain / `WITH SET TRUE` / `WITH ADMIN
  OPTION`) is killed via SQLAlchemy, the same plain grant succeeds raw. Not the pooler port (`:5432` was
  already set), not `statement_cache_size`. (`WITH ADMIN OPTION` also fails with a plain Postgres error —
  the creator is already an admin member.)
- **The fix (durable):** (1) one-time bootstrap over the simple protocol (DataGrip): `CREATE ROLE
  focal_app NOLOGIN NOBYPASSRLS; GRANT focal_app TO postgres WITH SET TRUE;`. (2) migration guard
  (commit `d2d6600`, in `5e7104e1aa66` + `app/rls.py`): wrap the self-grant in `IF NOT
  pg_has_role(current_user,'focal_app','USAGE')` so alembic skips it when already granted; a fresh local
  Postgres (no supautils) still runs it. Full detail in memory `focal-rls`.

## Next

- **✅ Done (round 2):** local tree pulled to `origin/feature/focal-migration` (now `d9f9549`); the
  IDOR fix is present locally (Divergence #1 closed).
- **✅ DONE (round 3, 2026-06-29) — RED blocker resolved.** Bootstrapped `focal_app` on `superapp-prod`
  via DataGrip (simple protocol: `CREATE ROLE … ; GRANT focal_app TO postgres WITH SET TRUE`) + a
  migration guard (commit `d2d6600`); `focal-prod` redeployed green, 43 policies live. The round-2
  `supabase_admin` / `WITH ADMIN OPTION` recommendation was **wrong** — see Round 3 above.
- Could seed `/gate1-think` on a **cutover-readiness burndown** (the critical-path list above as
  explicit go/no-go gates) and/or a **process-tiering decision** (which slice types get the full
  pipeline vs the lite flow).
- The authz audit (independent pass on `resolve_data_owner`/`data_scope`) is the highest-value
  single review before flip.
