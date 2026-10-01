# Brief: <slug>

Branch: <Linear gitBranchName, else the app's convention: feat/focal-<slug> for Focal, feature/<slug> or fix/<slug> elsewhere>
Base: dev
Linear: <ALL-id — url, or none>
Depth: <quick or full>
Date: YYYY-MM-DD
Pinned: <the sha the step-1 worktree block printed>

<!-- Step 1 of the co-dev flow (/step1). The ONE document the planner (GPT, /step2) works
     from, cold: it never saw the conversation. So no "as discussed", every fact carries file:line
     or a URL, the contract comes first and the open questions come last.
     It says WHAT and WHY, never HOW. No solution design: if the brief already holds a design, the
     planner restates it instead of planning, and the cross-model plan is lost. Evidence that
     something already exists and should be reused is a finding, not a design.
     Written in English; the requester's own words stay verbatim in their language.
     The header is machine-read: one key per line, a plain value with no backticks or bold, filled
     in before the step-1 worktree is created. Branch and Base decide the worktree every step works
     in; Pinned records the commit the research and the plan describe. Every slug has a branch of
     its own. -->


## Product brief
<!-- product.md below its header, pasted verbatim: the In short, the user stories, who it is for,
     the benefit, the unhappy paths, the business side, the out of scope, the questions and answers,
     the sources and the requester's own words. Its sections follow this comment as they are. Both
     researchers were given it as the requester confirmed it in 1a; the answers of 1d amend it. -->

## Acceptance criteria
<!-- The contract for the plan (every one traces to a slice) and for the release pass (every one
     names a test). Every criterion of the user stories above, by its id (US-1.1 ...), then any
     criterion the research added that no story covers (R-1 ...), each naming the finding it came
     from. Observable and testable: "works correctly" is not a criterion. -->
- [ ]

## Scope
<!-- What IS included, by story (US-n), specific to modules, screens, endpoints. -->

## Out of scope
<!-- What is explicitly NOT included beyond the product brief's Out of scope, including tempting
     neighbours the research found. -->

## Decided — do not reopen
<!-- Decisions already made, who made them, and when. The planner builds on these, not around them. -->

## Findings
<!-- Merged from research/opus.md and research/codex.md by UNION. Tag every item [O] Opus only,
     [G] GPT only, or [both]. Sweep wide, report narrow: an item earns its place only if the planner
     could make a DIFFERENT decision because of it. Quick depth fills Territory, Prior art, Tests and
     Scars; full depth fills all six. -->

### Territory
<!-- What this touches: modules, routes, tables, migrations, config, tests. A candidate blast radius. -->

### Prior art
<!-- What already exists and should be reused, each item with its ladder rung number
     (harness/checklists/ponytail.md): 2 this codebase, 3 the standard library, 4 the platform,
     5 an installed dependency. Prior art that already covers the whole intent was asked about. -->

### Constraints
<!-- Pinned versions READ FROM the lockfiles (say which file). Contracts this must not break. The
     superapp rules that govern this surface: AI-track code (exoskeleton + LDD) or not, a migration
     (sandbox proof) or not, user-facing strings (i18next, ru + en), tenant isolation / RLS. -->

### Scars
<!-- What was tried here before and failed: BUG_FIX_CONTEXT comments, recorded deviations, TODOs,
     past workarounds, ponytail: markers in the touched code. -->

### Tests
<!-- What covers this surface today, and what each test actually asserts versus what its name claims. -->

### Absences
<!-- What is missing rather than wrong: invariants enforced nowhere, untested paths, dangerous defaults. -->

## Open questions
<!-- What neither sweep could establish, each marked UNVERIFIED with what would close it. The plan
     must close each one or carry it forward as an explicit assumption. No open CONTRADICTION may
     remain here: those are settled in step 1 by reading the code or by asking the requester. -->

## Verification
<!-- The checks that prove the work: the jobs of .github/workflows/ci-<app>.yml for each app the
     change touches (that is where superapp's real lint, type, test, i18n, migration-drift and
     generated-types checks live), the real-DB suite against the migration sandbox when DB-backed
     behaviour changes, and the manual scenario for anything a person has to see. -->

## Coverage
<!-- [O] _ · [G] _ · [both] _. Mostly [both] means the second sweep bought little on this kind of
     task; largely disjoint means running two was worth it. -->
