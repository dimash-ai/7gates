# AGENTS.md

Conventions for AI agents working in this repository.

## Roles (co-dev flow, in stages — default)

By default every feature flows through three steps — **brief / plan / build**, the build once per
stage, each stage its own PR into dev (`harness/checklists/mvp.md`) — and Codex has a different role
in each. Every Codex run is a separate `codex exec` process whose final message is
written to a file by `-o`; results land in the code repo's `specs/<slug>/`, never in this repo.

- **Step 1, brief — no Codex.** Opus rephrases the request into the brief in minutes; Codex's
  independent reading comes in step 2.
- **Step 2, plan — Codex is the doer.** Read-only, it plans cold from the brief and the code: the
  stage map and every stage's detail, so step 3 only implements, and returns the plan as its final
  message. If the brief is ambiguous in a way that would change stage 1, it returns QUESTIONS; an
  ambiguity that only touches a later stage is planned as an UNVERIFIED assumption. Opus checks it
  inline, in stage mode, and may send it back once with the reason. In the quick lane (one low-risk
  stage of about two hours) Codex does not plan: Opus does, and the requester's yes is the check.
- **Step 3, build — Codex reviews where it changes the outcome.** Opus implements each stage with no
  review layers inside it. Codex reviews a stage whose risk is data or auth on its open PR, while CI
  runs, before it merges into dev (`Step: build`), and a release to main that carries such a stage,
  or a resolved cherry-pick, once (`Step: ship`). CI runs the checks, so Codex does not re-run them;
  it may run one targeted command to reproduce a finding, the only reason its sandbox can write, and
  it never creates, edits or deletes a file. In stage mode a Must Fix is only a ship-blocker
  (`harness/checklists/mvp.md` §5), opened by its class, and a BLOCK is fixed and goes on, with one
  re-review only for a security or data item; the over-engineering lens in
  `harness/checklists/ponytail.md` produces follow-ups.
- **Learn, weekly — Codex judges.** Read-only, from the data file Opus measured in PostHog and
  nothing else: no queries, no repo. A verdict per shipped hypothesis (validated, invalidated or
  inconclusive; on track, off track or too early inside its window), each with the number and the
  count of people it rests on, then a read of what is in demand. Independent of Opus's verdict; the
  requester decides. Not scored, so no verdict block.

The doer fixes only the reviewer's cited Must Fix items on a BLOCK, then resubmits; in the co-dev
flow's stage mode the fix goes on with CI as its proof, re-reviewed only for a security or data
item. Full flow:
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
