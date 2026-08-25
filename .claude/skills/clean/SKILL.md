---
name: clean
description: Sweep every pane and shell under ~/workspace, retire the sessions that are spent, and settle the board rows they held.
disable-model-invocation: true
---

# Clean

Retiring a session is deterministic where delegating it is not: a classifier
reads each pane's own session record, and closes only what carries no reason
to stay. Nothing here judges whether a worker did its job. The delegating
skill collects the output; this skill retires what the collection left
standing. All scripts live in `scripts/` here and print JSON. The classifier
itself is `scripts/session_state.py`, and the delegating skill calls it too --
reuse and retirement ask one question of one body of evidence.

Two rules hold over everything below.

- **Collect before closing.** Closing discards the pane, and a report that
  scrolled past nobody is gone with it. The pane is not the evidence behind a
  report either way: the session's transcript under `~/.claude/projects/` is,
  and it answers to the session in `/resume`.
- **Close a repository's work first.** A worker whose repository still holds
  uncommitted changes or a live worktree is not spent. The classifier reads
  this from the directories the session actually worked in, so the hold names
  the repository -- have the worker commit and remove the worktree, and wait
  for that to finish.

## What a verdict rests on
A pane carries its own session id (`agent_session`, written by the
`herdr-session-link` hook), the session id names its transcript, and the
transcript says whether the last turn completed. Nothing is read off the
screen, so a session nobody named -- started by hand or from the phone -- is
classified exactly like a delegated worker.

| verdict | the pane holds |
| --- | --- |
| `done` | a session whose last turn completed |
| `empty` | a session pane that was never prompted |
| `unlinked` | no transcript could be tied to the pane |
| `shell` / `shell-busy` | no agent: a bare shell, idle or running a command |
| the herdr status (`working`, `blocked`, `unknown`) | live work, a dialog, or no evidence |

The verdict alone never closes anything. Every row also carries `holds`, and
a pane retires only when that list is empty. A hold is raised by: herdr
reporting anything but idle, a detection rule matching `working` beneath the
winning one, an unanswered tool call, a turn left open, a last turn that ends
in a question, a repository the session touched still dirty or unpushed, a
live worker pane named under this one, the sweeping pane itself, and a
session quieter-than-`--quiet-min` minutes ago (default 2).

`unlinked` is the answer when evidence is missing rather than negative, and
it is never closable. Absent, ambiguous and stale evidence all land there:
the failure mode is a pane that outlives its work, never work that dies with
its pane.

One thing no rule can see: a session that finished its turn by asking you
something in plain prose owes you an answer and looks exactly like one that
is finished. The question-mark hold catches most of them. It is a guess about
language, not a guarantee -- raise `--quiet-min` when that matters.

The owner was shown that residual risk beside the alternative -- print the
candidates and close only what a person picks -- and chose the quiet-period
close anyway (2026-08-21). So a sweep acting on its own is the decision, not
an oversight: do not add a confirmation step back without asking.

## Sweep the workspace
`scripts/sweep-sessions [<repo>] [--close] [--quiet-min N] [--pane P]` reads every pane under `~/workspace` and prints
one verdict per session. Adding `--close` retires the ones carrying no hold,
re-reading each pane immediately beforehand so a session that woke up in the
meantime survives.

- Run it dry first whenever it covers sessions whose output nobody has
  collected yet.
- The container root (repo `workspace`) is swept like any entry, and the pane
  the owner happens to be looking at is a target like any other. Only `self`
  keeps the sweeping session itself alive; every other spent orchestrator
  retires with the workers it drove (owner, 2026-08-21).
- Empty tabs and workspaces need no step: herdr retires a tab when its last
  pane closes, and a workspace when its last tab does.

## Retire one collected worker
`scripts/close-session <name|pane-id>` closes a single session whose output
has been read — the normal end of one delegation, and now also the way to
retire a session nobody named, since the pane's session record rather than an
agent name is what says it finished. It refuses a pane carrying any hold and
prints them; `--force` overrides, and is for an explicit request from the
user, not for getting past a hold you would rather not read.

## Settle the board row behind a session
A pane and the board row behind it go stale together, so the sweep reads both
in one pass. After its pane rows it prints one row per board ticket needing
attention -- `{ticket, title, action, reason}` -- and under `--close` it acts:

| action | the row is | the sweep |
| --- | --- | --- |
| `release` | `working`, and no live session holds it | sets it back to `open` |
| `held` | `working` and tagged `#need-you` | leaves it, and says so |
| `unreachable` | not readable: the board did not answer | leaves everything |

Releasing is the whole of what a script may decide. It says nobody is working
the row, which the missing session already proves. Closing says the work
shipped, which only a reader of that session's report knows -- so read the
report, then close the row yourself with the `DELETE` door. A worker often
ships the work and still leaves its row `working`.

Liveness comes from the panes *and* from `sessions[]` in the snapshot, because
board dispatches sessions that never take a pane. Read the rows themselves at
`GET /api/snapshot` on `localhost:8300`, under `board.groups[].tickets[]`.

The doors that write a row, and the vocabulary they take, are in the
`delegating` skill, "Board's doors". One of them is not a door: the `working`
marker is taken through `/claim`, and a `PATCH .../head` asking for it is
refused with a 422. Releasing back to `open` is a plain head patch, and every
field it omits survives (probed 2026-08-21).

## When a verdict looks wrong
`scripts/verify-verdicts` runs the classifier against transcripts built to
order, and the board half against ticket records built the same way — no
herdr, no panes, nothing live. Run it whenever a session is
classified wrongly, and add the case that was misread: a rule the suite does
not pin is a rule the next edit can drop silently.
