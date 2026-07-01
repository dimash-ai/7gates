# Summary
<!-- Short paragraph: the approach in plain language. How the change will be made and the key design decision(s). -->

# Files to change
<!-- Every file you expect to add/modify/delete. Keep it honest so the reviewer can spot missing or surprising files. -->

| path | change | why |
|------|--------|-----|
|      |        |     |

# Implementation slices
<!-- Ordered, small steps. Each slice must be independently reviewable and leave the build green. -->
1. 
2. 
3. 

# Tests
<!-- What tests will be added or updated, at which level (unit/integration/e2e), and what each one proves. -->
- 

# Error & rescue map
<!-- Every error has a name. For each failure mode the change introduces, say what is thrown, where it is caught, and what the user sees. "Handle errors" is not an answer. Write "None" only if the change truly adds no new failure path. -->

| failure mode | error / exception | caught where | what the user sees |
|--------------|-------------------|--------------|--------------------|
|              |                   |              |                    |

# Review lenses (pre-answer before gate2-plan)
<!-- Pre-answer the lenses the Opus reviewer will score, so the plan clears in one pass. Skip a lens only if truly N/A. -->
- **Scope / strategy** — is this the minimum viable change? What existing code already solves part of it? Is the decision reversible?
- **Architecture** — coupling, state transitions, data flow on the unhappy path (null / empty / upstream error).
- **Design** (if user-facing) — empty / loading / error states; responsive + keyboard behavior.
- **DevEx** (if a tool/API/config) — onboarding friction and cognitive load for the next developer.

# Risks & migrations
<!-- Explicitly call out risky DB migrations, data backfills, config changes, or behavior changes. State rollback plan. If none, write "None". -->
- 

# Scope check
<!-- Confirm this plan matches the task's Scope/Out-of-scope and is small enough to review in one sitting. Note if it should be split. -->
- [ ] Matches the task's Scope and Out of scope
- [ ] Small enough to review in one sitting (else split)
- [ ] Size smell: if this touches many files or adds new services/abstractions, justify it here or propose a smaller cut

# Out of scope
<!-- Restate what this plan deliberately does not do, carried over from the task. -->
- 
