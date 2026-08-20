---
name: cleaning-sessions
description: Sweep every pane and shell under ~/workspace, retire the sessions that are spent, and settle the board rows they held.
disable-model-invocation: true
---

# Cleaning sessions

Retiring a session is deterministic where delegating it is not: a classifier
reads each pane, and only two of its verdicts may be closed. Nothing here
judges whether a worker did its job. The delegating skill collects the output;
this skill retires what the collection left standing. All scripts live in
`scripts/` here, print JSON, and share the pane library with the delegating
skill's own scripts (`../delegating/scripts/_lib.sh`), because both read the
same screens.

Two rules hold over everything below.

- **Collect before closing.** Closing discards the pane, and a report that
  scrolled past nobody is gone with it. The pane is not the evidence behind a
  report either way: the worker's transcript under `~/.claude/projects/` is,
  and it answers to the worker's name in `/resume`.
- **Close a repository's work first.** A worker whose repository still holds
  uncommitted changes or a live worktree is not spent, whatever its screen
  says. Have it commit and remove the worktree, and wait for that to finish.

## The verdicts
`sweep-sessions` classifies a session from its screen, and `check-sessions`
in the delegating skill reads the same classifier to decide reuse. Four
outcomes, and only the first two are closable:

| verdict | the pane holds | on `--close` |
| --- | --- | --- |
| `empty` | no work at all | retired |
| `done` | a completion sentinel as its last word | retired |
| `pending` | quiet, with no sentinel | reported |
| the herdr status (`working`, `blocked`, `unknown`) | live work, a prompt to answer, or a screen with no evidence left on it | reported |

A `pending` session is either waiting on an answer or finished without
printing a sentinel, and a screen cannot tell those apart. The scripts make no
judgement there: report the pending ones and let the user decide.

## Retire one collected worker
`scripts/close-session <name>` closes a single session whose output has been
read — the normal end of one delegation. It closes only sessions the
delegating skill launched, since a herdr agent name exists nowhere else;
anything else needs `--force` and an explicit request from the user.

## Sweep the workspace
`scripts/sweep-sessions [<repo>] [--close] [--include-workspace] [--shells]
[--lines N]` reads every pane under `~/workspace` and prints one verdict per
session. Adding `--close` retires the `empty` and `done` ones and nothing
else.

- Run it dry first whenever it covers sessions whose output nobody has
  collected yet.
- Sessions in the container root itself (repo `workspace`) are reported but
  never closed by a bare sweep — those are the orchestrators, and a clean-up
  asked about the entries must not retire the session that asked.
  `--include-workspace`, or naming the root as the sweep's target, is the
  explicit request that reaches them.
- `--shells` widens the same sweep to panes holding no session. A bare shell
  reads as `shell` when its foreground process group is the shell itself and
  `shell-busy` while a command holds it, and only the idle ones close.
- Empty tabs and workspaces need no step: herdr retires a tab when its last
  pane closes, and a workspace when its last tab does.

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
`scripts/verify-verdicts` runs the classifier against captured screens with a
stub herdr, touching no real session. Run it whenever a session is classified
wrongly: the agent's screen markers are the only evidence the classifier has,
so a change to them breaks it silently.
