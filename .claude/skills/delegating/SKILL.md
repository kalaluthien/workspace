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
   from the role, and neither belongs in the name. The role is one of five:

   | role | the work |
   | --- | --- |
   | `survey` | web research, reading, search |
   | `build` | implementation, fixes, script runs |
   | `plan` | design and planning |
   | `curate` | organizing knowledge already gathered |
   | `drive` | a delegate that orchestrates its own sub-agents |

   Model and effort follow the global preference (`~/.claude/CLAUDE.md`,
   "Claude Code"): every session launches as Opus, whatever its role, because
   a session owns decisions — what to try, what to commit — and Fable stays
   with this orchestrator, never below it. Effort is per task, not per role:
   it measures breadth. Pass `--effort high` (or `xhigh`) when the task spans
   many exceptional cases or a large state space; keep the default `medium`
   (or drop to `low`) when the scope is narrow. Subagents a session spawns
   follow the same preference — Opus where they decide, Sonnet where they
   search, classify, or summarize.

3. `scripts/check-sessions <repo>` — live sessions with name, role, status,
   verdict, and tab capacity. Reuse a session of the role the new task needs
   whose verdict is `empty` or `done`; the verdict decides, not the status,
   because a session that pauses mid-turn reports idle and claiming it would
   clear work still running. Otherwise
   `scripts/launch-session <repo> <role>-<task>` (capacity: a tab never exceeds
   4 panes; pick `--effort` from the task's breadth per step 2; `--model` is an
   escape hatch for one session).
   Claim a reused session here, before sending:
   `scripts/clean-session <name> --rename <role>-<task>` resets it to a
   known-empty context and renames the pane for the new task, because a session
   found idle carries both the last delegation's context and its name. The role
   has to stay the same, and the new task's breadth has to fit the effort the
   pane launched with — the pane keeps the model and effort `claude` started
   with, and a claim does not switch them — so a task in another role, or one
   much wider than the pane's effort, is a new session, however free the pane
   looks. A session launched in this step arrives clean and correctly named.
4. `scripts/send-prompt <name> [--worktree]` — the script appends what the
   session cannot see: sibling-session collision warnings, the worktree
   convention, and a `DONE <name>` completion sentinel. A task shaped as a
   mission with completion criteria opens with `/goal` on the prompt's first
   line — `/goal <mission, then the criteria>` — so the session loops on its
   own until its judge model reports the criteria met; the appended sentinel
   rides inside the goal text and still prints when the goal clears.
   A mission whose report will exceed one screen names a scratch file for the
   full deliverable in the prompt — `read-session` captures only the pane
   tail, and a report that scrolled off is a second round-trip to recover.
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
   re-request before escalating to the user. `blocked` also covers a session
   usage limit; the message names a reset time that can already be past when
   the watch fires — read the clock before scheduling any wait, and resume at
   once when the reset has passed.
6. Report outcomes and ask the session to clean its repository (commit, remove
   worktree). A delegate reports in its own shape — verbose, ordered by its
   criteria walk, blind to the sibling sessions. Write the user's report
   instead of forwarding that: keep the results that change what the user
   knows or must do, merge the sessions into one narrative, and state the
   conclusions the delegates left implicit. Wording follows the output
   style, "Reporting". Leave the session's context standing — it is the
   evidence behind the report, and the next delegation clears and renames
   it in step 3. Retiring
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
   `--shells` widens the same sweep to panes holding no session at all. A bare
   shell reads as `shell` when its foreground process group is the shell
   itself and `shell-busy` while a command holds it, and only the idle ones
   close. Empty tabs and workspaces need no step of their own — herdr retires
   a tab when its last pane closes, and a workspace when its last tab does.
   `scripts/verify-verdicts` checks the classifier against captured screens;
   run it when a session is misclassified, since the agent's screen markers
   are the only evidence it has.

## Board-dispatched missions
The board's start action spawns a session whose whole prompt is one line:
`/delegating <pool board file> <item title and body>`. When the arguments open
with a pool board file path, the mission is that one backlog item, and the
item's marker is the user-visible state of the job — the board renders the
file on every scan. Two writes to that file are part of the mission, not
bookkeeping:

1. Claim the item before anything else: flip its marker to `[/]` in the named
   file. The tap that spawned this session promised "working", and until the
   marker moves the board shows a promise the corpus denies.
2. Close the item on completion, per the Filing rules in `~/.claude/CLAUDE.md`:
   delete the row when the work shipped, after lifting any owed remainder into
   its own `#need-you` item; retag `#need-you` when the work now waits on the
   owner. A session that ends with the marker still `[/]` leaves a
   card that reads as running forever.

With no item after the pool file, the mission is the whole page: every item
whose marker is `[ ]` and which carries no tag waiting on the owner — the
same rows the board draws Start live on — in the order the file lists them,
which is the user's own priority. Claim them in one edit before anything
else, for the reason a single claim is made: until the markers move the
board shows a promise the corpus denies, and the rows are already held
against a second tap.

Then run them as separate missions, and close each item as its own mission
ships — not the batch at the end. Fan out only where the missions' changes
cannot meet; they land in one repository, so each takes its own worktree and
anything touching the same files runs in sequence. Keep at most three
running, so one `Monitor` watch covers them and a tab keeps a free pane.
Re-read the backlog file immediately before every close: filings and other
tickets edit it while you work, and a rewrite from the copy you read at
claim time drops their rows.

End the batch with no row still `[/]`. A mission you will not finish is
retagged `#need-you`, which hands that row back and is a correct outcome;
a row left working reads as a session that is still running, and the
board waits on it for ever.

When the orchestrator collects a board-dispatched session, it checks the
item's marker before reporting: a delegate can ship the work, print its
sentinel, and still leave the row `[/]`. Close the item yourself then — the
work is verified by the report you just read, and re-asking the session costs
a round-trip for one line.

## Worked example — "add object detection to camera"
1. Not workspace-level work → this skill. Route: research → `notes`,
   implementation → `camera`.
2. Launch `survey-tflite-detectors` and `survey-photo-subjects` in `notes` and
   send both surveys: license-free TFLite detection models; frequent photo
   subjects. Both questions are narrow, so the default effort stands. Put them
   under one `Monitor` watch and carry on with other work.
3. Each survey arrives as its own notification. A third question goes to a pane
   already there: `clean-session survey-photo-subjects --rename
   survey-model-licences` claims it — same role, similar breadth, new task. The
   write-up is `curate` work, another role, so it gets its own pane —
   `launch-session notes curate-detection-wiki` — with the two survey outputs
   in its prompt.
4. Launch `drive-camera-detection` in `camera` with `--effort high`: the
   mission spans planning, implementation, and evaluation — a wide state
   space — and it has criteria, so the prompt opens with `/goal`. The session
   drives its own subagents in a worktree (`--worktree`): Opus where they
   decide, Sonnet where they search. One session, so watch it with a
   background `Bash` call.
5. Its line arrives as `done`, or as `pending` when it stopped early — then
   read the output and re-request the remainder. Have it clean the repository
   and report the summary. The sessions stay as they are; the next delegation
   to `notes` or `camera` clears and renames them when it claims them.
