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
live worker pane named under this one, the sweeping pane itself, the focused
pane, and a session quieter-than-`--quiet-min` minutes ago (default 30).

`unlinked` is the answer when evidence is missing rather than negative, and
it is never closable. Absent, ambiguous and stale evidence all land there:
the failure mode is a pane that outlives its work, never work that dies with
its pane.

One thing no rule can see: a session that finished its turn by asking you
something in plain prose owes you an answer and looks exactly like one that
is finished. The question-mark hold catches most of them. It is a guess about
language, not a guarantee -- raise `--quiet-min` when that matters.

## Sweep the workspace
`scripts/sweep-sessions [<repo>] [--close] [--include-workspace]
[--quiet-min N] [--pane P]` reads every pane under `~/workspace` and prints
one verdict per session. Adding `--close` retires the ones carrying no hold,
re-reading each pane immediately beforehand so a session that woke up in the
meantime survives.

- Run it dry first whenever it covers sessions whose output nobody has
  collected yet.
- Sessions in the container root itself (repo `workspace`) are reported but
  never closed by a bare sweep -- those are the orchestrators, and a clean-up
  asked about the entries must not retire the session that asked.
  `--include-workspace`, or naming the root as the sweep's target, is the
  explicit request that reaches them.
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
A session the board dispatched carries its service-ticket in the snapshot, and
that ticket's rows are what the user sees. Read `GET /api/snapshot` on
`localhost:8300`: `sessions[]` names each pane's `service_ticket_id`, and
`board.groups[].backlog_tickets[]` carries every row with its state and the
sessions that held it. Settle the row before the pane goes, because a closed
pane leaves nothing to ask.

- A worker can ship the work, print its sentinel, and still leave its row
  `working`. Close the row yourself then — the report you have just read is the
  verification, and re-asking a session costs a round-trip for one line.
- Never close a row tagged `#need-you`. The tag holds the row's next
  transition, and only the owner ends it.
- A row left `working` and untagged after its session is gone reads as a
  session still running, and the board waits on it forever. Close it, or hand
  it back by setting it `open` and tagging it `#need-you`.

The doors that write a row, and the vocabulary they take, are in
`~/.claude/CLAUDE.md`, "Tickets".

## When a verdict looks wrong
`scripts/verify-verdicts` runs the classifier against transcripts built to
order — no herdr, no panes, nothing live. Run it whenever a session is
classified wrongly, and add the case that was misread: a rule the suite does
not pin is a rule the next edit can drop silently.
