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
   model/effort, status, and tab capacity. Reuse an idle session whose name
   matches the needed model and effort; otherwise
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
4. Monitor as a loop, not a blocking workflow: on each tick,
   `scripts/await-session <name> --match "DONE <name>" --timeout <short>`;
   a session that went idle without its sentinel gets `scripts/read-session`
   and one re-request before escalating to the user. Fire-and-forget sends
   (surveys, curation) skip awaiting and are collected on a later tick.
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
2. Launch two Opus-med sessions in `notes`; fire-and-forget: survey
   license-free TFLite detection models; survey frequent photo subjects.
3. When both sentinels appear, send a third prompt: curate the wiki from the
   two survey outputs.
4. Launch one Fable-high session in `camera`: plan the next version and drive
   its own subagents for implementation and evaluation (`--worktree`).
5. Loop until its sentinel: if it stops idle without `DONE`, read output and
   re-request the remainder; then have it clean the repository and report the
   summary. The sessions stay as they are; the next delegation to `notes` or
   `camera` clears them when it claims them.
