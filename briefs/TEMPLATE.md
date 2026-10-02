# Brief: <slug>

Branch: <Linear gitBranchName, else the app's convention: feat/focal-<slug> for Focal, feature/<slug> or fix/<slug> elsewhere>
Base: dev
Linear: <ALL-id — url, or none>
Depth: <quick or full>
Date: YYYY-MM-DD
Pinned: <the sha the step-2 worktree block printed>

<!-- The ONE document of the co-dev flow. Step 1 (/step1) writes its product part: the problem and
     the business task, merged by union from two independent product drafts and confirmed by the
     requester. Step 2 (/step2) researches the code against it and appends the research part; then
     the planner (GPT) works from the whole brief, cold: it never saw the conversation. So no "as
     discussed", every fact carries file:line or a URL, the contract comes first and the open
     questions come last.
     It says WHAT and WHY, never HOW. No solution design: if the brief already holds a design, the
     planner restates it instead of planning, and the cross-model plan is lost. Evidence that
     something already exists and should be reused is a finding, not a design.
     Written in English; the requester's own words stay verbatim in their language.
     The header is machine-read: one key per line, a plain value with no backticks or bold. Step 1
     fills Linear, Date, Branch, Base and Depth; step 2 adds Pinned once its worktree exists. Branch
     and Base decide the worktree steps 2 and 3 work in; Pinned records the commit the research and
     the plan describe. Every slug has a branch of its own. -->


<!-- PRODUCT PART, written in step 1: the sections of harness/briefs/PRODUCT.md below its header,
     from In short to In the requester's words, merged by union from product/opus.md and
     product/codex.md. Tag every story, criterion, unhappy path and question [O] Opus only, [G] GPT
     only, or [both]. Questions and answers records every answer the requester gives, in step 1 or
     step 2, with its date: the planner builds on it and does not reopen it. -->


<!-- RESEARCH PART: step 2 appends everything below, merged from research/opus.md and
     research/codex.md. -->

## Acceptance criteria
<!-- The contract for the plan (every one traces to a slice) and for the release pass (every one
     names a test). Every criterion of the user stories above, by its id (US-1.1 ...), then any
     criterion the research added that no story covers (R-1 ...), each naming the finding it came
     from, and M-1 when the Hypothesis signal does not exist yet: the change emits it, as
     Measurement names it. Observable and testable: "works correctly" is not a criterion. -->
- [ ]

## Scope
<!-- What IS included, by story (US-n), specific to modules, screens, endpoints. -->

## Out of scope
<!-- What is explicitly NOT included beyond the product part's Out of scope, including tempting
     neighbours the research found. -->

## Findings
<!-- Merged from research/opus.md and research/codex.md by UNION. Tag every item [O] Opus only,
     [G] GPT only, or [both]. Sweep wide, report narrow: an item earns its place only if the planner
     could make a DIFFERENT decision because of it. Quick depth fills Territory, Prior art, Tests,
     Scars and Measurement; full depth fills all seven. -->

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

### Measurement
<!-- How the Hypothesis signal is measured today: the analytics events and properties the code emits
     for it (file:line, and the helper that sends them), what PostHog holds for it and its value now
     (Opus reads it through the PostHog MCP; GPT cannot), and what is missing. Empty for a brief
     whose Hypothesis is none. -->

## Open questions
<!-- What neither sweep could establish, each marked UNVERIFIED with what would close it. The plan
     must close each one or carry it forward as an explicit assumption. No open CONTRADICTION may
     remain here: those are settled in step 2 by reading the code or by asking the requester. -->

## Verification
<!-- The checks that prove the work: the jobs of .github/workflows/ci-<app>.yml for each app the
     change touches (that is where superapp's real lint, type, test, i18n, migration-drift and
     generated-types checks live), the real-DB suite against the migration sandbox when DB-backed
     behaviour changes, and the manual scenario for anything a person has to see. -->

## Coverage
<!-- Product drafts: [O] _ · [G] _ · [both] _, counted from the tags above. Sweeps: [O] _ · [G] _ ·
     [both] _. Mostly [both] means the second model bought little on this kind of task; largely
     disjoint means running two was worth it. -->
