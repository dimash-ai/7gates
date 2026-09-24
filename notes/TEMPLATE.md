# Dossier: <topic-or-ticket>

<!-- Output of the explore gate (`/gate-explore <topic>`). Two independent reconnaissance sweeps,
     merged by UNION. Raw per-model sweeps in harness/scratch/<topic>-{opus,gpt}.md (gitignored).
     Not scored. Date: YYYY-MM-DD. Read by T1 before the spec is drafted. -->

## The issue

<!-- One paragraph, verbatim from what both sweeps were given. This makes the dossier stand alone
     six weeks from now, when nobody remembers the conversation that produced it. -->

---

<!-- EVERY item below: cite file:line (or a doc URL for external facts), and tag provenance —
     [O] Opus only · [G] GPT only · [both]. An item with no citation is a hunch: say so or cut it.
     Sweep wide, report narrow — include an item only if a planner could plausibly make a
     DIFFERENT DECISION because of it. -->

## Territory

<!-- What this issue plausibly touches: modules, routes, tables, migrations, config, tests.
     A candidate blast radius, before the spec measures it properly. -->

| what | where | prov |
|------|-------|------|
|      |       |      |

## Prior art

<!-- What already exists that a solution should REUSE rather than reinvent. The highest-value
     section in this document. Walk the reuse-first ladder (CLAUDE.md #2) and record which rung
     each item sits on: existing helper in this codebase / stdlib / platform-or-framework feature /
     already-installed dependency. -->

## Constraints

<!-- Pinned versions READ FROM the lockfiles (never from memory — say which file and line).
     Contracts and interfaces this must not break. Rules in CLAUDE.md / AGENTS.md that govern this
     specific surface — including whether it is AI-track code, which decides whether the semantic
     exoskeleton and LDD apply. Tenant-isolation / RLS boundaries in play. -->

## Scars

<!-- What was already tried here and failed: BUG_FIX_CONTEXT comments, recorded Deviations, TODOs,
     past workarounds. Cheapest thing to know, easiest to miss, and the thing that stops the swarm
     re-litigating a settled question. -->

## Tests

<!-- What covers this surface today, and what each test ACTUALLY asserts versus what its name
     claims. Note any capture-fixture test (caplog/capsys/mocked driver) whose channel never
     reaches a real sink — it proves the code called an API, not that anything was delivered. -->

## Absences

<!-- The defect class that is code which does NOT exist, so no reviewer reading the diff can see it:
     an invariant stated only in a comment with nothing enforcing it · a configurable value whose
     worst legal setting is materially worse than its default · two concerns sharing one credential,
     counter or limit · a code path with no test at all. -->

---

## Contradictions — resolve before planning

<!-- The two sweeps reported the same fact differently. Both claims, both citations, side by side.
     These BLOCK planning: a plan built on the wrong one of two contradictory facts is wrong from
     its first line. Resolve by reading the code, never by picking the more confident-sounding
     sweep. Record how each was settled when you close it. -->

| claim [O] | claim [G] | how it was settled |
|-----------|-----------|--------------------|
|           |           |                    |

## Gaps

<!-- What neither sweep could establish that the planner will need, and exactly what would close it.
     Each gap becomes an explicit open question in the spec — and an UNVERIFIED assumption the plan
     gate re-checks — rather than a silent guess in the plan. -->

---

## Coverage

<!-- Count the provenance tags: [O] _ · [G] _ · [both] _.
     Mostly [both] means the sweeps were redundant and one would do next time.
     Largely disjoint means running two was the right call. Read this before deciding whether to
     run the explore gate on the next ticket. -->
