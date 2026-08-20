# CLAUDE.md

House rules for Claude Code in this repository — the always-on quality bar. The formal
review pipeline in `ai/` enforces these same four principles at each gate, where the doer and
reviewer alternate between Opus and GPT and the reviewer scores against them
([`ai/checklists/scoring-rubric.md`](ai/checklists/scoring-rubric.md)). **By default a feature
runs the 3-gate flow** — design / build / verify (see
[`ai/README-3gate.md`](ai/README-3gate.md)); the shorter 2-gate co-dev flow
([`ai/README-2gate.md`](ai/README-2gate.md)) — GPT plans, Opus reviews; Opus builds, GPT reviews —
is the alternative for ordinary changes, and the higher-granularity 7-step flow
([`ai/README.md`](ai/README.md)) the one for finer checkpoints. `AGENTS.md`
covers Codex's dual doer/reviewer role.

Behavioral guidelines to reduce common LLM coding mistakes, derived from
[Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM
coding pitfalls (source kept in `andrej-karpathy-skills/`) and the reuse-first minimal-code ladder
from [ponytail](https://github.com/DietrichGebert/ponytail) (MIT), folded into principle 2 below.

**Tradeoff:** these guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

**Before writing code, walk the reuse-first ladder — stop at the first "yes":**
1. Does this need to exist at all?
2. Does something in this codebase already do it?
3. Does the standard library do it?
4. Is there a native platform/framework feature?
5. Does an already-installed dependency do it?
6. Can it be one line?
7. Only then: write the minimum that works.

The ladder never skips safety guardrails — validation, security, and accessibility still apply.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to
overcomplication, and clarifying questions come before implementation rather than after mistakes.
