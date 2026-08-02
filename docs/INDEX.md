# Index

Every document in `docs/`, as the chapter list. A chapter is a `##` heading,
a `Template:` line, and the documents that belong to it in reading order.
Update in the same commit that adds, renames, or retires a document.
Catalogue of the system: `README.md`.

## Principles

Template: `templates/principle.html`

(none yet — the template's own example records the views-only decision)

## Patterns

Template: `templates/pattern.html`

- [`agent-config-scopes.html`](agent-config-scopes.html) — the shape of the
  three Claude configuration scopes (global, workspace, project entry): one
  matrix over CLAUDE.md, rules, skills, agents, and memory pools, with the
  location of every routing rule, responsibility declaration, and file-format
  definition; appendixes hold the survey evidence, the migration record, and
  a connectivity check over the document templates.

## Practices

Template: `templates/practice.html`
- [`service-tailnet-hostname.html`](service-tailnet-hostname.html) — giving a
  service its own tailnet node and hostname with a `tailscale/tailscale`
  sidecar, so several services stay installable as phone apps at once; the
  state-directory trap, the host-allowlist move, and retiring the old mount.
