---
name: run
description: Show the workspace as it stands — every repository's git state and every live session's verdict, read out in one pass. Read-only.
model-invocable: false
disable-model-invocation: true
---

# Run

The workspace has no app of its own. It is the control plane over the
repositories under `~/workspace` and the claude sessions working them, so
running it means reading that state out for a person. Nothing here writes,
launches, or closes anything.

Run both commands from the workspace root, `~/workspace`.

## 1. Every repository

    scripts/herdr-survey

Two lines per repository, the container root included: the branch and the
herdr agents holding it, then the dirty file count, the worktree count, and the
unpushed commit count. `--json` emits the same rows as one object per
repository; the table is the form a person reads, so take `--json` only when
something downstream computes over it.

## 2. Every live session

    .claude/skills/cleaning-sessions/scripts/sweep-sessions --include-workspace --shells

One JSON line per pane — `{repo, name, pane, verdict, closed}` — over every
session under `~/workspace` and every bare shell. Without `--close` the sweep
retires nothing, and `closed` is `false` on every line. Two absences are
structural, not faults: the calling pane is skipped, so this session never
appears in its own read-out, and a repository with no herdr workspace prints no
line at all.

The verdicts and what each one means are in the `cleaning-sessions` skill,
"The verdicts". This command only reports them.

## Scope

A service the entries expose — the board web app, a bridge, a tailnet handler —
is not read here. Its state belongs to its own repository's `/run`, because
only that repository knows how the service starts and what serving looks like.

## Report

- One bullet per repository that needs a person: dirty files, a worktree, or
  unpushed commits, with the counts.
- One bullet per session that is not plainly busy: the name, the pane, and the
  verdict.
- A repository that is clean and a session that is `working` need no bullet.
  Say so in one closing line instead of listing them.
- Close with what waits on the person. When nothing does, stop at the outcome.
