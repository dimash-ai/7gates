# Review Scoring Rubric

Every review — by Opus or by GPT (Codex), in either direction — ends with a **Score out of 10**
and a **Status**. This file defines both, and applies identically regardless of which model reviews.

## Bands

| Score      | Status   | Meaning                                            |
|------------|----------|----------------------------------------------------|
| 9.0–10.0   | APPROVED | Good to go.                                        |
| 8.0–8.9    | BLOCKED  | Close. Mostly good; fix issues / strengthen tests. |
| 6.0–7.9    | BLOCKED  | Meaningful correctness, design, or test gaps.      |
| 0.0–5.9    | BLOCKED  | Failed review. Likely needs significant rework.    |

## Score meaning

- **10** — Excellent. Correct, well-tested, low risk, clean implementation.
- **9.0–9.9** — Approved. Minor non-blocking issues only.
- **8.0–8.9** — Not approved yet. Mostly good, but needs fixes or stronger tests.
- **6.0–7.9** — Blocked. Meaningful correctness, design, or test gaps.
- **Below 6** — Rejected. Significant rework likely needed.

## Hard caps (override the band)

- Any **must-fix** issue caps the score at **8.9** — it cannot be APPROVED.
- Any **security**, **data-loss**, or **build/test-breaking** issue caps the score at **7.9** or lower.
- A review may score **9.0+ only if** there are no must-fix correctness, security, data-loss,
  or test-blocking issues.

## Principle violations → severity

The four house principles (root `CLAUDE.md`) are scored, not optional:

| Principle violated | Severity |
|--------------------|----------|
| **Surgical Changes** — unrelated edits, drive-by refactors, style churn | **must-fix** (caps at 8.9) |
| **Surgical Changes** — code changed/removed that wasn't understood and breaks behavior | build/test or data-loss cap (**7.9** or lower) |
| **Goal-Driven Execution** — new behavior with no verifiable success criteria / tests | **must-fix**, test-blocking (caps at 8.9) |
| **Think Before Coding** — a silent wrong assumption that affects correctness | **must-fix** (caps at 8.9) |
| **Simplicity First** — clear overcomplication, speculative abstraction, or reinventing what the reuse-first ladder (`CLAUDE.md` #2) would have reused (codebase/stdlib/platform/dep) | **Should Consider**; **must-fix** if it harms correctness or maintainability enough to warrant rework |

## Findings discipline

- A **Must Fix** must cite concrete evidence — the exact `file:line` or the failing command/output. An issue you cannot point to, or are unsure is real, is **Should Consider** and must NOT cap the score or block a 9.0.
- A failing or skipped check counts as "pre-existing" only when proven on the base branch; an unproven "not related to my change" claim is itself a **must-fix**.
- A secret, credential, or PII that would ship in external text (PR body, handoff, issue) is a **security** issue → caps at **7.9** or lower.

## The gate

```
The doer produces the step's artifact.
The reviewer (the other model) scores it.
Score >= 9.0  → APPROVED → proceed.
Score <  9.0  → BLOCKED  → the doer fixes the Must Fix items and resubmits for re-score.
```
