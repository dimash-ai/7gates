# AGENTS.md

Conventions for AI agents working in this repository.

## Roles (3-gate pipeline — default)

By default every feature flows through 3 gates — **design / build / verify** — each with a **doer**
and a **reviewer** that alternate between Opus (Claude Code) and GPT (Codex). Codex therefore has
**two** roles:

- **Codex reviews** gate A (design) and each build slice in gate B. Here Codex is **read-only** and
  must not edit any file — it returns a scored verdict only.
- **Codex is the doer** on gate C (verify): invoked with `--sandbox workspace-write`, it verifies
  the whole change and authors/runs the tests, then prints its verification report for Opus to
  persist. Outside the file(s) the gate names, Codex changes nothing.

So the builder never verifies its own code: **Opus builds (B), GPT verifies (C)**. Opus reviews gate
C from a fresh, clean-context subagent using the `final-release-review` charter (gate C doubles as
the release gate), then ships on APPROVED. The doer fixes only the reviewer's cited Must Fix items on
a BLOCK, then resubmits. `Step:` in a 3-gate verdict is `design`, `build`, or `verify`. Full flow and
prompts live in `ai/` — see `ai/README-3gate.md`.

The higher-granularity **7-step flow** (`ai/README.md`) is the alternative when you want finer
checkpoints — think / plan / design / build / review / test / ship, roles alternating each step.
There Codex **reviews** steps 1 (think), 3 (design), 4 (build), and 7 (ship) read-only; is the
**doer** on steps 2 (plan) and 6 (test) under `--sandbox workspace-write`; and runs the holistic
**review pass** on step 5 read-only, printing it for Claude to persist. Opus reviews Codex's doer
steps from a fresh, clean-context subagent. `Step:` is then `think | plan | design | build | review
| test | ship`.

A standalone **explore gate** (`/gate-explore`, see `ai/README.md`) sits before any build flow:
Codex answers the user's questions **independently** and read-only — from scratch, not deferring to
any other model — for Opus to synthesize into `ai/notes/<topic>.md`. It is **not scored**, so no
verdict block; just give a concise per-question answer with evidence and a confidence level.

## Review output (any reviewer)

Whenever you review work in this project — including automatic stop-time reviews — end with a
scored verdict in this EXACT format:

```
# Review Verdict

Reviewer: <Opus | GPT Codex>
Step: <think | plan | design | build | review | test | ship | verify>
Score: X.X / 10
Status: APPROVED or BLOCKED

## Reason
## Must Fix
## Should Consider
## Tests Reviewed
## Release Risk
```

Scoring is governed by `ai/checklists/scoring-rubric.md`:

- Status is **APPROVED only if Score >= 9.0**; otherwise **BLOCKED**.
- Any **must-fix** issue caps the score at **8.9**.
- Any **security**, **data-loss**, or **build/test-breaking** issue caps the score at **7.9** or lower.
