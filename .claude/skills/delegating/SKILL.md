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
2. Name the session for the work, `<role>-<task>` — `survey-tflite-detectors`,
   `build-preview-crash`, `plan-camera-v3`. The name is the routing key for
   every later step, so it must say what the pane is for; a reader of
   `herdr agent list` learns the repository from the pane's `cwd` and the model
   from the role, and neither belongs in the name. The role is one of five, and
   it decides the model, per the global sub-agent preference:

   | role | the work | launched as |
   | --- | --- | --- |
   | `survey` | web research, reading, search | Opus medium |
   | `build` | implementation, fixes, script runs | Opus medium |
   | `plan` | design and planning | Opus high |
   | `curate` | organizing knowledge already gathered | Opus high |
   | `drive` | a delegate that orchestrates its own sub-agents | Fable high |

3. `scripts/check-sessions <repo>` — live sessions with name, role, status,
   verdict, and tab capacity. Reuse a session of the role the new task needs
   whose verdict is `empty` or `done`; the verdict decides, not the status,
   because a session that pauses mid-turn reports idle and claiming it would
   clear work still running. Otherwise
   `scripts/launch-session <repo> <role>-<task>` (capacity: a tab never exceeds
   4 panes; `--model`/`--effort` override the role's mapping for one session).
   Claim a reused session here, before sending:
   `scripts/clean-session <name> --rename <role>-<task>` resets it to a
   known-empty context and renames the pane for the new task, because a session
   found idle carries both the last delegation's context and its name. The role
   has to stay the same — the pane keeps the model and effort `claude` started
   with, and a claim does not switch them — so a task in another role is a new
   session, however free the pane looks. A session launched in this step arrives
   clean and correctly named.
4. `scripts/send-prompt <name> [--worktree]` — the script appends what the
   session cannot see: sibling-session collision warnings, the worktree
   convention, and a `DONE <name>` completion sentinel.
5. Wait with the harness, not with the turn. `scripts/watch-sessions <name>...`
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
6. Report outcomes and ask the session to clean its repository (commit, remove
   worktree). Leave its context standing — it is the evidence behind the
   report, and the next delegation clears and renames it in step 3. Retiring
   the pane (`scripts/clean-session <name> --close`) is for sessions this skill
   launched, only when the user asks.
7. When the user asks for a session clean-up, `scripts/sweep-sessions` reads
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
2. Launch `survey-tflite-detectors` and `survey-photo-subjects` in `notes` and
   send both surveys: license-free TFLite detection models; frequent photo
   subjects. The `survey` role puts both on Opus medium. Put them under one
   `Monitor` watch and carry on with other work.
3. Each survey arrives as its own notification. A third question goes to a pane
   already there: `clean-session survey-photo-subjects --rename
   survey-model-licences` claims it, same role, new task. The write-up is
   `curate` work and Opus high, so it gets its own pane — `launch-session notes
   curate-detection-wiki` — with the two survey outputs in its prompt.
4. Launch `drive-camera-detection` in `camera`: the `drive` role gives it Fable
   high, so it can plan the next version and drive its own subagents for
   implementation and evaluation (`--worktree`). One session, so watch it with a
   background `Bash` call.
5. Its line arrives as `done`, or as `pending` when it stopped early — then
   read the output and re-request the remainder. Have it clean the repository
   and report the summary. The sessions stay as they are; the next delegation
   to `notes` or `camera` clears and renames them when it claims them.
