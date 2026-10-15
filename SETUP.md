# Setup — the co-dev flow on a new machine

Clone this repo into your superapp checkout as `harness/`, link its commands into Claude Code, and
log in to Codex and `gh`: about fifteen minutes. The repo is public, so nobody has to invite you.
How the flow works, step by step, is in [`README-codev.md`](README-codev.md).

## What you need

The flow runs inside the superapp repo and is built around it: its CI, its migration sandbox, its
`dev` and `main` branches, its PostHog and its Linear.

| Tool | Why the flow needs it | Check |
|------|-----------------------|-------|
| superapp checkout, push access | every stage is built in it, pushed as a branch and opened as a PR into `dev` | `gh repo view Allosta-Group/superapp` |
| Claude desktop app, Code tab, Opus | Opus writes the brief, the design and the plan, and builds; step 3 turns on each PR's Auto-fix through the app's PR tools, which the terminal CLI does not have | a Code session open on superapp |
| Codex CLI, logged in with ChatGPT | GPT reviews the plan blind in step 2, and data or auth stages in step 3; every call runs in Fast mode | `codex --version` (tested on 0.160.0) |
| `gh`, logged in | opens, reads and merges the stage PRs | `gh auth status` |
| git 2.31 or newer | `git rev-parse --path-format` finds the main checkout | `git --version` |
| perl | the twenty-minute timebox around each Codex run; macOS ships it | `perl -v` |
| PostHog plugin, recommended | step 3 records each change's hypothesis | ask Claude to list your PostHog projects |
| Linear MCP, optional | step 1 reads a ticket from its id; without it, paste the ticket | ask Claude to open a Linear issue |

## Install

**1. Clone the harness into superapp.** It must sit at `superapp/harness`: every command finds it by
walking up from the session's folder. superapp already ignores `/harness/`, `specs/` and
`.worktrees/`, so nothing shows in `git status`.

```bash
cd ~/path/to/superapp
git clone https://github.com/dimash-ai/7gates.git harness
```

**2. Link the commands into Claude Code.** With no `~/.claude/commands` yet, link the whole folder:
every command, and every new one after a pull, shows up in every project.

```bash
ln -s "$PWD/harness/.claude/commands" ~/.claude/commands
```

Already have commands of your own there? Link the files instead, and run it again when a pull adds a
command:

```bash
for f in "$PWD"/harness/.claude/commands/*.md; do ln -s "$f" ~/.claude/commands/; done
```

With the folder link, never `ln`, `cp` or `rm` single files inside `~/.claude/commands`: it is the
repo's own folder, so `ln -sf` turns a command into a link to itself and `rm` deletes it from the
repo.

**3. Install Codex and log in** with your ChatGPT account.

```bash
npm install -g @openai/codex
codex login
```

The harness pins Fast mode on every call, but not the model or its effort: those come from
`~/.codex/config.toml`. What the flow's owner runs:

```toml
model = "gpt-6.1-sol"
model_reasoning_effort = "ultra"
```

**4. Log in to GitHub** with an account that can push to Allosta-Group/superapp.

```bash
gh auth login
```

**5. Connect PostHog and Linear.** With the PostHog plugin (`posthog@claude-plugins-official`), step 3
records each change's hypothesis on the «Hypotheses — bets and demand» dashboard. Without it, put
`Hypothesis: none` in your request and step 3 skips that part. The Linear MCP is a convenience:
without it, paste the ticket's text after the slug.

If you use the ponytail plugin, start these sessions with `PONYTAIL_DEFAULT_MODE=off`: the harness
carries its own pinned copy of ponytail's rules, and the plugin's hooks would override it.

## Check it works

Codex answers `OK` in a few seconds with the exact flags every harness call uses:

```bash
echo 'Reply with the single word OK.' | codex exec --enable fast_mode -c service_tier="priority" --sandbox read-only -
```

Then open a new Code session on superapp and type `/step`: the list shows `/step1`, `/step2` and
`/step3`.

