# Review Verdict

Reviewer: <Opus | GPT Codex>
Step: <think | plan | design | build | review | test | ship>
Score: X.X / 10
Status: APPROVED or BLOCKED

## Reason
<why this score>

## Must Fix
<blocking issues, or "None">

## Should Consider
<non-blocking suggestions, or "None">

## Tests Reviewed
<tests/commands inspected or run>

## Release Risk
Low, Medium, or High

<!--
Scoring is governed by ai/checklists/scoring-rubric.md:
APPROVED only if Score >= 9.0; any must-fix caps at 8.9; any security / data-loss /
build-or-test-breaking issue caps at 7.9.

Reviews live in a per-feature folder, numbered by step (the reviewer is the OTHER model):
  ai/reviews/<feature>/01-think-verdict.md    (/gate1-think  — GPT reviews Opus)
  ai/reviews/<feature>/02-plan-verdict.md     (/gate2-plan   — Opus reviews GPT)
  ai/reviews/<feature>/03-design-verdict.md   (/gate3-design — GPT reviews Opus)
  ai/reviews/<feature>/04-build-verdict-N.md  (/gate4-build  — GPT reviews Opus; one file per slice/fix)
  ai/reviews/<feature>/05-review-pass.md      (/gate5-review — GPT's holistic review pass, the artifact)
  ai/reviews/<feature>/05-review-verdict.md   (/gate5-review — Opus scores GPT's review)
  ai/reviews/<feature>/06-test-verdict.md     (/gate6-test   — Opus reviews GPT)
  ai/reviews/<feature>/07-ship-verdict.md     (/gate7-ship   — GPT reviews Opus)
-->
