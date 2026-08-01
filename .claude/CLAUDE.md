# Workspace layout
`~/workspace` is a container holding two kinds of directory. The kind decides
which git repository a change lands in, so identify it before any git command.

**Workspace-owned directories** belong to the container root — itself a
whitelist git repository whose `.gitignore` ignores `/*` and re-admits only
these. A change here is committed to the root repository:

| directory | holds | read first |
| --- | --- | --- |
| `.claude/` | workspace instructions, conditional rules, skills, output styles | this file |
| `docs/` | workspace-level proposals and how-to guides, over both planes | `docs/README.md` |
| `scripts/` | workspace-level herdr tooling (`herdr-survey`, `herdr-spawn-claude`) | script headers |

A document request whose topic belongs to no project entry lands in `docs/`,
as one of its two chapters — never in a project entry it does not fit, and
never in chat alone. A document about one project entry still belongs in that
entry's own document store.

The workspace is a control plane over **agents** — the entries above and the
sessions that work them — and over **services**, the long-running things those
entries expose. A `docs/` filename carries its plane as a prefix,
`agent-<slice>` or `service-<slice>`, and the plane's own rules load from
`.claude/rules/` when a matching document is read.

**Project entries** are independent git repositories, each with its own
context, all git-ignored by the root. Never run one git command across
entries, and never commit an entry's files to the root repository. Route by
intent, then read that entry's own documents first — everything about *how*
to work in an entry lives in the entry:

| entry | route here when the request is about | read first |
| --- | --- | --- |
| `notes/` | research, surveys, study notes, wiki curation, blog writing or publishing, Obsidian | `.claude/CLAUDE.md` |
| `camera/` | the Android camera app: features, bugs, specs, releases, APK install, emulator tests | `.claude/CLAUDE.md`, then `docs/README.md` |
| `mabinogi-mobile-automation/` | the 마비노기 모바일 game window: park, show, screenshot, start, quit | `.claude/CLAUDE.md` |
| `claude-memory-viewer/` | the memory-observer web app: its views, server, host bridge, ticket flow, container, tailscale exposure | `.claude/CLAUDE.md`, then `docs/INDEX.md` |
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

<!-- rtk-instructions v2 -->
# RTK (Rust Token Killer) - Token-Optimized Commands

## Golden Rule

**Always prefix commands with `rtk`**. If RTK has a dedicated filter, it uses it. If not, it passes through unchanged. This means RTK is always safe to use.

**Important**: Even in command chains with `&&`, use `rtk`:
```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```

## RTK Commands by Workflow

### Build & Compile (80-90% savings)
```bash
rtk cargo build         # Cargo build output
rtk cargo check         # Cargo check output
rtk cargo clippy        # Clippy warnings grouped by file (80%)
rtk tsc                 # TypeScript errors grouped by file/code (83%)
rtk lint                # ESLint/Biome violations grouped (84%)
rtk prettier --check    # Files needing format only (70%)
rtk next build          # Next.js build with route metrics (87%)
```

### Test (60-99% savings)
```bash
rtk cargo test          # Cargo test failures only (90%)
rtk go test             # Go test failures only (90%)
rtk jest                # Jest failures only (99.5%)
rtk vitest              # Vitest failures only (99.5%)
rtk playwright test     # Playwright failures only (94%)
rtk pytest              # Python test failures only (90%)
rtk rake test           # Ruby test failures only (90%)
rtk rspec               # RSpec test failures only (60%)
rtk test <cmd>          # Generic test wrapper - failures only
```

### Git (59-80% savings)
```bash
rtk git status          # Compact status
rtk git log             # Compact log (works with all git flags)
rtk git diff            # Compact diff (80%)
rtk git show            # Compact show (80%)
rtk git add             # Ultra-compact confirmations (59%)
rtk git commit          # Ultra-compact confirmations (59%)
rtk git push            # Ultra-compact confirmations
rtk git pull            # Ultra-compact confirmations
rtk git branch          # Compact branch list
rtk git fetch           # Compact fetch
rtk git stash           # Compact stash
rtk git worktree        # Compact worktree
```

Note: Git passthrough works for ALL subcommands, even those not explicitly listed.

### GitHub (26-87% savings)
```bash
rtk gh pr view <num>    # Compact PR view (87%)
rtk gh pr checks        # Compact PR checks (79%)
rtk gh run list         # Compact workflow runs (82%)
rtk gh issue list       # Compact issue list (80%)
rtk gh api              # Compact API responses (26%)
```

### JavaScript/TypeScript Tooling (70-90% savings)
```bash
rtk pnpm list           # Compact dependency tree (70%)
rtk pnpm outdated       # Compact outdated packages (80%)
rtk pnpm install        # Compact install output (90%)
rtk npm run <script>    # Compact npm script output
rtk npx <cmd>           # Compact npx command output
rtk prisma              # Prisma without ASCII art (88%)
rtk uv run <cmd>        # Compact uv project command output
```

### Files & Search (60-75% savings)
```bash
rtk ls <path>           # Tree format, compact (65%)
rtk read <file>         # Code reading with filtering (60%)
rtk grep <pattern>      # Search grouped by file (75%). Format flags (-c, -l, -L, -o, -Z) run raw.
rtk find <pattern>      # Find grouped by directory (70%)
```

### Analysis & Debug (70-90% savings)
```bash
rtk err <cmd>           # Filter errors only from any command
rtk log <file>          # Deduplicated logs with counts
rtk json <file>         # JSON structure without values
rtk deps                # Dependency overview
rtk env                 # Environment variables compact
rtk summary <cmd>       # Smart summary of command output
rtk diff                # Ultra-compact diffs
```

### Infrastructure (85% savings)
```bash
rtk docker ps           # Compact container list
rtk docker images       # Compact image list
rtk docker logs <c>     # Deduplicated logs
rtk kubectl get         # Compact resource list
rtk kubectl logs        # Deduplicated pod logs
```

### Network (65-70% savings)
```bash
rtk curl <url>          # Compact HTTP responses (70%)
rtk wget <url>          # Compact download output (65%)
```

### Meta Commands
```bash
rtk gain                # View token savings statistics
rtk gain --history      # View command history with savings
rtk discover            # Analyze Claude Code sessions for missed RTK usage
rtk proxy <cmd>         # Run command without filtering (for debugging)
rtk init                # Add RTK instructions to CLAUDE.md
rtk init --global       # Add RTK to ~/.claude/CLAUDE.md
```

## Token Savings Overview

| Category | Commands | Typical Savings |
|----------|----------|-----------------|
| Tests | vitest, playwright, cargo test | 90-99% |
| Build | next, tsc, lint, prettier | 70-87% |
| Git | status, log, diff, add, commit | 59-80% |
| GitHub | gh pr, gh run, gh issue | 26-87% |
| Package Managers | pnpm, npm, npx | 70-90% |
| Files | ls, read, grep, find | 60-75% |
| Infrastructure | docker, kubectl | 85% |
| Network | curl, wget | 65-70% |

Overall average: **60-90% token reduction** on common development operations.
<!-- /rtk-instructions -->
