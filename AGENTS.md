# Workspace layout

`~/workspace` is a container holding two kinds of directory, and the kind decides which git repository a change lands in, so identify it before any git command.

**Workspace-owned directories** belong to the container root — itself a whitelist git repository whose `.gitignore` ignores `/*` and re-admits only this file, the `CLAUDE.md` beside it that imports it, and these. A change here is committed to the root repository.

| directory | holds | read first |
| --- | --- | --- |
| `.claude/` | conditional rules, skills, and output styles | this file |
| `docs/` | workspace-level views (`.html`), over both planes, plus the machine contract every `docs/` reader parses | `docs/README.md` |
| `hooks/` | this repository's own git hooks, chained after the shared guard by `.git/local-hooks/pre-commit` | `hooks/pre-commit` |
| `scripts/` | workspace-level herdr tooling (`herdr-survey`, `herdr-update`), `check-docs` and its test | script headers |
| `spec/` | workspace-level specifications (`.md`), over both planes, and the spec template every entry resolves | `spec/README.md` |

**Project entries** are independent git repositories, each with its own context, all git-ignored by the root. Never run one git command across entries, and never commit an entry's files to the root repository. Route by intent, then read that entry's own documents first — everything about *how* to work in an entry lives in the entry.

| entry | route here when the request is about | read first |
| --- | --- | --- |
| `notes/` | research, surveys, study notes, wiki curation, blog writing or publishing, Obsidian | `AGENTS.md` |
| `camera/` | the Android camera app: features, bugs, specs, releases, APK install, emulator tests | `AGENTS.md`, then `docs/README.md` |
| `garden/` | the Android plant-watering app: its design, features, bugs, releases | `AGENTS.md`, then `docs/README.md` |
| `mabinogi-mobile-automation/` | the 마비노기 모바일 game window: park, show, screenshot, start, quit | `AGENTS.md` |
| `board/` | the board web app: task board, docs rendering, search, its server, container, tailscale exposure | `AGENTS.md`, then `docs/INDEX.md` |
| `kalaluthien.github.io/` | site theme, Jekyll config, deployment — content itself is synced from `notes/`, edit it there | `_config.yml` |

A request whose topic belongs to no project entry lands at the root — never in a project entry it does not fit, and never in chat alone. Which directory follows from the kind: a normative statement is a specification and lands in `spec/`, and a page drawn for a reader is a view and lands in `docs/`. The two are kept apart and neither inherits the other's rules.

The workspace is a control plane over **agents** — the entries above and the sessions that work them — and over **services**, the long-running things those entries expose. A `docs/` filename carries a plane prefix, and the plane's own rules load from `.claude/rules/` when a matching document is read.

A request that spans entries is an orchestration request: load the `delegating` skill. A document about one project entry belongs in that entry's own document store, and writing a view runs through the `writing` skill, which forks its own context and returns one message.

# Ad-hoc work

A job the owner typed straight into a session gets a row too — the board is the one record of what these repositories are worked on, and an ask that never became a ticket leaves nothing behind. File it into the pool of the entry the work lands in, and file it already taken — one call both files the row and puts your name on it, so a row of yours is never briefly unheld. The doors and the ticket grammar are in the `delegating` skill, "Board's doors".

File before the first write that outlives the session — a commit, a document, a deploy, a worker you send — and never after it. Judging a job short enough to file at the end is a judgment made before the work is understood, and a row that appears once the work is over was never the thing the owner watched.

A row covering a neighbouring piece of the work is not this job's row. Working under one puts your job on somebody else's scope and leaves your own unrecorded; file yours and let the two name each other.

Leave the row open. A closed ticket draws no card anywhere, so one filed and closed in the same breath is a record nobody reads; the open row is what puts the finished job in front of the owner, who closes it from the phone.

# Technical knowledge

`notes/` is the one cache for technical survey knowledge: `wiki/index.md` lists every page with a one-line summary, `wiki/*.md` are the timeless concept pages, and `journal/YYYY-MM-DD-slug.md` are the dated survey reports the pages distill. Read the cache before the web, and write the web back into it, because an answer that stays in chat history is lost.

Read the wiki first. Before any technical survey or web search, read `notes/wiki/index.md` in this session and then the concept pages it names — plain file reads, no delegation — and cite the page you used, so the reader can check it. If the wiki answers the question, answer from the page and stop.

Only a partial, stale, or missing answer reaches the web, and every web survey is delegated to `notes` through the `delegating` skill, one prompt per question, because the answer must land in the vault and only an agent in `notes` can commit it there.

A survey prompt carries four things: the question in one sentence, the wiki pages already read and what they miss, the decision the answer feeds, and the required outputs — one dated report in `journal/`, plus the concept pages and `wiki/index.md` updated. It carries nothing about how the report is shaped, which is the `notes` entry's own convention. Report the paths the survey produced beside the answer, so the next agent starts at the wiki instead of at the web.

# Herdr sessions

Herdr is the one terminal interface over these repositories. The session lifecycle — find, name, launch, send, await, report — is owned by the `delegating` skill, and retiring a session by the `clean` command; use their scripts instead of raw herdr calls. Install, version, environment, and output-parsing facts are in the `setup-herdr` memory.

One herdr workspace per repository, labelled with the repository directory name and `cwd` at the repository root. The label is the routing key.

Run `scripts/herdr-survey [--json]` before editing anything — it shows every repository's branch, dirty count, worktrees, unpushed commits, and which agents hold it.

Never close a workspace, tab, or pane you did not create, and never run `herdr server stop` unasked. Keep background work on `--no-focus`.

# Concurrent agents

Several agents work these repositories at the same time, so survey before editing and scope your edits so they do not collide with other worktrees, sessions, and uncommitted changes. Rebase your branch onto what landed instead of force-pushing over it, since an agent that assumes exclusive ownership silently reverts work it never read.

Before touching work another agent owns, check it has actually finished, and explain the why in the commit body — a terse message on someone else's work reads as an unauthorized commit, and a peer has reverted one and reported it as a security incident.

Before reporting that a delegate exceeded its scope, survey the live panes and match commit subjects to session names, because a sibling launched by another operator often owns the surprising commit and a wrong attribution turns a correct report into a false incident.

# Machine setup

Machine and tool facts — the Android and JVM toolchain, uv-only Python, shell aliases and traps, remote access, git config and its per-repository identity, herdr install — live as `setup-*` topic memories in the global pool, `~/.claude/projects/-Users-hyungmokim--claude/memory/`. Check its `MEMORY.md` and read the matching topic before that kind of work.
