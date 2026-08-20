# Shared helpers for delegating scripts. Source only; not executable.
set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$HOME/workspace}"

die() { printf '%s: %s\n' "$(basename "$0")" "$1" >&2; exit 1; }

require_herdr() {
  [ "${HERDR_ENV:-}" = 1 ] || die 'not inside a herdr pane (HERDR_ENV is unset)'
}

# repo_path <repo-name-or-abs-path> -> absolute repo path
#
# The container root is a repository too, and its label is its own directory
# name, so that one name resolves to the root itself rather than to a
# non-existent entry beneath it. The name is read off $WORKSPACE_ROOT instead
# of hardcoded, so the mapping follows a reconfigured root.
repo_path() {
  case $1 in
    /*) printf '%s\n' "$1" ;;
    "$(basename "$WORKSPACE_ROOT")") printf '%s\n' "$WORKSPACE_ROOT" ;;
    *)  printf '%s\n' "$WORKSPACE_ROOT/$1" ;;
  esac
}

# role_of <name> -> the role prefix of a session name
#
# A board-dispatched worker is named inside its dispatch's namespace,
# work-<project>-<n>--<role>-<task>, so the role is read after the "--"
# boundary rather than off the head of the name — where it would say "work"
# for every worker a board mission launches.
role_of() { local n=${1##*--}; printf '%s\n' "${n%%-*}"; }

# fold_kebab <text> -> lower-case kebab, no leading or trailing dash
fold_kebab() {
  printf '%s' "$1" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

# free_name <requested> -> a herdr-legal agent name no live session holds
#
# Session names read <role>-<task>, so the request must carry both. herdr
# requires [a-z][a-z0-9_-]{0,31} and uniqueness across the server, so the
# request is folded to lower-case kebab, cut to leave room for a "-NN" suffix,
# and disambiguated against the live roster.
#
# A board-dispatched worker carries its dispatch's namespace in front,
# work-<project>-<n>--<role>-<task>. Each side of that "--" folds on its own,
# because the fold collapses every run of separators to a single dash and
# would otherwise eat the boundary — which is what tells the board which
# ticket owns the pane. The cut lands on the joined name, so the namespace
# spends from the same budget and the task part is what loses letters.
free_name() {
  local want=$1 prefix= base name n taken
  case $want in
    *--*) prefix="$(fold_kebab "${want%%--*}")--"; want=${want#*--} ;;
  esac
  base=$(printf '%s%s' "$prefix" "$(fold_kebab "$want")" |
    cut -c1-29 | sed -E 's/(.)-+$/\1/')
  case $base in
    [a-z]*-?*) ;;
    *) die "a session name must read <role>-<task> and start with a letter: '$1'" ;;
  esac
  taken=$(herdr agent list | jq -r '.result.agents[].name // empty')
  name=$base; n=2
  while printf '%s\n' "$taken" | grep -qx "$name"; do
    name="$base-$n"; n=$((n + 1))
  done
  printf '%s\n' "$name"
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

# shell_verdict <pane> -> shell | shell-busy
#
# Whether a pane holding no session is safe to retire. A shell that sits at its
# prompt is its own foreground process group; anything it launched takes that
# group over, so the two ids differ for exactly as long as the command runs.
# Idle is claimed only when both ids are present and equal, so a pane that
# cannot be read reports busy and survives the sweep.
shell_verdict() {
  herdr pane process-info --pane "$1" |
    jq -r '.result.process_info
           | if (.shell_pid != null and .foreground_process_group_id != null
                 and .shell_pid == .foreground_process_group_id)
             then "shell" else "shell-busy" end' 2>/dev/null || printf 'shell-busy\n'
}

# session_verdict <pane> <name> <status> -> the pane's verdict, one word
#
# Whether a session is free to claim or retire. herdr's status alone cannot
# say: a pane reads idle whenever the session pauses mid-turn, so a claim
# made on status clears work still running.
#
# The judgement lives in one place, session_state.py in the clean skill, and
# both skills call it -- reuse and retirement ask the same question of the
# same evidence, and two classifiers that disagree hand a live pane to a new
# task. It reads the session's own transcript, found through the session id
# herdr holds for the pane, so nothing here depends on what the screen
# happens to be showing.
#
# A verdict this cannot establish comes back `unlinked`, which is free for
# neither claiming nor closing -- the safe answer when the evidence is
# missing rather than negative.
CLASSIFIER=${CLASSIFIER:-$(dirname "${BASH_SOURCE[0]}")/../../clean/scripts/session_state.py}

session_verdict() {
  /usr/bin/python3 "$CLASSIFIER" verdict --pane "$1" 2>/dev/null || printf 'unknown\n'
}
