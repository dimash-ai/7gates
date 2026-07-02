# Findings: focal-migration-progress

> Output of the **explore gate** (`/gate-explore`). Two independent takes — Opus (Linear + git +
> Railway/Supabase live) and GPT (codex, offline, repo-only) — synthesized. Not scored. Date: 2026-06-27.
> Sibling of `focal-migration-assessment.md` (the qualitative verdict); this one quantifies done-vs-remaining.

## Questions
1. Decompose the migration into work-streams; % complete per stream, with evidence.
2. Single overall % — and is there more than one defensible denominator?
3. What concretely remains per stream — cutover-blocking vs post-cutover vs net-new?

## The progress bar

```
HEADLINE  (two honest denominators)
Code & config built      ████████████████████░░░░ 85%   ← what exists in the repo
Ready to flip to prod    ███████████████░░░░░░░░░ 63%   ← incl. live ops + cutover execution + E2E

STREAMS
Backend port               ███████████████████████░ 94%   done; only foc_ rebrand + CRM ADR deferred
In-app AI (Phase 7)        █████████████████████░░░ 88%   code+tests done; prod seed/env at cutover
Data, ETL & RLS (build)    ████████████████████░░░░ 85%   migrations authored, dev applied, ETL dry-run OK
Frontend re-skin+parity    ████████████████████░░░░ 83%   ~all pages shipped; visual-QA/E2E + a few parity gaps
Ops / Deploy / CI          ████████████░░░░░░░░░░░░ 50%   repo-config ~80% BUT live prod broken (RLS not applied)
Cutover exec (freeze→flip) ████████░░░░░░░░░░░░░░░░ 35%   tooling+dry-run done; freeze/flip/rollback drills unrun

NET-NEW (excluded — not old→new migration): Kanban (8), Mind-map-tasks (4),
Live-standard mindmap (2), Habbits extras (2) = ~16 issues, 0% — future roadmap.
```

## Consensus
> Both models independently. High confidence unless noted.

- **Backend is essentially done (~90-98%).** Every backend phase (0–5, 7, 8) is complete: ~31–34
  tables, a real Google two-way sync engine, ~1704 tests, full router surface. Evidence: Linear "Focal
  v1" — all Phase-0/1/2/3/4/5/7/8 issues Done; `server/app/main.py:76`, `models/__init__.py`. Only the
  `foc_` rebrand (ALL-209) + CRM-relocation ADR (ALL-202) are deferred. Confidence: High.
- **In-app AI (Phase 7) is code-complete (~88%) and is a non-blocking fast-follow.** Linear 9/9 Done;
  classifier + entity handlers + RAG + SSE chat + AIChat UI all exist (`ai_chat.py:187`). Remaining is
  provisioning: prod Qdrant seed, `OPENAI_API_KEY`, and an **AI-history ETL script that does not exist
  yet** (GPT: `migrate_ai_history.py` absent; `migrate_legacy.py:25` excludes it). Confidence: High.
- **The frontend is ~83% — most of it has shipped, but "shipped" ≠ "QA-passed".** ~27 frontend PRs merged
  (redesign re-skin + parity #92–#102); `client/src/App.tsx:51` routes cover every old-Focal surface; 20
  redesign + 11 parity handoffs. Remaining: light/dark **visual QA is "pending" across handoffs**, the
  **E2E/route-diff gate is unrun**, the `calendar-year` slice is design-only, and a few user-visible parity
  gaps live in the Linear "V1" backlog (recurring-events display, multi-day events, all-day tasks, tags
  filters, view-persistence). Confidence: Medium-High.
- **The remaining work is the cutover gate, not raw implementation.** Both reached this independently: the
  last mile is OpenAPI-vs-freeze **route-diff = 0** + green Playwright, **apply+verify RLS on prod**,
  finish **Deploy/CI** (Cloudflare `/api/*` + parked-Express `/api/ai-agent/*` proxies, Supabase redirects),
  **env carry-over** (Google OAuth client + VAPID hard invariants), and a **rehearsed freeze + rollback**.
  Evidence: `CUTOVER_RUNBOOK.md:10-27`. Confidence: High.
- **Two denominators are both legitimate** — "engineering build exists in repo" (~85%) vs "ready to flip to
  prod" (~63%). Both models split exactly here. The gap is *entirely* execution/verification/live-ops, not
  features. Confidence: High.
- **Net-new feature work is out of migration scope.** Kanban, Mind-map-tasks, Live-standard mindmap, Habbits
  extras (~16 Linear issues, 0% done) are future roadmap, not old→new parity — they should not drag the
  migration bar down. (Opus from Linear milestones; GPT from "net-new" classification.) Confidence: High.

## Divergence
- **Ops / Deploy / CI: how done is it?**
  - **Opus (live): ~45%.** Measured the live result — prod RLS NOT applied (`focal_app` role absent, 0
    policies, alembic stuck pre-RLS), focal-prod deploys FAILED×3 → now SKIPPED, prod env missing Google/VAPID.
  - **GPT (repo): ~80%.** Measured the artifacts — Dockerfile uv+alembic (`Dockerfile:22`), focal CI job
    (`ci.yml:124`), Railway pre-deploy alembic (`railway.toml:23`) — and explicitly noted it "cannot verify
    live state."
  - **Reconciled:** not a real disagreement — different denominators. The deploy *config* is ~80% built;
    the deploy *outcome on prod* is broken. Since live prod is verifiably down, the **flip-ready** number
    must weight the live state → I scored the stream **~50%** and the headline flip-ready bar at 63%.
  - **Decision for the user:** none on the number — but it confirms the one blocker (prod RLS bootstrap,
    tracked in `focal-migration-assessment.md`) is what moves this bar.
- **Cutover execution: 25% (Opus) vs 55% (GPT).** Same axis — GPT credits the runbook being concrete + ETL
  tooling built; Opus weights that the freeze/flip/**rollback drills are unrun**. Converges to: machinery
  ready, execution + rollback rehearsal pending. Synthesized at **35%**. No user decision needed.

## Open
> Neither closed these from their sources alone.

- **Route-contract parity (GPT's catch, unverified).** CRM/contact, admin fix-event-times, `/api/status`,
  project move/move-preview, push check-reminders "appear in the kept freeze but are not obvious in the new
  routers." To close: run the **OpenAPI-vs-freeze route diff** (`MIGRATION_PLAN.md:635`) — the gate wants 0
  unported non-AI routes. This is the single most load-bearing unknown in the frontend/backend bar.
- **E2E / visual-QA status.** Handoffs say visual QA is "pending"; is the Playwright page suite green? To
  close: run it (or the user confirms). Frontend % swings on this.
- **V1-milestone pre/post split.** Which of the 13 "V1" Linear items are flip-blocking parity gaps vs
  post-cutover polish — the same ALL-204 mapping open in `focal-migration-assessment.md`. To close: user/Linear.

## Next
- Numbers feed a **cutover-readiness burndown** (`/gate1-think`): the 63%→100% delta is a finite, listed
  set of gate items, not open-ended build.
- The one live blocker (prod RLS) is in `focal-migration-assessment.md` → "Round 2 refresh".
- Suggest the user move the 7 shipped frontend epics (ALL-211..216) out of "In Progress" in Linear — the
  tracker lags git by ~10 merged PRs, which is why a naive Linear read understates progress.
