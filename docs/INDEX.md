# Index

Every document in `docs/`, as the chapter list. A chapter is a `##`
heading, a `Template:` line, and the documents that belong to it in
reading order. Update in the same commit that adds, renames, or retires a
document. The system's rules: `~/.claude/agents/document-writer.md`; the machine contract: `README.md`.

## Specifications

Template: `~/.claude/agents/document-writer/templates/spec.md`

(none yet — the agent orchestration and service coordination layers are
still documented in `.claude/` files)

## Explanations

Template: `~/.claude/agents/document-writer/templates/explanation.html`

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

## Guides

Template: `~/.claude/agents/document-writer/templates/guide.html`

- [`service-tailnet-hostname.html`](service-tailnet-hostname.html) —
  giving a service its own tailnet node and hostname with a
  `tailscale/tailscale` sidecar: the walked steps, the state-directory
  trap, and the recovery paths.

## Proposals

Template: `~/.claude/agents/document-writer/templates/proposal.html`

- [`agent-document-writing.html`](agent-document-writing.html) — moving the
  document system's rules out of the seven sites that restated them into the
  `document-writer` agent's own definition: the options, why locality decided
  it, and the enforcement and re-render work the shipped move left behind;
  Accepted 2026-08-04.
