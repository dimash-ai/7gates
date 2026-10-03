# AGENTS.md

Conventions for AI agents working in this repository.

## Roles (co-dev flow, in stages — default)

By default every feature flows through three steps — **brief / plan / build**, the build once per
stage, each stage its own PR into dev (`harness/checklists/mvp.md`) — and Codex has a different role
in each. Every Codex run is a separate `codex exec` process whose final message is
written to a file by `-o`; results land in the code repo's `specs/<slug>/`, never in this repo.

- **Step 1, brief — Codex drafts the brief and its MVP cut.** Read-only, independently, from the
  request alone: it never looks for or defers to another model's draft. It states the problem from
  the user's side, the hypothesis, and the cut: stage 1 (the least a user must see on dev), the next
  stages, Not now; at most five questions, smallest option first, each with its cost. It reads
  product docs and may skim the code only to see what already exists; it may use web search for
  facts outside the repo, and names no design. Not scored, so no verdict block.
- **Step 2, plan — Codex is the doer.** Read-only, it plans cold from the brief and the code: the
  stage map and every stage's detail, so step 3 only implements, and returns the plan as its final
  message. If the brief is ambiguous in a way that would change stage 1, it returns QUESTIONS; an
  ambiguity that only touches a later stage is planned as an UNVERIFIED assumption. Opus reviews it
  from a fresh, clean-context subagent, in stage mode.
- **Step 3, build — Codex reviews where it changes the outcome.** Opus implements each stage with no
  review layers inside it. Codex reviews a stage whose risk is data or auth before it merges into
  dev (`Step: build`), and every release to main once (`Step: ship`), write-enabled for one reason
  only, to **run the checks itself** and report the counts it observed. It never creates, edits or
  deletes a file. In stage mode a Must Fix is only a ship-blocker (`harness/checklists/mvp.md` §5);
  the over-engineering lens in `harness/checklists/ponytail.md` produces follow-ups.
- **Learn, weekly — Codex judges.** Read-only, from the data file Opus measured in PostHog and
  nothing else: no queries, no repo. A verdict per shipped hypothesis (validated, invalidated or
  inconclusive; on track, off track or too early inside its window), each with the number and the
  count of people it rests on, then a read of what is in demand. Independent of Opus's verdict; the
  requester decides. Not scored, so no verdict block.

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

- Status is **APPROVED only if Score >= 9.0**; otherwise **BLOCKED**. In the co-dev flow's stage
  mode, only ship-blockers are Must Fix items, and a review with none is APPROVED.
- Any **must-fix** issue caps the score at **8.9**.
- Any **security**, **data-loss**, or **build/test-breaking** issue caps the score at **7.9** or lower.
