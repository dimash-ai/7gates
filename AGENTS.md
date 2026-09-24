# AGENTS.md

Conventions for AI agents working in this repository.

## Roles (3-step co-dev flow — default)

By default every feature flows through three steps — **brief / plan / build** — and Codex has a
different role in each. Every Codex run is a separate `codex exec` process whose final message is
written to a file by `-o`; results land in the code repo's `specs/<slug>/`, never in this repo.

- **Step 1, brief — Codex researches.** Read-only, independently, from scratch: it never looks for
  or defers to another model's findings. It sweeps the code repo for what a planner needs (Territory,
  Prior art by ladder rung, Constraints, Scars, Tests, Absences), cites every item, may use web
  search for facts outside the repo, and proposes no design. Not scored, so no verdict block.
- **Step 2, plan — Codex is the doer.** Read-only: it plans cold from the brief alone and returns
  the plan as its final message. If the brief is ambiguous in a way that would change the plan, it
  returns QUESTIONS instead of planning around the ambiguity. Opus reviews it from a fresh,
  clean-context subagent.
- **Step 3, build — Codex reviews.** Read-only on each slice Opus builds; write-enabled on the
  release pass for one reason only, to **run the checks itself** and report the counts it observed.
  It never creates, edits or deletes a file. Both reviews apply the over-engineering lens in
  `harness/checklists/ponytail.md`. `Step:` is `build` per slice and `ship` for the release pass.

The doer fixes only the reviewer's cited Must Fix items on a BLOCK, then resubmits. Full flow:
`harness/README-codev.md`. The other flows, and Codex's roles in them, are in each flow's
`harness/README-*.md`; `PIPELINE_OVERVIEW.md` says when each still applies.

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

Scoring is governed by `harness/checklists/scoring-rubric.md`:

- Status is **APPROVED only if Score >= 9.0**; otherwise **BLOCKED**.
- Any **must-fix** issue caps the score at **8.9**.
- Any **security**, **data-loss**, or **build/test-breaking** issue caps the score at **7.9** or lower.
