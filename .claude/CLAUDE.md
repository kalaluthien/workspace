# Workspace catalogue
`~/workspace` is a container: each entry is its own git repository with its own
context. The container root is itself a whitelist git repository that tracks
only `.claude/` and `scripts/` (workspace tooling); never run one git command
across project entries, and never commit an entry's files to the root repo.

Route by intent, then read that entry's own documents first — everything about
*how* to work in an entry lives in the entry.

| entry | route here when the request is about | read first |
| --- | --- | --- |
| `notes/` | research, surveys, study notes, wiki curation, blog writing or publishing, Obsidian | `.claude/CLAUDE.md` |
| `camera/` | the Android camera app: features, bugs, specs, releases, APK install, emulator tests | `.claude/CLAUDE.md`, then `docs/README.md` |
| `mabinogi-mobile-automation/` | the 마비노기 모바일 game window: park, show, screenshot, start, quit | `.claude/CLAUDE.md` |
| `kalaluthien.github.io/` | site theme, Jekyll config, deployment — content itself is synced from `notes/`, edit it there | `_config.yml` |
| `scripts/` | workspace-level herdr tooling (`herdr-survey`, `herdr-spawn-claude`) | script headers |

A request that spans entries (research + implementation, multi-repo work) is an
orchestration request: load the `/delegating` skill.

# Herdr session
Herdr is the one terminal interface over all of these repositories; `herdr`
attaches to its persistent server. Installed version 0.7.4 — before scripting a
subcommand, check `herdr <subcommand> --help` (unknown commands print help
silently instead of failing; see the `setup-herdr` memory).

1. One herdr workspace per repository, labelled with the repository directory
   name, `cwd` at the repository root. The label is the routing key.
2. Run `scripts/herdr-survey [--json]` before editing anything — it shows every
   repository's branch, dirty count, worktrees, unpushed commits, and which
   agents hold it.
3. `HERDR_ENV=1` means you are inside a herdr pane; `HERDR_WORKSPACE_ID`,
   `HERDR_TAB_ID`, `HERDR_PANE_ID` say where. Every command prints JSON —
   parse IDs with `jq`, never from screen order.
4. Session lifecycle (find, name, launch, send, await, report, clean) is owned
   by the `/delegating` skill and its scripts — use them instead of raw herdr
   calls.
5. Never close a workspace, tab, or pane you did not create; never run
   `herdr server stop` unasked. Keep background work on `--no-focus`.

# Concurrent agents
Several agents work these repositories at the same time.

1. Survey before editing (`scripts/herdr-survey`), and scope edits so they do
   not collide with other worktrees, sessions, and uncommitted changes.
2. Work in your own worktree and branch; keep commits atomic; rebase onto what
   landed instead of force-pushing over it. An agent that assumes exclusive
   ownership silently reverts work it never read.
3. Do not `cd` into a git worktree inside a command chain that later merges or
   removes it — the merge runs inside the worktree ("already up to date") and
   the removal deletes the shell's own cwd. Operate on worktrees from the main
   checkout with `git -C <path>`.
4. Background subagent shells can die silently on this machine: treat an agent
   quiet for ~10 minutes as suspect and probe its process with `pgrep` instead
   of waiting longer.
5. Before touching work another agent owns, check it has actually finished,
   and explain the why in the commit body. A terse message on someone else's
   work reads as an unauthorized commit — a peer has reverted one and reported
   it as a security incident. (2026-07-26)

# Git conventions
From `~/.dotfiles/git/gitconfig` plus lessons that cost real time.

1. `init.defaultBranch = main`, `pull.default = simple`, `rerere` enabled,
   `diff.colorMoved = default`.
2. No global `user.name`/`user.email` — identity is per-repo. Before the first
   commit in a repo, confirm `git config user.email` is set there.
3. A release tag names the commit that produced the artifact, not `HEAD`.
   Before adding "one more fix" to a release whose commit already exists, check
   which tree the tag will point at; when the fix must ship and nothing is
   pushed yet, rewrite the unpushed history so the fix precedes the release
   commit, then rebuild the artifact from that tree.

# Machine setup
Machine and tool facts (Android/JVM toolchain, uv-only Python, shell aliases
and traps, remote access, herdr install) live as `setup-*` topic memories in
the global pool — `~/.claude/projects/-Users-hyungmokim--claude/memory/`.
Check its `MEMORY.md` and read the matching topic before that kind of work.
