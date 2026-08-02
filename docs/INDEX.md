# Index

Every document in `docs/`, as the chapter list. A chapter is a `##` heading,
a `Template:` line, and the documents that belong to it in reading order.
Update in the same commit that adds, renames, or retires a document.
Conventions: `README.md`.

## How-to guides

Template: `templates/how-to-guide.html`

- [`agent-config-scopes.html`](agent-config-scopes.html) — surveying the three
  Claude configuration scopes (global, workspace, project entry) into one
  matrix over CLAUDE.md, rules, skills, agents, and memory pools, with the
  location of every routing rule, responsibility declaration, and file-format
  definition.
- [`service-tailnet-hostname.html`](service-tailnet-hostname.html) — giving a
  service its own tailnet node and hostname with a `tailscale/tailscale`
  sidecar, so several services stay installable as phone apps at once; the
  state-directory trap, the host-allowlist move, and retiring the old mount.

## Proposals

Template: `templates/proposal.html`

(none yet)
