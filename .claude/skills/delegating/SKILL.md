---
name: delegating
description: Orchestrate work across named worker claude sessions in herdr panes, one per ~/workspace repository. Use when a request belongs in a project entry (research → notes, app work → camera, ...) or spans several entries, when the user asks to spawn, reuse, message, monitor, or clean agent sessions, or for fire-and-forget surveys beside monitored implementation. Not for work this session can finish in its own cwd.
---

# Delegating

This session is the orchestrator: it routes, delegates, monitors, and reports —
it does not do the delegated work itself. A session this skill launches and
names is a worker; "session" alone means any claude session in a pane, named
or not. All scripts live in
`scripts/` here, print JSON, and never touch panes they did not create.

## Decision loop
1. Route the request to repository entries with the workspace catalogue
   (`~/workspace/.claude/CLAUDE.md`).
2. Name the worker for the work, `<role>-<task>` — `survey-tflite-detectors`,
   `build-preview-crash`, `plan-camera-v3`. The name is the routing key for
   every later step and the search key for the worker's history:
   `launch-session` stamps it on the herdr agent and on the claude session
   (`claude --name`), so `/resume` and the transcript under
   `~/.claude/projects/` answer to it after the pane is gone. It must say what
   the pane is for; a reader of `herdr agent list` learns the repository from
   the pane's `cwd` and the model from the role, and neither belongs in the
   name. The role is one of five:

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

3. `scripts/check-sessions <repo>` — live workers with name, role, status,
   and verdict. Reuse a worker of the role the new task needs whose verdict
   is `empty` or `done`; the verdict decides, not the status, because a
   worker that pauses mid-turn reports idle and claiming it would clear work
   still running. A `done` worker still standing was never collected — step 6
   closes a collected one — so read its tail before claiming it.
   Otherwise `scripts/launch-session <repo> <role>-<task>`
   (every session gets a tab of its own, so a launch never splits a pane and
   never runs out of room; pick `--effort` from the task's breadth per step 2;
   `--model` is an escape hatch for one session).
   Claim a reused session here, before sending:
   `scripts/clean-session <name> --rename <role>-<task>` resets it to a
   known-empty context and renames both sides — the herdr agent and the claude
   session — for the new task, because a worker found idle carries both the
   last delegation's context and its name. The role has to stay the same, and
   the new task's breadth has to fit the effort the
   pane launched with — the pane keeps the model and effort `claude` started
   with, and a claim does not switch them — so a task in another role, or one
   much wider than the pane's effort, is a new worker, however free the pane
   looks. A worker launched in this step arrives clean and correctly named.
4. `scripts/send-prompt <name> [--worktree]` — the script appends what the
   worker cannot see: sibling-session collision warnings, the worktree
   convention, and a `DONE <name>` completion sentinel. A task shaped as a
   mission with completion criteria opens with `/goal` on the prompt's first
   line — `/goal <mission, then the criteria>` — so the worker loops on its
   own until its judge model reports the criteria met; the appended sentinel
   rides inside the goal text and still prints when the goal clears.
   A mission whose report will exceed one screen names a scratch file for the
   full deliverable in the prompt — `read-session` captures only the pane
   tail, and a report that scrolled off is a second round-trip to recover.
5. Wait with the harness, not with the turn. `scripts/watch-sessions <name>...`
   prints one line per worker the moment it stops needing the orchestrator —
   `done` on its sentinel, `blocked` on a permission prompt, `gone` on a
   closed pane, `pending` when it goes quiet without finishing — and exits
   when the last one lands. Run it two ways, by how many wake-ups the wait
   needs:
   - One session: a background `Bash` call. It exits on the single event and
     the harness re-invokes this session with the line.
   - Several: the `Monitor` tool. Each worker that lands is a notification,
     and the watch ends itself when all of them have.
   Neither blocks the turn, and neither needs the user to prompt again. Do not
   foreground a wait and do not end a turn asking the user to check back — a
   foreground wait burns the turn holding a `sleep`, and a timeout ends it
   with nothing delivered. `scripts/await-session` remains for a deliberate
   blocking wait that also prints the pane tail.
   While a watch stands, spend no turns checking the workers it covers — no
   `read-session`, `check-sessions`, or `sweep-sessions` between events. Each
   check turn re-reads the orchestrator's whole context to learn what the
   watch will deliver anyway; read a worker once, when its line arrives.
   A `pending` or `blocked` worker gets `scripts/read-session` and one
   re-request before escalating to the user. `blocked` also covers a session
   usage limit; the message names a reset time that can already be past when
   the watch fires — read the clock before scheduling any wait, and resume at
   once when the reset has passed.
