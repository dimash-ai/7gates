# Ponytail lens — the reuse-first ladder, the over-engineering review, the debt marker

A pinned copy of [ponytail](https://github.com/DietrichGebert/ponytail) **v4.10.0** (`e3ba2aa`,
MIT, notice in [`PONYTAIL-LICENSE`](PONYTAIL-LICENSE)), adapted to this pipeline and to superapp's
constitution. The co-dev commands hand **this file** to every step, so a ponytail release cannot
change what a gate checks between two runs of the same feature. That holds only while the ponytail
**plugin** stays off during the flow: installed and on, its hooks inject the live ruleset into the
builder's session, every Claude subagent (the blind plan reviewer included) and trusted Codex
sessions, and its test rule ("one runnable check, no frameworks, no fixtures") contradicts §4. Run
the flow with `PONYTAIL_DEFAULT_MODE=off`. To take a newer release: read its changelog, carry what
changed into this file by hand, bump the pin above.

## 1 · The ladder

Stop at the first rung that holds:

1. **Does this need to exist at all?** Speculative need: skip it and say so in one line (YAGNI).
2. **Already in this codebase?** Reuse the helper, type or pattern that lives here. Re-implementing
   what sits a few files over is the most common slop.
3. **Standard library does it?** Use it.
4. **Native platform feature covers it?** `<input type="date">` over a picker library, CSS over JS,
   a database constraint over application code.
5. **Already-installed dependency solves it?** Use it. Never add a dependency for what a few lines do.
6. **Can it be one line?** One line.
7. **Only then:** the minimum code that works.

The ladder runs **after** the problem is understood, never instead of it: read the code the change
touches and trace the real flow end to end, then climb. A bug fix goes at the root cause: grep every
caller of the function you are about to touch and fix the shared function once. A guard in one
caller leaves its siblings broken.

| step | who | how the ladder is applied |
|------|-----|---------------------------|
| 1 · brief | both researchers | Prior art is recorded **by rung number**: 2 this codebase, 3 the standard library, 4 the platform, 5 an installed dependency. Prior art that already covers the whole intent goes to the requester as a question, not as a footnote. |
| 2 · plan | GPT plans, Opus reviews | Every new file, module, dependency or abstraction in the plan names the rung it stopped at and why the earlier rungs did not hold. A new surface with no rung is a Must Fix. |
| 3 · build | Opus builds, GPT reviews | Opus climbs the ladder before each slice; GPT reviews each slice with the tags in §2. |
| 3 · release | GPT | Lists the `ponytail:` markers the change adds (§3). |

## 2 · Over-engineering review — the tags

One line per finding: `<file>:L<line>: <tag> <what>. <replacement>.`

- `delete:` dead code, unused flexibility, a speculative feature. Replacement: nothing.
- `stdlib:` a hand-rolled thing the standard library ships. Name the function.
- `native:` a dependency or code doing what the platform already does. Name the feature.
- `yagni:` an abstraction with one implementation, config nobody sets, a layer with one caller.
- `shrink:` the same logic in fewer lines. Show the shorter form.

End the list with `net: -<N> lines possible.` Nothing to cut: `Lean already.`

**Severity** (`scoring-rubric.md`, Simplicity First): a finding is **Should Consider** by default. It
is a **Must Fix** only when the cut changes correctness, or when the extra surface is big enough to
warrant rework: a new dependency carried for one call, a speculative layer spread across files.

**Scope:** the lines this change adds or modifies. Over-engineering that predates the change is
reported as Should Consider and never deleted in this change (house rule 3, Surgical Changes).

## 3 · The debt marker

A deliberate shortcut with a known ceiling (a global lock, an O(n²) scan, a naive heuristic, a
full-table scan) is marked where it lives, naming the ceiling and the trigger to upgrade:

```
# ponytail: full scan of the sender's cards, add an index if a sender passes ~10k cards
```

(`//` or a JSDoc ` * ` line in TypeScript, `--` in SQL.) superapp already carries this marker, in
`services/assistant` and in the PRIMA client. The release pass lists every marker the change
**adds**:

```
git diff origin/<base>...HEAD | grep -E '^\+.*(#|//|\*|--) ?ponytail:'
```

A marker that names no upgrade trigger is tagged `no-trigger`: that is the kind that quietly
becomes permanent.

## 4 · What is NOT over-engineering in superapp

Ponytail's defaults lose to the repo's constitution: root `superapp/CLAUDE.md`, and
`apps/<app>/CLAUDE.md` for the app being changed. Never flag these, and never cut them:

- **The semantic exoskeleton and LDD** on AI-track Python (`services/assistant/**`, plus the
  agent-API / agent-token / MCP modules of `apps/focal/server` and `apps/prima/server`):
  `# region MODULE_CONTRACT`, `# region FUNC_` / `CLASS_` tags, `# GREP_SUMMARY:` / `# STRUCTURE:`,
  and the `imp=` / `func=` / `block=` structlog fields. Where superapp's AI-track rule requires them
  they are never over-engineering, and their absence is a finding. Where it puts none (frontend
  code, Alembic revisions, Python outside those paths, module-level markup added to a pre-existing
  file) their presence breaks that rule: report it under the rule, not as over-engineering.
- **i18n.** Every user-facing string goes through i18next with both `ru` and `en` entries. A
  hardcoded string is a defect, not a shorter form.
- **Tests.** The repo's stack (pytest with pytest-asyncio, Vitest with Testing Library, Playwright)
  and the plan's test strategy set the bar. Ponytail's "one assert-based self-check" does not apply
  here, and a test the plan names is never a deletion candidate.
- **Migrations.** RLS policies, grants, the `downgrade()` body and the sandbox proof are required,
  not flexibility.
- **Repo-mandated structure.** `AppError` handling, Pydantic and SQLAlchemy models for I/O,
  structlog with `correlation_id`, tenant filters and RLS, validation at trust boundaries,
  accessibility basics.

Ponytail itself never cuts validation, data-loss handling, security or accessibility.
