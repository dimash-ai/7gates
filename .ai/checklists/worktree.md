# Worktree Contract

Every code-touching gate runs against a **dedicated git worktree of the code repo**, one per
feature, so several pipeline sessions can run **in parallel without colliding** on files, the
branch, or the git index. This is the single source of truth for that convention — the gate
commands (`gate-build`/`gate4-build`, `gate-verify`, `gate5-review`, `gate6-test`,
`gate7-ship`) reference it.

## Naming

For feature `$1`, code repo `$2` (the path passed as `<repo>`, relative to the pipeline root),
base branch `$3`:

| Thing | Value |
|-------|-------|
| Worktree path | `$2/.worktrees/$1` (`.worktrees/` is gitignored in the code repo) |
| Branch        | `feature/$1` |
| Base          | `$3` — **default `main`; pass `feature/focal-migration` for focal slices** |

Pass the **same base** to build, verify, and ship for a given feature: the branch forks from it,
and verify/ship diff against it as `$3...HEAD`.

> **Path gotcha (don't "fix" it):** `git -C "$2" worktree add/remove` resolves its path argument
> **relative to `$2`**, so those two subcommands take the repo-relative `.worktrees/$1`. Every other
> command runs from the pipeline root and takes the full `$2/.worktrees/$1`. Mixing them up creates
> `$2/$2/.worktrees/$1`.
>
> **No cross-command shell vars:** each gate runs its commands in separate shells, so a `WT=…` set
> in one block won't survive to the next — write the literal `$2/.worktrees/$1` in each command
> (`$1`/`$2`/`$3` are substituted by the slash-command layer before bash sees them). The `BR`/`BASE`
> vars below are local to the one block that uses them.

## Lifecycle

The **build gate creates** the worktree (it's the first code-touching gate); every later gate
**locates and reuses** it; the **ship gate removes** it after the PR merges. All three are
idempotent.

### Create-or-locate — build gates only

```bash
BR="feature/$1"; BASE="$3"; [ -n "$BASE" ] || BASE="main"   # focal: pass feature/focal-migration as $3
if [ ! -d "$2/.worktrees/$1" ]; then
  if git -C "$2" show-ref --verify --quiet "refs/heads/$BR"; then
    git -C "$2" worktree add ".worktrees/$1" "$BR"            # branch exists (prior run) -> attach
  else
    git -C "$2" worktree add ".worktrees/$1" -b "$BR" "$BASE" # new branch off base
  fi
fi
echo "worktree: $2/.worktrees/$1   branch: $BR"
```

### Locate-or-fail — verify / review / test / ship

```bash
[ -d "$2/.worktrees/$1" ] || echo "ERROR: no worktree for '$1' at $2/.worktrees/$1 — run the build gate first."
```

Then run **every** `git`, build, test, and `codex` command of that gate against `$2/.worktrees/$1`
— never `$2`. That path is a subpath of `$2`, so the codex sandbox scoping is identical to operating
on `$2` directly; the only change is the path.

### Remove — ship/verify, only after the PR has merged

```bash
git -C "$2" worktree remove ".worktrees/$1"     # refuses if dirty; KEEPS the branch
echo "Worktree removed. After confirming the merge landed: git -C $2 branch -d feature/$1"
```

## Scope — code repo only

Only the **code repo (`$2`)** is isolated this way — that's the sole place parallel sessions edit
files, switch branches, and commit. The `.ai/` paper trail stays in the **shared** pipeline
checkout: its artifacts are per-feature paths (`design/$1-design.md`, `reviews/$1/`, …) that don't
clobber across features. The only shared-state hazard there is two sessions running `git
add/commit` on `.ai/` at the same instant — commit your `.ai/` paper trail per feature (or
serialize those commits) and there is nothing to collide.