6. Collect and retire. Read the worker's output, and when its repository still
   holds uncommitted work, have it clean up (commit, remove worktree) and wait
   for that to finish. Then close the pane:
   `scripts/clean-session <name> --close`. Close only after the output is
   collected — closing first discards the pane tail — and close only `done`
   workers; a `pending` or `blocked` one still needs a re-request or an
   answer. The pane is not the evidence behind the report: the worker's
   transcript under `~/.claude/projects/` is, and it answers to the worker's
   name in `/resume`. A worker reports in its own shape — verbose, ordered by
   its criteria walk, blind to the sibling workers. Write the user's report
   instead of forwarding that: keep the results that change what the user
   knows or must do, merge the workers into one narrative, and state the
   conclusions they left implicit. Wording follows the output style,
   "Reporting".
7. When the user asks for a session clean-up, `scripts/sweep-sessions` reads
   every pane and prints a verdict: `empty`, `done`, `pending`, or the herdr
   status of a pane too busy to read. Adding `--close` retires the empty and
   done ones and nothing else, because a `pending` session is either waiting
   on an answer or finished without a sentinel and the screen cannot tell
   which. Sessions in the container root itself (repo `workspace`) are reported
   but never closed by a bare sweep — `--include-workspace`, or naming the root
   as the sweep's target, is the explicit user request that reaches them.
   Report the pending ones and let the user decide. Run it dry first
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
2. End the item on completion, per the Filing rules in `~/.claude/CLAUDE.md`,
   in exactly one of three ways. The work shipped and nothing waits on the
   owner: delete the row, after lifting any owed remainder into its own
   `#need-you` item. The work is finished but the close waits on the owner's
   review: leave the marker `[/]` and tag the row `#need-you`. The work is
   unfinished and waits on the owner's input: put the marker back to `[ ]` and
   tag the row `#need-you`. The tag holds the item's next automatic
   transition, so only the owner ends a tagged row. A session that ends with
   the marker still `[/]` and no such tag leaves a card that reads as running
   forever.

When the item's scope turns out to hold a technical decision that is unknown
or open to more than one reading, do not finish the item by choosing an answer
yourself: the tap asked for the work, not for the decision behind it, and a
guess ships as if the owner had made it. Write a proposal instead, in that
project's own docs and per the workspace document system — named options,
their trade-offs, one recommendation — and commit it. Then append a new
`#need-you` row to the same backlog file naming the decision, with a sentence
or two on why it blocks the work and a pointer to the proposal. Hand your own
row back the third way above — unfinished, waiting on the owner's input —
and name the blocking row in its body, so a re-tap meets the decision instead
of the same ambiguity.

When the line naming one item also says the owner tapped Start on it
themselves, that tap is under the owner's own finger, so it confirms — but the
board has no interface for a choice, so it cannot decide. Read the row and the
proposal it points to, and judge what the row's owner-waiting tag was waiting
for. Waiting for a confirmation — one stated recommendation, needing only
acceptance: the tap is that acceptance. Record it in the proposal document,
drop the owner-waiting tag as you claim the row, and do the work the row names.
Waiting for a decision — a choice among options, or an input only the owner can
give: the tap does not carry it, and reading it as picking the recommendation
decides a question the owner never answered. Ask the owner with the
`AskUserQuestion` tool, options taken from the proposal and the recommendation
first, then record the answer in the proposal document, drop the tag, and do the
work the answer selects. Either way, do not ask the owner anything the
confirmation already answered.

With no item after the pool file, the mission is the whole page: every item
whose marker is `[ ]` and which carries no tag waiting on the owner — the
same rows the board's own Start all selects — in the order the file lists them,
which is the user's own priority. Claim them in one edit before anything
else, for the reason a single claim is made: until the markers move the
board shows a promise the corpus denies, and the rows are already held
against a second tap.

Then run them as separate missions, and close each item as its own mission
ships — not the batch at the end. Fan out only where the missions' changes
cannot meet; they land in one repository, so each takes its own worktree and
anything touching the same files runs in sequence. Keep at most three
running, so one `Monitor` watch covers them.
Re-read the backlog file immediately before every close: filings and other
tickets edit it while you work, and a rewrite from the copy you read at
claim time drops their rows.

End the batch with no row still `[/]` and untagged. A mission you will not
finish is retagged `#need-you`, which hands that row back and is a correct
outcome; so is a `[/] #need-you` row, which says the work is finished and the
close is held for the owner. A row left working with no such tag reads as a
session that is still running, and the board waits on it for ever.

When the orchestrator collects a board-dispatched session, it checks the
item's marker before reporting: a worker can ship the work, print its
sentinel, and still leave the row `[/]`. Close the item yourself then — the
work is verified by the report you just read, and re-asking the session costs
a round-trip for one line. Do not close a row tagged `#need-you`: the tag
holds the automatic close, and only the owner closes it.

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
   read the output and re-request the remainder. Have it clean the repository,
   close each worker as its output lands (`clean-session <name> --close`), and
   report the summary. The transcripts keep the evidence under the workers'
   names.
