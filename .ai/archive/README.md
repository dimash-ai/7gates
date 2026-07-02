# Archive — retired legacy 5-gate pipeline

History only. Nothing here is part of the active process; the live flows are the default 3-gate
pipeline in [`../README-3gate.md`](../README-3gate.md) and the higher-granularity 7-step pipeline in
[`../README.md`](../README.md).

These artifacts were produced by the original **unidirectional** flow — Opus builds, GPT (Codex)
reviews read-only at every gate — on the `gate-task → gate-plan → gate-code → gate-test →
gate-final` commands. That flow has been retired in favour of the current doer/reviewer-alternating
pipelines. The work is kept for audit history.

| Path | Holds |
|------|-------|
| `reviews-legacy/<feature>/` | Per-feature scored verdicts in the old `01-task … 05-final` numbering. |
| `prompts-legacy/` | The old role charters `claude-builder.md` (Opus = builder) and `codex-reviewer.md` (Codex = reviewer). |
| `examples-legacy/auth-refresh/` | The worked example for the 5-gate flow. |
| `runs-legacy/` | Raw run logs (gitignored — not committed). |

Per-feature `tasks/`, `plans/`, and `handoffs/` files stay in the live tree: a task or plan is
process-agnostic, and their prose references to old gate names are accurate history.
