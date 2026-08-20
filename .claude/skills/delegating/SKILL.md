---
name: delegating
description: Orchestrate work across named worker claude sessions in herdr panes, one per ~/workspace repository. Use when a request belongs in a project entry (research → notes, app work → camera, ...) or spans several entries, when the user asks to spawn, reuse, message or monitor agent sessions, or for fire-and-forget surveys beside monitored implementation. Not for work this session can finish in its own cwd, and not for retiring sessions, which is the `clean` command.
---

# Delegating

This session is the orchestrator: it routes, delegates, monitors, and reports —
it does not do the delegated work itself. A session this skill launches and
names is a worker; "session" alone means any claude session in a pane, named
or not. All scripts live in
`scripts/` here, print JSON, and never touch panes they did not create.
Retiring a session is `clean`, a command a person types. Its
rules are still the rules here, and this session reads them as a file —
`.claude/skills/clean/SKILL.md` — because a command is hidden
from the skill list. This skill decides what to run and reads what comes
back; that file says which panes may close and how the board row settles.

## Decision loop
1. Route the request to repository entries with the workspace catalogue
   (`~/workspace/AGENTS.md`).
2. Name the worker for the work, `<role>-<task>` — `survey-tflite-detectors`,
   `build-preview-crash`, `plan-camera-v3`. The name is the routing key for
   every later step and the search key for the worker's history:
   `launch-session` stamps it on the herdr agent and on the claude session
   (`claude --name`), so `/resume` and the transcript under
   `~/.claude/projects/` answer to it after the pane is gone. It must say what
   the pane is for; a reader of `herdr agent list` learns the repository from
   the pane's `cwd` and the model from the role, and neither belongs in the
   name. A worker launched by a board-dispatched service-ticket takes this same
   name behind its namespace — "Board-dispatched service-tickets" below. The role
   is one of five:

   | role | the work |
   | --- | --- |
   | `survey` | web research, reading, search |
   | `build` | implementation, fixes, script runs |
   | `plan` | design and planning |
   | `curate` | organizing knowledge already gathered |
   | `drive` | a delegate that orchestrates its own sub-agents |

   Model and effort follow the global preference (`~/.claude/CLAUDE.md`,
   "Claude Code"): every session launches as Opus, whatever its role, because
   a session owns decisions — what to try, what to commit. `--model fable` is
   the exception, and the task earns it: a problem that is extremely hard, a
   mission that reads two ways, a design with no obvious shape. Never pass it
   because this orchestrator happens to run that tier. Effort is per task, not
   per role: it is a thinking budget, and both breadth and difficulty spend it.
   Pass `--effort high` (or `xhigh`) when the task spans many exceptional cases
   or a large state space, or when its one case is genuinely hard; keep the
   default `medium` (or drop to `low`) when the task is both narrow and well
   understood. Where a ticket is the task, its `#easy` or `#hard` tag is
   that estimate already made at writing time — take it instead of guessing
   again, and take the hardest tag in a batch, since one session works the
   whole set. Subagents a session spawns
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
   `scripts/claim-session <name> --rename <role>-<task>` resets it to a
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
   for that to finish. Then retire the worker: read its output first, close
   only a worker whose verdict is `done` or `empty`, settle its board row
   before the pane goes, and run
   `../clean/scripts/close-session <name>`. Every other rule
   about closing a pane is in `.claude/skills/clean/SKILL.md`,
   which is a file to read rather than a skill to load.
   A worker reports in its own shape — verbose, ordered by
   its criteria walk, blind to the sibling workers. Write the user's report
   instead of forwarding that: keep the results that change what the user
   knows or must do, merge the workers into one narrative, and state the
   conclusions they left implicit. Wording follows the output style,
   "Reporting".
7. A request to clean sessions up, rather than to get work done, is the
   `clean` command's whole subject and not a step of a
   delegation: it sweeps every pane, retires the spent ones, and leaves the
   rest for the user to judge.

## Board-dispatched service-tickets
The board's start action spawns a session whose whole prompt is one
`/delegating` line. It opens with where the backlog-tickets live and which
doors change them, then the namespace clause, then one line per row, each
opening with its own backlog-ticket id. No file appears anywhere in it: a
backlog-ticket lives in the board's store and has no line to edit. The rows it
names are the service-ticket and no others, and each row's state is the
user-visible state of the work — the board draws the card from the row itself.
One row arrives as its own title and body; a batch arrives as a numbered run,
`(1) … (2) …`, in the page's own order, which is the user's priority. Two
calls to the store are part of the service-ticket, not bookkeeping:

