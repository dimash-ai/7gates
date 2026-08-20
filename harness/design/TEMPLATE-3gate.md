# Design: <feature>
<!-- The complete pre-build design for the 3-gate flow (gate A). ONE cohesive document, structured
by topic — not a sequence of sub-steps. The builder (gate B) and verifier (gate C) work from this
alone, so make it self-contained, and keep it tight. -->

## Problem & decision
<!-- What we're solving and for whom; why now. The approach you're taking, and the main
alternative(s) you rejected with the reason. One or two paragraphs — push back here if the asked-for
approach isn't the simplest. -->

## Assumptions & scope
<!-- Assumptions, each marked confirmed/unverified (the reviewer challenges silent ones). What's
explicitly out of scope. Open questions that must be answered before building ("None" if none). -->
- Assumption (confirmed/unverified):
- Out of scope:
- Open questions:

## Success criteria
<!-- Observable conditions that make this done — these become the tests the verifier (gate C) expects. -->
- [ ]

## Build approach (slices)
<!-- Ordered, independently shippable slices; each leaves the tree green. For each: the files it
touches, its main failure mode, and what its test proves. Add rows as needed. -->

| # | slice | files | main failure mode | what its test proves |
|---|-------|-------|-------------------|----------------------|
| 1 |       |       |                   |                      |

## Architecture & contracts
<!-- Components touched/added and how they couple. Data model: new/changed tables, columns, indexes,
migrations ("None" if no persistent state). Public interfaces/endpoints/events: signature, inputs,
outputs, error returns. A small ASCII diagram if it clarifies. Reach for what already exists
(codebase/stdlib/platform/dep) before adding new surface — the reuse-first ladder (CLAUDE.md #2). -->

| entity / interface | change | notes |
|--------------------|--------|-------|
|                    |        |       |

## Flow (happy + unhappy)
<!-- Main sequence, then null / empty / upstream-error / partial-failure. Name each failure, where
it's caught, and what the user sees. -->

| path  | trigger | handled where | result |
|-------|---------|---------------|--------|
| happy |         |               |        |

## Test strategy, security & rollback
<!-- Levels (unit/integration/e2e) and the risky path each proves; what "verified" means before
ship. Security surfaces (authz, injection, secrets, SSRF, rate-limiting). Migration/rollback shape.
"None" only if genuinely none. -->
- Test strategy:
- Security:
- Rollback:
