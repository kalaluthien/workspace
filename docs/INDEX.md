# Index

Every document in `docs/`, as the chapter list. A chapter is a `##`
heading, a `Template:` line, and the documents that belong to it in
reading order. Update in the same commit that adds, renames, or retires a
document. Catalogue of the system: `README.md`.

## Specifications

Template: `templates/spec.md`

(none yet — the agent orchestration and service coordination layers are
still documented in `.claude/` files)

## Explanations

Template: `templates/explanation.html`

- [`agent-config-scopes.html`](agent-config-scopes.html) — where each kind
  of Claude configuration (instruction, rule, skill, agent, memory) lives
  across the global, workspace, and project scopes, and what routes it
  there.

## Guides

Template: `templates/guide.html`

- [`service-tailnet-hostname.html`](service-tailnet-hostname.html) —
  giving a service its own tailnet node and hostname with a
  `tailscale/tailscale` sidecar: the walked steps, the state-directory
  trap, and the recovery paths.

## Proposals

Template: `templates/proposal.html`

- [`agent-document-writing.html`](agent-document-writing.html) — move the
  document system's rules out of the six files that restate them and into
  the `document-writer` agent's own definition, with a shared contract
  checker and a four-phase migration of all 45 documents; Open.
