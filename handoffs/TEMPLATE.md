# Stage
<!-- Which pipeline gate this handoff is for, e.g. "Stage 3: implement one slice" or "Stage 5: tests + verification". -->

# What changed
<!-- Precise description of what was done in this step. Reference slice numbers from the plan. No vague summaries. -->

# Files touched
<!-- Exact list of files added/modified/deleted in this step. -->
- 

# Tests run
<!-- The exact commands you ran and their result (pass/fail counts). -->
```sh

```

# Verification output
<!-- Paste the relevant tail of `make verify` (or equivalent) output proving the state of the build. -->
```sh

```

# Still needs review
<!-- Call out anything you are unsure about, intentional shortcuts, or spots where you want the reviewer to look hardest. Any check left failing must be proven pre-existing on the base branch — not assumed unrelated. -->
- 

# PR / release notes (for users — stage 5)
<!-- Only at the final gate. Describe what the user can now DO, in plain language. NOT the branch's history: no version bumps, mid-branch fixes, review outcomes, or "while I was in there". Confirm the text below contains no secrets, tokens, keys, or PII. -->
- 

# Status
<!-- Codex verdict once reviewed, e.g. "CODEX APPROVED (9.2)" or "CODEX BLOCKED (8.4)"; APPROVED requires Score >= 9.0. Until reviewed: AWAITING CODEX REVIEW. -->
AWAITING CODEX REVIEW

---
Do not continue implementation until Codex review is complete.
