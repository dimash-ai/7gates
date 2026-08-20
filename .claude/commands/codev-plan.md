---
description: "Co-dev 1 (plan): GPT does, Opus reviews"
argument-hint: <feature-name> [repo-path]
---

# Co-dev · 1 — plan  ·  GPT does · Opus reviews

The first gate of the **2-gate co-dev flow** (`harness/README-2gate.md`): **GPT writes the complete plan
for `$1`**, and a blind Opus reviewer scores it. No code is written until the score clears 9.0.

`$1` is the feature slug. `$2` is the code repo path relative to the pipeline root — **optional,
defaults to `superapp`**, the only code repo under the root. **If `$2` was omitted, substitute
`superapp` for every `$2` below** — inside the codex prompt string too — before running anything.

**Doer = GPT (Codex), write-enabled.** GPT plans cold: it has none of this conversation's context, so
everything it needs must be in the repo or the kickoff task. Run exactly this one bash command from
the pipeline root:

```bash
mkdir -p harness/design harness/runs
codex exec --sandbox workspace-write "$(cat harness/prompts/doer.md)
You are GPT Codex, the doer for the PLAN step of $1. Read the kickoff task harness/tasks/$1.md if it exists, then study the code repo $2 until you can plan against what is actually there. Write the complete plan to harness/design/$1-design.md following the structure in harness/design/TEMPLATE-3gate.md — the problem and the decision with the alternatives you rejected, assumptions marked confirmed/unverified, what is out of scope, observable success criteria, the build broken into independently shippable slices (each with the files it touches, its main failure mode, and what its test proves), the architecture and contracts, the happy AND unhappy flow, and the test/security/rollback strategy. The builder works from this document ALONE, so it must be self-contained. Walk the reuse-first ladder (CLAUDE.md #2) before proposing any new surface, and cite every claim about existing code as file:line. You have NO network access: if the plan depends on a library, framework, or tool API, state which pinned version you assumed (read it from the repo's pyproject.toml / package.json / lockfiles — never from memory) and mark that assumption UNVERIFIED so the reviewer can check it. Write ONLY harness/design/$1-design.md — do NOT edit code, tests, configs, or any other file." 2>&1 | tee harness/runs/$1-codev-plan.txt
```

**Reviewer = Opus, fresh context.** Do **not** review the plan inline — you watched it being made,
and you may have shaped the request that produced it. Spawn a clean-context Opus reviewer with the
**Agent tool** (`subagent_type: "claude"`), passing this prompt:

> `<contents of harness/prompts/reviewer.md>`
> You are Opus, the reviewer. Step: plan. Read ONLY the plan at `harness/design/$1-design.md`, the kickoff task `harness/tasks/$1.md` if it exists, and the code it cites in `$2`. Apply the plan and design lenses together: is the problem framed correctly and the approach justified against the alternatives; are assumptions explicit and scope bounded; is this the minimum viable change, or does existing code already solve part of it (the reuse-first ladder, CLAUDE.md #2); is the build sliced into sound, independently shippable steps each with a named failure mode and a test that proves something; is the architecture coherent — coupling, data model, interfaces, and the unhappy path (null / empty / upstream error)? **Verify the plan's file:line citations** against the repo — a plan built on code that isn't there is a Must Fix. **GPT wrote this offline with no network**, so you own every version-sensitive claim: check each library/framework/tool assumption against the repo's actual pins (`pyproject.toml`, `package.json`, lockfiles) and, where the API matters, the official docs for that version (Context7 docs MCP or WebSearch). A stale-API or wrong-version assumption is a Must Fix. Output the verdict EXACTLY as the charter specifies (Reviewer: Opus, Step: plan). Status is APPROVED only if Score >= 9.0.

Take the subagent's returned verdict and:

1. Ensure `harness/reviews/$1/` exists, then save **only the verdict block** — from the `# Review Verdict` line to the end — to `harness/reviews/$1/1-plan-verdict.md`. **If the file exists, increment:** `1-plan-verdict-2.md`, etc.
2. STOP. Write no code.
3. Report **Score** and **Status**:
   - **BLOCKED** (< 9.0): list every Must Fix, then re-run the GPT doer command with the Must Fix list appended to its prompt — instruct GPT to revise `harness/design/$1-design.md` fixing **only** those items — and re-review.
   - **APPROVED** (>= 9.0): say so; next stage is **co-dev 2 — build** (`/codev-build $1 [repo] [base-branch]`).

> `--sandbox workspace-write` lets the GPT doer write the plan file — confirm the flag with `codex --help`. The Opus review must run in a **fresh subagent**, not inline, so the reviewer has the same blind context `codex exec` gives GPT.
