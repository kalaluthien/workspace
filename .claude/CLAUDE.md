# Workspace layout
`~/workspace` is a container holding two kinds of directory. The kind decides
which git repository a change lands in, so identify it before any git command.

**Workspace-owned directories** belong to the container root — itself a
whitelist git repository whose `.gitignore` ignores `/*` and re-admits only
these. A change here is committed to the root repository:

| directory | holds | read first |
| --- | --- | --- |
| `.claude/` | workspace instructions, conditional rules, skills, output styles | this file |
| `docs/` | workspace-level specs and views, over both planes, plus the machine contract every `docs/` reader parses | `docs/README.md` |
| `hooks/` | this repository's own git hooks, chained after the shared guard by `.git/local-hooks/pre-commit` | `hooks/pre-commit` |
| `scripts/` | workspace-level herdr tooling (`herdr-survey`, `herdr-update`) and `check-docs` | script headers |

A document request whose topic belongs to no project entry lands in `docs/`,
as a spec (`.md`) or a view (`.html`) — never in a project entry it does not
fit, and never in chat alone. The document system's rules live in the
`writing` skill, `.claude/skills/writing/` (`SKILL.md` with `references/`,
`scripts/`, and `evals/` beside it); a document about one project entry
still belongs in that entry's own document store, which follows the same
system; view writing runs through the `writing` skill, which forks its own
context and returns one message.

The workspace is a control plane over **agents** — the entries above and the
sessions that work them — and over **services**, the long-running things those
entries expose. A `docs/` filename carries a plane prefix (naming: the
`writing` skill's `references/doctypes.md`), and the plane's own rules load from `.claude/rules/`
when a matching document is read.

**Project entries** are independent git repositories, each with its own
context, all git-ignored by the root. Never run one git command across
entries, and never commit an entry's files to the root repository. Route by
intent, then read that entry's own documents first — everything about *how*
to work in an entry lives in the entry:

| entry | route here when the request is about | read first |
| --- | --- | --- |
| `notes/` | research, surveys, study notes, wiki curation, blog writing or publishing, Obsidian | `.claude/CLAUDE.md` |
| `camera/` | the Android camera app: features, bugs, specs, releases, APK install, emulator tests | `.claude/CLAUDE.md`, then `docs/README.md` |
| `garden/` | the Android plant-watering app: its design, features, bugs, releases | `.claude/CLAUDE.md`, then `docs/README.md` |
| `mabinogi-mobile-automation/` | the 마비노기 모바일 game window: park, show, screenshot, start, quit | `.claude/CLAUDE.md` |
| `board/` | the board web app: task board, docs rendering, search, its server, container, tailscale exposure | `.claude/CLAUDE.md`, then `docs/INDEX.md` |
| `kalaluthien.github.io/` | site theme, Jekyll config, deployment — content itself is synced from `notes/`, edit it there | `_config.yml` |

A request that spans entries (research + implementation, multi-repo work) is an
orchestration request: load the `/delegating` skill.

# Technical knowledge
`notes/` is the one cache for technical survey knowledge. `wiki/index.md` lists
every page with a one-line summary, `wiki/*.md` are the timeless concept pages,
and `journal/YYYY-MM-DD-slug.md` are the dated survey reports the pages
distill. Read the cache before the web, and write the web back into it. An
answer that stays in chat history is lost.

1. Read the wiki first. Before any technical survey or web search, read
   `notes/wiki/index.md` in this session, then the concept pages it names.
   These are plain file reads and need no delegation. Cite the page you used,
   for example "per `notes/wiki/on-device-ml-runtimes.md`", so the reader can
   check it.
2. Judge the gap yourself. The wiki answers the question, answers it partly or
   stale, or does not cover it. Only the last two conditions reach the web.
   - The wiki answers it: answer from the page and stop. No survey.
3. Delegate every web survey to `notes`. Load the `/delegating` skill and send
   one survey prompt per question. This session does not run the survey itself,
   even for a single search, because the answer must land in the vault and only
   an agent in `notes` can commit it there.
4. Ask for the write-back in the prompt. A survey prompt that asks only for an
   answer gets an answer in chat and leaves the cache empty. Name the outputs:
   one dated report in `journal/`, plus the concept pages and `wiki/index.md`
   updated.
5. Report the paths with the answer. Name the journal and wiki files the survey
   produced, so the next agent starts at step 1 instead of at the web.

A survey prompt carries four things: the question in one sentence, the wiki
pages already read and what they miss, the decision the answer feeds, and the
required outputs from step 4. It carries nothing about *how* the report is
shaped — front matter, filenames, links, and commits are the `notes` entry's
own conventions, and restating them in a prompt only competes with them.

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
2. Rebase your branch onto what landed instead of force-pushing over it. An
   agent that assumes exclusive ownership silently reverts work it never read.
   The branch-per-patch rule itself is in `~/.claude/CLAUDE.md`, "Code to work".
3. Before touching work another agent owns, check it has actually finished,
   and explain the why in the commit body. A terse message on someone else's
   work reads as an unauthorized commit — a peer has reverted one and reported
   it as a security incident. (2026-07-26)
4. A background agent quiet for about 10 minutes is suspect: probe its process
   with `pgrep` instead of waiting longer. Its shell can die silently here.
5. Before reporting that a delegate exceeded its scope, survey the live panes
   and match commit subjects to session names. A sibling launched by another
   operator often owns the surprising commit, and a wrong attribution turns a
   correct report into a false incident.

# Git identity
There is no global `user.name`/`user.email` — identity is per-repo. Confirm
`git config user.email` inside a repository before its first commit there.
Other git config defaults are in the `setup-git` memory; worktree and release-
tag rules are in `~/.claude/CLAUDE.md`, "Craft".

# Machine setup
Machine and tool facts (Android/JVM toolchain, uv-only Python, shell aliases
and traps, remote access, git config, herdr install) live as `setup-*` topic
memories in the global pool — `~/.claude/projects/-Users-hyungmokim--claude/memory/`.
Check its `MEMORY.md` and read the matching topic before that kind of work.