## Your first run

In the desktop app, open a Code session on superapp and give the Linear id as the slug:

```
/step1 ALL-123
```

No ticket: use a short kebab-case name and write the request after it, as in
`/step1 kanban-filter Add an assignee filter to the Kanban board`. Everything after the slug is the
request.

From there it chains on its own and normally stops for you twice (the rare other stops are in
[Where it stops](README-codev.md#where-it-stops)):

1. **Brief**, about 10 minutes: the request rephrased, with its MVP. It asks only when it must.
2. **Design**, about 30 minutes: a hi-fi HTML prototype opens in your browser. **Stop 1:** say ok,
   or what to change.
3. **Plan**, about 30 minutes: Opus plans every stage, GPT reviews the plan blind.
4. **Build**, up to about 4 hours a stage: each stage is its own PR into `dev`, merged on green CI
   while the next one is built. PM tests each stage on dev.
5. **Release. Stop 2:** when dev looks right, ask for the release to main. It opens one PR into
   `main`, and you merge it.

A task with nothing users see skips the drawing; it stops after the plan for your yes instead, and
once more for you to try stage 1 on a local URL. `/step3 <slug>` resumes a run, `/design <slug>`
redraws, `/step2 <slug>` re-plans the stages not started.

The results (brief, design, plan, reviews, build logs) land in `specs/<slug>/` of the session's
folder, gitignored. A session with its own worktree (the worktree box in the composer) keeps them
inside it: run every step in that one session, and copy out what must outlive it, since deleting the
session deletes them.

## What it does without asking

These touch shared surfaces, so know them before your first run.

- **Merges into `dev` on green CI.** Each stage is pushed, opened as a PR into `dev` with Auto-fix
  on, and merged by the session itself once CI is green.
- **Leaves the ticket open.** Stage PR bodies start with `Part of <Linear id>`, and branch names and
  PR titles carry no id, so a stage PR links the ticket without closing it. You close it.
- **Never touches `main` by itself.** The release is a branch cut from `origin/main` with this task's
  commits cherry-picked onto it, opened as a PR that you merge.
- **Checks once, right before each push:** the app's static checks, the affected tests, and the
  migration sandbox for a schema change. It refuses a merge that would leave two Alembic heads.
- **Records the bet in PostHog:** an insight on the hypotheses dashboard and a notebook, once the
  change's signal is measurable on dev. The weekly `/learn` review is the flow owner's to run; you
  can leave it alone.
- **Spends Codex quota.** Every GPT review is a Fast-mode call, which uses more of your plan. On a
  usage limit the flow stops and says so; it never swaps in an Opus review without your word.

## Keep it current

```bash
git -C ~/path/to/superapp/harness pull
```

Pull between tasks, not in the middle of one: each brief records the harness commit it started on
(its `Harness:` line), and a task should finish on that version. Claude Code serves whatever branch
the checkout has, so keep it on `main`.

Don't edit the harness files in place, or your next pull will conflict: send a change as a pull
request to this repo. A change to how we work goes into the harness, never into superapp's CI or
`CLAUDE.md`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `/step1` is not in the command list | `readlink ~/.claude/commands` should print the harness's `.claude/commands`, and the harness checkout must be on `main` |
| `no harness/ at or above this directory` | the session runs outside superapp, or the clone is not at `superapp/harness` |
| A command shows old text in one project | a project-level `.claude/commands/` with the same file names shadows yours: delete those files |
| `Error: Unknown feature flag` from Codex | update Codex: `npm install -g @openai/codex` |
| Codex fails to authenticate | `rm ~/.codex/auth.json && codex login` |
| A review's log ends on a usage limit | wait for your Codex reset, then tell the session to run the review again |
| `codev: the brief for <slug> is in …` | run the steps from the session whose folder holds that brief |
| A red CI does not wake the session | run the flow in the desktop app: Auto-fix lives there, not in the terminal CLI |
