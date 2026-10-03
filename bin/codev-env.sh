# codev-env.sh — sourced by every bash block of /step1, /step2 and /step3; never executed on its own.
#
# Each block starts with the same two lines: find harness/ by walking up, then source this file
# with the command's own arguments (the slug, and the optional code-repo path):
#
#   H=$(d=$PWD; while [ "$d" != / ] && [ ! -f "$d/harness/prompts/reviewer.md" ]; do d=$(dirname "$d"); done; [ "$d" != / ] && echo "$d/harness")
#   . "${H:?no harness/ at or above this directory}/bin/codev-env.sh" "$1" "$2" || exit 1
#
# Shell variables do not survive between blocks, so every block re-derives the same values here
# instead of trusting a variable set earlier. It sets:
#   R     the code repo (run inside the harness itself, R is the harness's parent: superapp)
#   M     the code repo's MAIN checkout, even when run from inside a worktree
#   S     M/specs/<slug>      every result of the flow (gitignored in superapp)
#   WT    M/.worktrees/<slug> the one tree step 2 plans against and step 3 builds in; it moves
#         from stage branch to stage branch (<Branch>-s1, <Branch>-s2, ...), each cut from
#         origin/<Base> once the stage before it has merged.
#         A session that runs in a worktree of its own (R under M/.claude/worktrees/, the Claude
#         desktop app's default) keeps both in that worktree instead: S=R/specs/<slug>, WT=R.
#   BR    the brief's Branch: line (the base name of the stage branches), BASE its Base: line
#         (both empty until the brief header exists)
# and defines the codev_need_* checks the blocks call before acting.

SLUG="$1"
[ -n "$SLUG" ] || { echo "codev: no slug given" >&2; return 1; }
R=$(cd "${2:-$(git rev-parse --show-toplevel 2>/dev/null)}" 2>/dev/null && pwd) || { echo "codev: no code repo at '${2:-$PWD}'" >&2; return 1; }
[ -f "$R/prompts/reviewer.md" ] && R=$(dirname "$R")   # ran inside the harness -> the code repo is its parent
M=$(git -C "$R" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) && M=$(dirname "$M")
{ [ -n "$M" ] && [ -d "$M/.git" ]; } || { echo "codev: $R is not inside a git checkout" >&2; return 1; }
# Results live in the main checkout: a worktree has its own empty specs/, and removing a worktree
# deletes its gitignored files along with it.
S="$M/specs/$SLUG"
WT="$M/.worktrees/$SLUG"
# Except in a session that runs in a worktree of its own: the app lets that session write only
# inside its worktree, so the flow keeps its results there and builds in the worktree itself.
case "$R/" in "$M/.claude/worktrees/"*) S="$R/specs/$SLUG"; WT="$R";; esac
BR=""; BASE=""
if [ -f "$S/brief.md" ]; then
  BR=$(sed -n 's/^Branch:[[:space:]]*//p' "$S/brief.md" | head -1 | tr -d '`*' | awk '{print $1}')
  BASE=$(sed -n 's/^Base:[[:space:]]*//p' "$S/brief.md" | head -1 | tr -d '`*' | awk '{print $1}')
else   # a later step run from another session: name the checkout that holds this slug's brief
  git -C "$M" worktree list --porcelain | sed -n 's/^worktree //p' | while IFS= read -r d; do
    [ -f "$d/specs/$SLUG/brief.md" ] && echo "codev: the brief for $SLUG is in $d/specs/$SLUG - run the steps from the session that works there" >&2
  done
fi
echo "codev: slug=$SLUG  results=$S  worktree=$WT${BR:+  branch=$BR}${BASE:+  base=$BASE}"

# Branch and Base must be real values; a missing line or a template placeholder fails loudly.
codev_need_header() {
  case "$BR" in ""|"<"*) echo "codev: $S/brief.md has no Branch: line" >&2; return 1;; esac
  case "$BASE" in ""|"<"*) echo "codev: $S/brief.md has no Base: line" >&2; return 1;; esac
}

# The worktree must exist and be on one of the brief's branches, so nothing is built or committed
# elsewhere: a stage branch <Branch>-s<N> (or its -fix), or a promotion branch <Branch>-main[-<n>].
# A plain <Branch> is accepted for a slug planned before stages.
codev_need_worktree() {
  [ -d "$WT" ] || { echo "codev: no worktree at $WT - /step2 $SLUG creates it (2a)" >&2; return 1; }
  case "$(git -C "$WT" branch --show-current)" in
    "$BR"|"$BR"-s[0-9]*|"$BR"-main|"$BR"-main-[0-9]*) ;;
    *) echo "codev: $WT is not on $BR-s<N> or $BR-main (it is on '$(git -C "$WT" branch --show-current)')" >&2; return 1;;
  esac
}

# The newest plan verdict must be APPROVED.
codev_need_approved_plan() {
  local v
  v=$(ls "$S"/reviews/plan-*.md 2>/dev/null | sort | tail -1)
  { [ -s "$S/plan.md" ] && [ -n "$v" ] && grep -q '^Status: APPROVED' "$v"; } || { echo "codev: no APPROVED plan verdict in $S/reviews - finish /step2 $SLUG first" >&2; return 1; }
}
