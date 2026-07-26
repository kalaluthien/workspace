# Shared helpers for delegating scripts. Source only; not executable.
set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$HOME/workspace}"

die() { printf '%s: %s\n' "$(basename "$0")" "$1" >&2; exit 1; }

require_herdr() {
  [ "${HERDR_ENV:-}" = 1 ] || die 'not inside a herdr pane (HERDR_ENV is unset)'
}

# repo_path <repo-name-or-abs-path> -> absolute repo path
repo_path() {
  case $1 in
    /*) printf '%s\n' "$1" ;;
    *)  printf '%s\n' "$WORKSPACE_ROOT/$1" ;;
  esac
}

# workspace_id_for_label <label> -> workspace id or empty
workspace_id_for_label() {
  herdr workspace list |
    jq -r --arg l "$1" \
      'first(.result.workspaces[] | select(.label == $l) | .workspace_id) // empty'
}

# agent_row <target> -> one agent JSON object (by name, pane id, or terminal id)
agent_row() {
  herdr agent list |
    jq -c --arg t "$1" \
      'first(.result.agents[]
             | select(.name == $t or .pane_id == $t or .terminal_id == $t))
       // empty'
}

# pane_of <target> -> pane id (accepts agent name, pane id, terminal id)
pane_of() {
  local row
  row=$(agent_row "$1")
  if [ -n "$row" ]; then
    printf '%s' "$row" | jq -r '.pane_id'
  else
    case $1 in
      w*:p*) printf '%s\n' "$1" ;;
      *) die "no agent or pane named '$1'" ;;
    esac
  fi
}
