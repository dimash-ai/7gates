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
#         origin/<Base> once the stage before it has merged, or from that stage's branch while
#         its PR waits for CI (rebased onto origin/<Base> before its own PR opens).
#         A session that runs in a worktree of its own (R under M/.claude/worktrees/, the Claude
#         desktop app's default) keeps both in that worktree instead: S=R/specs/<slug>, WT=R.
#   BR    the brief's Branch: line (the base name of the stage branches), BASE its Base: line
#         (both empty until the brief header exists)
#   DESIGN the first word of the brief's Design: line: html, handoff or none (empty in a brief
#         written before the design step, which counts as none)
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
BR=""; BASE=""; DESIGN=""
if [ -f "$S/brief.md" ]; then
  BR=$(sed -n 's/^Branch:[[:space:]]*//p' "$S/brief.md" | head -1 | tr -d '`*' | awk '{print $1}')
  BASE=$(sed -n 's/^Base:[[:space:]]*//p' "$S/brief.md" | head -1 | tr -d '`*' | awk '{print $1}')
  DESIGN=$(sed -n 's/^Design:[[:space:]]*//p' "$S/brief.md" | head -1 | tr -d '`*' | awk '{print $1}')
else   # a later step run from another session: name the checkout that holds this slug's brief
  git -C "$M" worktree list --porcelain | sed -n 's/^worktree //p' | while IFS= read -r d; do
    [ -f "$d/specs/$SLUG/brief.md" ] && echo "codev: the brief for $SLUG is in $d/specs/$SLUG - run the steps from the session that works there" >&2
  done
fi
echo "codev: slug=$SLUG  results=$S  worktree=$WT${BR:+  branch=$BR}${BASE:+  base=$BASE}${DESIGN:+  design=$DESIGN}"

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

# A brief with something to draw (Design: html or handoff) needs the requester's ok on the design
# (reviews/design-<N>.md, Status: APPROVED) before step 2 plans: development starts only after it.
codev_need_design() {
  case "$DESIGN" in ""|"<"*|none) return 0;; esac
  local v
  v=$(ls "$S"/reviews/design-*.md 2>/dev/null | sort | tail -1)
  { [ -n "$v" ] && grep -q '^Status: APPROVED' "$v"; } || { echo "codev: the design of $SLUG has no ok from the requester yet - run /design $SLUG first" >&2; return 1; }
}

# The newest plan verdict must be APPROVED.
codev_need_approved_plan() {
  local v
  v=$(ls "$S"/reviews/plan-*.md 2>/dev/null | sort | tail -1)
  { [ -s "$S/plan.md" ] && [ -n "$v" ] && grep -q '^Status: APPROVED' "$v"; } || { echo "codev: no APPROVED plan verdict in $S/reviews - finish /step2 $SLUG first" >&2; return 1; }
}

# Merging <head> into <base> must leave every Alembic chain that <head> adds a revision to with one
# head, and every down_revision must name a revision the merged tree holds. Two migrations cut from
# the same parent in parallel lanes fork the chain, and the pre-deploy `alembic upgrade head` then
# fails on every service of the app; CI on the PR ran before the other migration merged, so its
# green does not show the fork. Reads the two refs only (the caller fetches them first): no
# checkout, no database.
codev_need_one_alembic_head() {
  local base="$1" head="$2" t d n rc=0
  t=$(mktemp -d) || return 1
  for d in $(git -C "$M" diff --name-only --no-renames --diff-filter=AMD "$base...$head" -- '*alembic/versions/*.py' | sed 's#/[^/]*$##' | sort -u); do
    # The directory as the merge leaves it: <head>'s version of every file it adds, changes or
    # deletes, <base>'s of the rest.
    { git -C "$M" diff --raw --no-abbrev --no-renames --diff-filter=AMD "$base...$head" -- "$d/" | awk '{ print "H", $6, $4 }'
      git -C "$M" ls-tree "$base" -- "$d/" | awk '$2 == "blob" { print "B", $4, $3 }'
    } | awk '$2 ~ /\.py$/ { if ($1 == "H") h[$2] = $3; else if (!($2 in h)) b[$2] = $3 }
             END { for (p in h) if (h[p] !~ /^0+$/) print h[p]; for (p in b) print b[p] }' | _codev_alembic_ids > "$t/merged"
    git -C "$M" diff --raw --no-abbrev --no-renames --diff-filter=A "$base...$head" -- "$d/" | awk '{ print $4 }' | _codev_alembic_ids > "$t/added"
    sed -n 's/^R //p' "$t/merged" | sort -u > "$t/revs"
    sed -n 's/^D //p' "$t/merged" | sort -u > "$t/downs"
    n=$(comm -23 "$t/revs" "$t/downs" | grep -c .)
    if [ "$n" -gt 1 ]; then
      echo "codev: merging $head into $base leaves $n Alembic heads in $d: $(comm -23 "$t/revs" "$t/downs" | tr '\n' ' ')" >&2
      echo "codev: this change adds: $(sed -n 's/^R //p' "$t/added" | tr '\n' ' ')- point the down_revision of its first new revision at the other head (it is applied nowhere yet), re-run the migration sandbox proof, push, and merge on the next green; if neither head is this change's, $base is already forked and needs an Alembic merge revision first: stop and tell the requester" >&2
      rc=1
    fi
    if [ -n "$(comm -13 "$t/revs" "$t/downs")" ]; then
      echo "codev: in $d a down_revision names $(comm -13 "$t/revs" "$t/downs" | tr '\n' ' ')which $base does not hold: that migration has to reach $base first, or go with this change" >&2
      rc=1
    fi
  done
  rm -rf "$t"
  return $rc
}

# Reads blob ids on stdin; prints "R <id>" for each revision and "D <id>" for each id a down_revision
# names (one, none, or a tuple, also one spread over several lines). Ids are double-quoted, as ruff
# formats them.
_codev_alembic_ids() {
  git -C "$M" cat-file --batch | awk '
    function ids(   n, q, i) { n = split($0, q, "\""); for (i = 2; i <= n; i += 2) print "D " q[i] }
    /^[0-9a-f]+ blob [0-9]+$/ { down = 0; next }
    /^revision(:[^=]*)?[[:space:]]*=[[:space:]]*"/ { split($0, r, "\""); print "R " r[2]; next }
    /^down_revision(:[^=]*)?[[:space:]]*=/ { ids(); down = ($0 ~ /\([^)]*$/); next }
    down { ids(); if ($0 ~ /\)/) down = 0 }
  '
}
