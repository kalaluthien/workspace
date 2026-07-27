---
name: delegating
description: Orchestrate work across claude sessions in herdr panes, one per ~/workspace repository. Use when a request belongs in a project entry (research → notes, app work → camera, ...) or spans several entries, when the user asks to spawn, reuse, message, monitor, or clean agent sessions, or for fire-and-forget surveys beside monitored implementation. Not for work this session can finish in its own cwd.
---

# Delegating

This session is the orchestrator: it routes, delegates, monitors, and reports —
it does not do the delegated work itself. All scripts live in
`scripts/` here, print JSON, and never touch panes they did not create.

## Decision loop
1. Route the request to repository entries with the workspace catalogue
   (`~/workspace/.claude/CLAUDE.md`).
2. `scripts/check-sessions <repo>` — live sessions with name-encoded
   model/effort, status, verdict, and tab capacity. Reuse a session whose name
   matches the needed model and effort and whose verdict is `empty` or `done`;
   the verdict decides, not the status, because a session that pauses mid-turn
   reports idle and claiming it would clear work still running. Otherwise
   `scripts/launch-session <repo> --model <m> --effort <e>` (capacity: a tab
   never exceeds 4 panes; sub-agent models per the global preference — Opus
   medium for search/coding/scripts, Opus high for planning; Fable only when
   the delegate must itself orchestrate).
   Clear a reused session here, before sending: `scripts/clean-session <name>`
   resets it to a known-empty context, and a session found idle carries
   whatever the last delegation left in it. A session launched in this step is
   already empty and needs no clear.
3. `scripts/send-prompt <name> [--worktree]` — the script appends what the
   session cannot see: sibling-session collision warnings, the worktree
   convention, and a `DONE <name>` completion sentinel.
4. Wait with the harness, not with the turn. `scripts/watch-sessions <name>...`
   prints one line per session the moment it stops needing the orchestrator —
   `done` on its sentinel, `blocked` on a permission prompt, `gone` on a
   closed pane, `pending` when it goes quiet without finishing — and exits
   when the last one lands. Run it two ways, by how many wake-ups the wait
   needs:
   - One session: a background `Bash` call. It exits on the single event and
     the harness re-invokes this session with the line.
   - Several: the `Monitor` tool. Each session that lands is a notification,
     and the watch ends itself when all of them have.
   Neither blocks the turn, and neither needs the user to prompt again. Do not
   foreground a wait and do not end a turn asking the user to check back — a
   foreground wait burns the turn holding a `sleep`, and a timeout ends it
   with nothing delivered. `scripts/await-session` remains for a deliberate
   blocking wait that also prints the pane tail.
   A `pending` or `blocked` session gets `scripts/read-session` and one
   re-request before escalating to the user.
5. Report outcomes and ask the session to clean its repository (commit, remove
   worktree). Leave its context standing — it is the evidence behind the
   report, and the next delegation clears it in step 2. Retiring the pane
   (`scripts/clean-session <name> --close`) is for sessions this skill
   launched, only when the user asks.
6. When the user asks for a session clean-up, `scripts/sweep-sessions` reads
   every pane and prints a verdict: `empty`, `done`, `pending`, or the herdr
   status of a pane too busy to read. Adding `--close` retires the empty and
   done ones and nothing else, because a `pending` session is either waiting
   on an answer or finished without a sentinel and the screen cannot tell
   which. Report the pending ones and let the user decide. Run it dry first
   when the sweep covers sessions whose output has not been collected yet —
   closing a `done` session discards the report behind it.
   `scripts/verify-verdicts` checks the classifier against captured screens;
   run it when a session is misclassified, since the agent's screen markers
   are the only evidence it has.

## Worked example — "add object detection to camera"
1. Not workspace-level work → this skill. Route: research → `notes`,
   implementation → `camera`.
2. Launch two Opus-med sessions in `notes` and send both surveys: license-free
   TFLite detection models; frequent photo subjects. Put both under one
   `Monitor` watch and carry on with other work.
3. Each survey arrives as its own notification. When the second lands, send a
   third prompt: curate the wiki from the two survey outputs.
4. Launch one Fable-high session in `camera`: plan the next version and drive
   its own subagents for implementation and evaluation (`--worktree`). One
   session, so watch it with a background `Bash` call.
5. Its line arrives as `done`, or as `pending` when it stopped early — then
   read the output and re-request the remainder. Have it clean the repository
   and report the summary. The sessions stay as they are; the next delegation
   to `notes` or `camera` clears them when it claims them.
