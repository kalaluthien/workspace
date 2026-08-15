# Index

Every document in `docs/`, as the chapter list. A chapter is a `##`
heading and the documents that belong to it in reading order; the
Specifications chapter also carries a `Template:` line. Update in the
same commit that adds, renames, or retires a document. The system's
rules: the `writing` skill (`~/workspace/.claude/skills/writing/SKILL.md`);
the machine contract: `README.md`.

## Specifications

Template: `templates/spec.md`

- [`agent-document-system.md`](agent-document-system.md) — which file holds
  the document system's rules, the two arrangements that lost and why, and
  what the choice still owes.

## Explanations

- [`agent-config-scopes.html`](agent-config-scopes.html) — where each kind
  of Claude configuration (instruction, rule, skill, agent, memory) lives
  across the global, workspace, and project scopes, and what routes it
  there.
- [`agent-memtypes.html`](agent-memtypes.html) — the memory-file kinds
  read from one question — what would make this file wrong — and the
  three lifecycle classes and five filename prefixes that answer admits.
- [`agent-hooks.html`](agent-hooks.html) — the hooks that fire around a
  working session, split by the layer that owns them: four Claude Code
  hooks in one settings file, and the git guard every repository runs.
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

- [`agent-backlog-writing.html`](agent-backlog-writing.html) — what rule
  should structure a backlog row's text, and where that rule and its guard
  should live: three structuring options, three homes, and the reach
  argument that picks one of each; Accepted 2026-08-12.
- [`agent-development-cycle.html`](agent-development-cycle.html) — what
  directory contract and work cycle agent sessions should follow in a
  program-building project entry: one checked chain from use case to
  settling test, four entrypoints, models as red-twice-proven evidence,
  and a recovery path for code-first patches; garden is the testbed;
  Proposed 2026-08-15.
