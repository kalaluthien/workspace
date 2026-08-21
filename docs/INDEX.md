# Index

Every document in `docs/`, as the chapter list. A chapter is a `##`
heading and the documents that belong to it in reading order. Update in the
same commit that adds, renames, or retires a document. The system's
rules: the `writing` skill (`~/workspace/.claude/skills/writing/SKILL.md`);
the machine contract: `README.md`.

Specifications are not documents and are not listed here. They live in
`~/workspace/spec/`, which carries its own rules in `spec/README.md`.

## Explanations

- [`agent-config-scopes.html`](agent-config-scopes.html) — where each kind
  of Claude configuration (instruction, rule, skill, agent, memory) lives
  across the global, workspace, and project scopes, and what routes it
  there.
- [`agent-memtypes.html`](agent-memtypes.html) — the memory-file kinds
  read from one question — which kind does a new fact take — and the
  three lifecycle classes and six filename prefixes the live table
  admits, with the guard that refuses the rest.
- [`agent-hooks.html`](agent-hooks.html) — the hooks that fire around a
  working session, split by the layer that owns them: four Claude Code
  hooks in one settings file, and the git guard every repository runs.
- [`agent-orchestration-model.html`](agent-orchestration-model.html) — how
  the workspace's orchestration layer and board's ticket store talk: the
  three one-way channels between them, the six ticket doors, the launch that
  spawns a session, the pane name that joins a row to a pane, seven meeting
  scenarios, and the two repair loops.
- [`agent-writing.html`](agent-writing.html) — how the `writing` skill
  turns a five-field brief into one delivered view: the fork contract,
  the run steps from doctype to open, and the render check that can
  fail.

## Guides

- [`service-tailnet-hostname.html`](service-tailnet-hostname.html) —
  giving a service its own tailnet node and hostname with a
  `tailscale/tailscale` sidecar: the walked steps, the state-directory
  trap, and the recovery paths.

## Proposals

- [`agent-development-cycle.html`](agent-development-cycle.html) — what
  directory contract and work cycle agent sessions should follow in a
  program-building project entry: one checked chain from a spec's domain
  and behaviour halves down to a settling test, four entrypoints, an
  eval stage over code and models, and a recovery path for code-first
  patches; garden is the testbed; Open.
- [`agent-session-cleanup.html`](agent-session-cleanup.html) — where the
  cleanup of a delegated session's claims belongs: the measured firing gap
  between the turn-end and session-end events, the one leak that is real,
  three options with the destructor killed, and the owner's three yes-or-no
  decisions; Open.