1. Claim the row before anything else:
   `PATCH /api/backlog-tickets/<id>/head` with `{"state":"working"}`. The tap
   that spawned this session promised "working", and until the state moves the
   board shows a promise the store denies.
2. End the row on completion, per the Filing rules in `~/.claude/CLAUDE.md`,
   in exactly one of three ways. The work shipped and nothing waits on the
   owner: `DELETE /api/backlog-tickets/<id>`, after lifting any owed remainder
   into its own `#need-you` row. The work is finished but the close waits on
   the owner's review: leave the state `working` and tag the row `#need-you`.
   The work is unfinished and waits on the owner's input: set the state back to
   `open` and tag the row `#need-you`. The tag holds the row's next automatic
   transition, so only the owner ends a tagged row. A session that ends with
   the row `working` and no such tag leaves a card that reads as running
   forever.

`done` is reachable only through `DELETE`. The head door refuses it
(`check_state`), so a row's settled state never has two places it could live.
A close keeps the row for good and the board stops drawing it, so a closed row
is a permanent record rather than a deletion.

When the row's scope turns out to hold a technical decision that is unknown
or open to more than one reading, do not finish the row by choosing an answer
yourself: the tap asked for the work, not for the decision behind it, and a
guess ships as if the owner had made it. Write a proposal instead, in that
project's own docs and per the workspace document system — named options,
their trade-offs, one recommendation — and commit it. Then file a new
`#need-you` backlog-ticket in the same pool naming the decision, with a
sentence or two on why it blocks the work and a pointer to the proposal —
through the board's filing door (`~/.claude/CLAUDE.md`, Filing, "Tickets").
Hand your own row back the third way above — unfinished, waiting on the
owner's input — and name the blocking row in its body, so a re-tap meets the
decision instead of the same ambiguity.

When the line naming one row also says the owner tapped Start on it
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

When the line names several rows, the service-ticket is exactly those rows, in
that order, and no other row of the pool however workable it looks. The board
froze that set at the tap and claims exactly it, so a row you add is a row
nobody claimed and nobody measures — worked beside whatever already held it,
and still running when the board calls the batch finished. A row filed after
the tap is not the batch's; it takes a second tap. Claim every named row
before anything else, one `PATCH .../head` call each: until the states move the
board shows a promise the store denies, and the rows are already held against a
second tap.

With no row named after the doors at all — a line typed by hand, never one the
board sends — the service-ticket is the whole pool: every row whose state is
`open` and which carries no tag waiting on the owner, read from
`GET /api/snapshot`, in the order it lists them.

Then run them as separate service-tickets, and close each row as its own work
ships — not the batch at the end. Fan out only where the changes cannot meet;
they land in one repository, so each takes its own worktree and anything
touching the same files runs in sequence. Keep at most three running, so one
`Monitor` watch covers them.

Name every session a board-dispatched service-ticket launches inside the
namespace, which the board's own line hands you: `st-<id>--<role>-<task>`,
the same `<role>-<task>` as anywhere else with that prefix in front. It is
what makes a worker reachable by anything but this session: the board's cancel
interrupts every pane in the namespace and closes it once the service-ticket
settles, and a worker named outside the namespace survives a cancelled
service-ticket with nobody able to name it. Two prices, both known and neither
a reason to shorten the prefix. herdr allows 32 characters and
`launch-session` clips at 29 to leave room for its duplicate suffix, so the
prefix spends about 13 and the task part is cut to about 16 — a worked example
in this file can lose letters. And a clipped name is no longer a `/resume` key,
so a worker launched this way is found through its row rather than through its
own transcript.

End the batch with no row still `working` and untagged. Work you will not
finish is retagged `#need-you`, which hands that row back and is a correct
outcome; so is a `working` + `#need-you` row, which says the work is finished
and the close is held for the owner. A row left working with no such tag reads
as a session that is still running, and the board waits on it for ever.

A worker can ship the work, print its sentinel, and still leave its row
`working`, so a row's state is read before its pane goes. That check belongs to
the retirement and lives with it, in
`.claude/skills/clean/SKILL.md`.

## Worked example — "add object detection to camera"
1. Not workspace-level work → this skill. Route: research → `notes`,
   implementation → `camera`.
2. Launch `survey-tflite-detectors` and `survey-photo-subjects` in `notes` and
   send both surveys: license-free TFLite detection models; frequent photo
   subjects. Both questions are narrow, so the default effort stands. Put them
   under one `Monitor` watch and carry on with other work.
3. Each survey arrives as its own notification. A third question goes to a pane
   already there: `claim-session survey-photo-subjects --rename
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
   retire each worker as its output lands (`close-session`), and
   report the summary. The transcripts keep the evidence under the workers'
   names.
