---
name: clean-sessions
description: Sweep every pane and shell under ~/workspace, retire the spent ones, and settle the board rows they held. The front door to the cleaning-sessions skill.
disable-model-invocation: true
---

# Clean sessions

A front door, not a procedure. Every rule about what may close and what may
not lives in the `cleaning-sessions` skill, and restating any of it here would
make a second copy that drifts from the first.

1. **Load the `cleaning-sessions` skill.** It owns everything below the
   command line: the verdicts, why a `pending` pane is never closed, why a
   repository's uncommitted work is committed first, and how a board row is
   settled.

2. **Read the whole workspace before closing any of it.** Run the sweep dry
   from `~/workspace`:

       .claude/skills/cleaning-sessions/scripts/sweep-sessions --include-workspace --shells

   `--include-workspace` is what makes this a whole-workspace sweep. Without
   it the sweep still reports the container root's panes but closes none of
   them, and the root is where the orchestrators sit.

3. **Close the spent ones.** Same command with `--close`:

       .claude/skills/cleaning-sessions/scripts/sweep-sessions --include-workspace --shells --close

   Closing discards a pane and whatever was still on its screen. Only `empty`,
   `done`, and idle `shell` panes close, and the calling pane never does, so
   this session cannot retire itself. A closed worker's transcript survives
   under `~/.claude/projects/` and answers to the worker's name in `/resume`.

4. **Settle the board row behind every session that closed**, per
   `cleaning-sessions`, "Settle the board row behind a session". A row left
   `working` after its session is gone reads as work still running, and the
   board waits on it forever.

## Report

- One bullet per pane retired: the repository, the name, and the verdict that
  retired it.
- One bullet per pane left standing that a person must decide about — every
  `pending` one, and anything the sweep refused.
- One bullet per board row settled, and one per row handed back.
- Close with what waits on the person. When nothing does, stop at the outcome.
