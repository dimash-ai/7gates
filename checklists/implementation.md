# Implementation Checklist

The build doer (Opus) runs through this before the build gate (`/gate4-build`).

- [ ] Change is ONE small, logically coherent slice from the plan.
- [ ] Matches the task scope — nothing added that isn't in the task/plan.
- [ ] Surgical (Surgical Changes): every changed line traces to the task; no drive-by refactors or style churn; only orphans MY change created are removed.
- [ ] Simple (Simplicity First): minimum code for the slice; no speculative abstraction, config, or flexibility that wasn't asked.
- [ ] Assumptions surfaced, not silently chosen (Think Before Coding); ambiguity raised before coding, not after.
- [ ] Existing tests still pass and the new behavior is left verifiable; the comprehensive, adversarial tests are authored by GPT in Step 6 (`/gate6-test`), not here.
- [ ] If this fixes a bug: target the root cause, not the symptom (the reproducing test is authored in Step 6).
- [ ] `make verify` (test + lint + typecheck + build) passes locally.
- [ ] Any check left failing is proven pre-existing on the base branch — not assumed unrelated.
- [ ] No debug code, leftover TODOs, commented-out blocks, or stray logs.
- [ ] No secrets, tokens, or credentials in code, tests, fixtures, commit messages, or any text headed for an external sink (PR body, issue).
- [ ] Diff is small enough to review well; if not, split into more slices.
- [ ] On track for a 9.0+ review: no open must-fix correctness / security / test-blocking issues (see `scoring-rubric.md`).
