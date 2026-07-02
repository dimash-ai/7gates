# Worktree Contract

Every code-touching gate runs against a **dedicated git worktree of the code repo**, one per
feature, so several pipeline sessions can run **in parallel without colliding** on files, the
branch, or the git index. This is the single source of truth for that convention — the gate
commands (`gate-design`, `gate-build`/`gate4-build`, `gate-verify`, `gate5-review`, `gate6-test`,
`gate7-ship`) reference it.

## Naming

For feature `<feature>`, code repo `<repo>` (the path passed as `<repo>`, relative to the pipeline root),
base branch `<base>`:

| Thing | Value |
|-------|-------|
| Worktree path | `<repo>/.worktrees/<feature>` (`.worktrees/` is gitignored in the code repo) |
| Branch        | `feature/<feature>` |
| Base          | `<base>` — **default `main`**. Focal: pass `feature/focal-migration` **until 2026-07-10**; from 2026-07-10 (migration merged) focal branches off the default `main` too |

Pass the **same base** to build, verify, and ship for a given feature: the branch forks from it,
and verify/ship diff against it as `<base>...HEAD`.

> **Path gotcha (don't "fix" it):** `git -C "<repo>" worktree add/remove` resolves its path argument
> **relative to `<repo>`**, so those two subcommands take the repo-relative `.worktrees/<feature>`. Every other
> command runs from the pipeline root and takes the full `<repo>/.worktrees/<feature>`. Mixing them up creates
> `<repo>/<repo>/.worktrees/<feature>`.
>
> **No cross-command shell vars:** each gate runs its commands in separate shells, so a `WT=…` set
> in one block won't survive to the next — write the literal `<repo>/.worktrees/<feature>` in each command
> (`<feature>`/`<repo>`/`<base>` are substituted by the gate executor — parsed from the raw `$ARGUMENTS` string, never from positional placeholders — before bash sees them). The `BR`/`BASE`
> vars below are local to the one block that uses them.

## Lifecycle

In the **3-gate flow the design gate creates** the worktree (so the feature's branch exists from
the very first gate); the **build gate creates-or-locates** it (the creator in the 7-step flow,
and the fallback when design ran without a `<repo>`); every later gate **locates and reuses** it;
the **ship gate removes** it after the PR merges. All steps are idempotent.

### Create-or-locate — design + build gates

```bash
BR="feature/<feature>"; BASE="<base>"; [ -n "$BASE" ] || BASE="main"   # focal until 2026-07-10: pass feature/focal-migration as <base>
if [ ! -d "<repo>/.worktrees/<feature>" ]; then
  if git -C "<repo>" show-ref --verify --quiet "refs/heads/$BR"; then
    git -C "<repo>" worktree add ".worktrees/<feature>" "$BR"            # branch exists (prior run) -> attach
  else
    git -C "<repo>" worktree add ".worktrees/<feature>" -b "$BR" "$BASE" # new branch off base
  fi
fi
echo "worktree: <repo>/.worktrees/<feature>   branch: $BR"
```

### Locate-or-fail — verify / review / test / ship

```bash
[ -d "<repo>/.worktrees/<feature>" ] || echo "ERROR: no worktree for '<feature>' at <repo>/.worktrees/<feature> — run the build gate first."
```

Then run **every** `git`, build, test, and `codex` command of that gate against `<repo>/.worktrees/<feature>`
— never `<repo>`. That path is a subpath of `<repo>`, so the codex sandbox scoping is identical to operating
on `<repo>` directly; the only change is the path.

### Remove — ship/verify, only after the PR has merged

```bash
git -C "<repo>" worktree remove ".worktrees/<feature>"     # refuses if dirty; KEEPS the branch
echo "Worktree removed. After confirming the merge landed: git -C <repo> branch -d feature/<feature>"
```

## Scope — code repo only

Only the **code repo (`<repo>`)** is isolated this way — that's the sole place parallel sessions edit
files, switch branches, and commit. The `.ai/` paper trail stays in the **shared** pipeline
checkout: its artifacts are per-feature paths (`design/<feature>-design.md`, `reviews/<feature>/`, …) that don't
clobber across features. The only shared-state hazard there is two sessions running `git
add/commit` on `.ai/` at the same instant — commit your `.ai/` paper trail per feature (or
serialize those commits) and there is nothing to collide.
