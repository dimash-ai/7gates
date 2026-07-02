# Codex Review Verdict

Score: 8.2 / 10
Status: BLOCKED

## Reason
The task is detailed and mostly verifiable, but two requirements conflict with the declared legacy-source contract. As written, implementation could satisfy the task while violating the stated parity goal.

## Must Fix
- `.ai/tasks/focal-tasks-tags.md:75`-`77` and `:208`-`:210` require invalid `startDate`/`endDate` to fall back to the current month, but the cited legacy helper only falls back when either value is missing, not invalid (`focal/server/utils/functions.ts:1`-`:12`; route passes raw query params at `focal/server/routes.ts:2978`-`:2981`). Either document this as an intentional behavior change or align the task with the legacy contract.
- `.ai/tasks/focal-tasks-tags.md:151`-`:157` and `:228`-`:230` describe `/api/tags` as legacy parity while allowing missing `color` to default to `#3b82f6`; the legacy route rejects missing `color` (`focal/server/routes.ts:3129`-`:3135`). Either mark this as an intentional divergence from legacy or update the requirement.

## Should Consider
- `.ai/tasks/focal-tasks-tags.md:128`-`:138` does not spell out the legacy sphere-resolution condition for priority calculation; legacy only resolves sphere when `project.isWorkTime === false` and `project.sphere` is set (`focal/server/storage.ts:940`-`:943`).
- `.ai/tasks/focal-tasks-tags.md:100`-`:102` sits under Create while `.ai/tasks/focal-tasks-tags.md:91`-`:95` says create ignores `status`; consider clarifying that free-form `status` applies only to PATCH.

## Tests Reviewed
Read-only review only. Inspected `.ai/tasks/focal-tasks-tags.md`, `.ai/checklists/scoring-rubric.md`, `CLAUDE.md`, and the referenced legacy routes/storage/helpers.

## Release Risk
Medium
