# Plan: <slug>

Branch: <the brief's Branch>
Base: <the brief's Base>
Planned at: <the sha the plan was written against>

<!-- Step 2 of the co-dev flow (/step2): the stage map and every stage's detail, so that step 3 is
     implementation only. GPT writes it cold from the brief and the code; a blind Opus reviews it
     against harness/checklists/mvp.md. Under about 300 lines: stage 1's detail is the fullest, a
     later stage's detail is short, because the code will have moved by the time it is built and its
     builder records any departure. Re-planning (/step2 again, after the map changes) rewrites only
     the stages not yet started. Cite every claim about existing code as file:line. -->

## Decision
<!-- Two to five sentences: the approach for the whole feature, and each rejected alternative in one
     line with its reason. Push back here if the brief's stage 1 is not the smallest visible
     increment: say what is smaller. -->

## Stage map
<!-- One row per stage, in delivery order; stage 1 is the brief's MVP. Every stage is user-visible
     on dev, or a foundation of about two hours that the next stage uses (mvp.md §2).
     budget: hours of build, at most about four.
     risk: low (no schema change, no auth or tenant surface, no deletes), data (a migration, a
     backfill, deletes or rewrites of existing records), auth (authz, tokens, RLS, sharing). A data
     or auth stage gets one GPT review before it merges into dev; a low one ships on the builder's
     checks and CI.
     guard: how the stage stays safe on the shared dev environment until users are switched over:
     additive (nothing users have today changes), a hidden route, or a dev-only flag.
     demo: three to five steps a person follows on the dev environment to see the stage work; for a
     screen that also lives inside another app (Focal inside SURA) or on phones, the demo covers
     that place and that width too.
     covers: the brief's criterion ids. -->

| # | what users get on dev | demo on dev | budget | risk | guard | covers |
|---|-----------------------|-------------|--------|------|-------|--------|
| 1 |                       |             | ≤ 4 h  | low  | additive | US-1.1 |

## Stage 1 — <name>

### What the user gets
<!-- The map row, said in two or three sentences. -->

### Approach
<!-- The minimum that delivers it: what exists and is reused (file:line), what is added, and why.
     Climb the ladder in harness/checklists/ponytail.md before adding any surface. -->

### Files
| file | change | rung, for new surface |
|------|--------|-----------------------|
|      |        |                       |

### Tests
<!-- The demo path; a regression guard for every behaviour users have today that this touches; the
     repo's mandatory proofs (the migration sandbox, RLS assertions). Edge cases of the new feature
     beyond the demo path are follow-ups, listed under Not in this stage, not tests of this stage. -->

### Data and migrations
<!-- "None", or the revision: what it adds, its RLS and grants, its downgrade, and the sandbox proof
     (scripts/migration-sandbox.sh with the app's server dir and schema). Additive only. -->

### Not in this stage
<!-- What a reader might expect here and where it went: stage N, Not now, or a follow-up. -->

## Stage 2 — <name>
<!-- The same five headings, each in a few lines: What the user gets, Approach (with the file:line it
     builds on), Files, Tests, Data and migrations. Repeat for every stage on the map. -->

## Not now
<!-- The brief's Not now, plus whatever planning moved out of the stages; each a candidate
     follow-up ticket, one line. -->

## Rules and checks
<!-- The repo rules that apply to this feature (the AI-track markup, i18n ru and en, migrations with
     RLS and the sandbox proof, tenant isolation) and the jobs of .github/workflows/ci-<app>.yml
     that verify each stage. -->
