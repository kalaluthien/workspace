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

# Herdr sessions
Herdr is the one terminal interface over these repositories. The session
lifecycle — find, name, launch, send, await, report, clean — is owned by the
`/delegating` skill and its scripts; use them instead of raw herdr calls.
Install, version, environment, and output-parsing facts are in the
`setup-herdr` memory.

1. One herdr workspace per repository, labelled with the repository directory
   name, `cwd` at the repository root. The label is the routing key.
2. Run `scripts/herdr-survey [--json]` before editing anything — it shows every
   repository's branch, dirty count, worktrees, unpushed commits, and which
   agents hold it.
3. Never close a workspace, tab, or pane you did not create; never run
   `herdr server stop` unasked. Keep background work on `--no-focus`.

# Concurrent agents
Several agents work these repositories at the same time.

1. Survey before editing, and scope edits so they do not collide with other
   worktrees, sessions, and uncommitted changes.
2. Work in your own worktree and branch; keep commits atomic; rebase onto what
   landed instead of force-pushing over it. An agent that assumes exclusive
   ownership silently reverts work it never read.
3. Before touching work another agent owns, check it has actually finished,
   and explain the why in the commit body. A terse message on someone else's
   work reads as an unauthorized commit — a peer has reverted one and reported
   it as a security incident. (2026-07-26)
4. A background agent quiet for about 10 minutes is suspect: probe its process
   with `pgrep` instead of waiting longer. Its shell can die silently here.

# Git identity
There is no global `user.name`/`user.email` — identity is per-repo. Confirm
`git config user.email` inside a repository before its first commit there.
Other git config defaults are in the `setup-git` memory; worktree and release-
tag rules are in `~/.claude/rules/craft.md`.

# Machine setup
Machine and tool facts (Android/JVM toolchain, uv-only Python, shell aliases
and traps, remote access, git config, herdr install) live as `setup-*` topic
memories in the global pool — `~/.claude/projects/-Users-hyungmokim--claude/memory/`.
Check its `MEMORY.md` and read the matching topic before that kind of work.
