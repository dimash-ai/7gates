# Release Gate

The final gate — **Step 7 (ship)**, command `/gate7-ship`. Release only when the scored verdict clears the bar.

## Gate rule

- **Score >= 9.0 and Status APPROVED** → cleared for release.
- Otherwise → **BLOCKED**. The ship doer (Opus) fixes the Must Fix items and resubmits for re-score.
- Hard caps (see `scoring-rubric.md`): any must-fix → ≤ 8.9; any security / data-loss /
  build-or-test-breaking issue → ≤ 7.9.

## Before the final review, confirm

- [ ] All prior gates scored >= 9.0 (think, plan, design, every build slice, review, tests).
- [ ] `make verify` passes on the full change; output captured in the handoff.
- [ ] Every acceptance criterion in the task is met and demonstrably tested.
- [ ] PR description is accurate, complete, and honest about risk and scope.
- [ ] Migrations / data or format changes called out, with a rollback path.
- [ ] No new secrets, no unintended breaking changes, no unreviewed files in the diff.
- [ ] Follow-ups / out-of-scope items recorded (not silently dropped).
