---
paths: docs/service-*.html
---

# Services plane

The workspace controls two planes. The agents plane is the catalogue plus the
`delegating` skill; the services plane is the long-running things the entries
expose — a web app on a port, a bridge, a tailnet handler. A `docs/service-*`
document governs the second one.

- **One tailnet node per service, never two ports on one node.** A node carries
  exactly one `*.ts.net` name, and a phone matches an installed web app by
  scheme and host while ignoring the port, so services sharing a hostname
  cannot both be installed. `docs/service-tailnet-hostname.html` is the
  procedure.
- **Never `tailscale serve reset`.** It removes every handler on the host,
  other services' included. Turn off one mount by naming its port.
- A service that pins a hostname anywhere in its own configuration — a Host
  allowlist, a published-origin setting — owns that value in its launch path,
  not in a shell one-off. A hand-set value is undone by the next deploy.
- The procedure lives here; what one service currently exposes lives in that
  service's own repository documents. Do not restate a port or a URL in this
  plane's rules.
