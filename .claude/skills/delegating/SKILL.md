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
3. `scripts/send-prompt <name> [--worktree]` — the script appends what the
   session cannot see: sibling-session collision warnings, the worktree
   convention, and a `DONE <name>` completion sentinel.
4. Monitor as a loop, not a blocking workflow: on each tick,
   `scripts/await-session <name> --match "DONE <name>" --timeout <short>`;
   a session that went idle without its sentinel gets `scripts/read-session`
   and one re-request before escalating to the user. Fire-and-forget sends
   (surveys, curation) skip awaiting and are collected on a later tick.
5. Report outcomes, ask the session to clean its repository (commit, remove
   worktree), then `scripts/clean-session <name>` (/clear for reuse;
   `--close` only for sessions this skill launched, only when requested).

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
   re-request the remainder; then have it clean the repository; report the
   summary and clear the sessions.
