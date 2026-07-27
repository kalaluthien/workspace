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

# session_verdict <pane> <name> <status> -> empty | done | pending | <status>
#
# Whether a session is free to claim or retire. Status alone cannot say:
# herdr reports a quiet pane as idle, and a pane goes quiet whenever the
# session pauses mid-turn, so only working, blocked and unknown are trusted
# as-is and reported unread. The rest is read off the screen by three markers.
# The assistant bullet says the session produced output, a prompt line
# carrying anything but a slash command says it was given work, and the
# welcome banner says the session is fresh or freshly cleared.
#
# Every verdict rests on a marker that is present, never on one that is
# absent, because the screen is a lossy record: a pane repaints as it runs
# and the transcript above the fold is gone from the emulator, not merely
# unread. So empty means the banner is showing with nothing after it, and a
# screen holding none of the three markers is unknown — the session may have
# finished hours ago with its sentinel long scrolled away. The DONE sentinel
# counts only when no later prompt line reopened the session, and an unnamed
# session carries no sentinel to match. Splitting on a marker avoids assuming
# its byte width, and a read that comes back with nothing is a failed read.
session_verdict() {
  case $3 in
    idle|done) ;;
    *) printf '%s\n' "$3"; return ;;
  esac
  herdr pane read "$1" --source recent-unwrapped --lines "${SESSION_READ_LINES:-200}" |
    awk -v name="$2" '
      BEGIN { sentinel = (name == "" ? "" : "DONE " name) }
      { seen = NR }
      index($0, "\342\217\272") { output = 1 }                   # the assistant bullet
      index($0, "\342\226\220\342\226\233") { banner = 1 }       # the welcome banner
      sentinel != "" && index($0, sentinel) { done_at = NR }
      {
        if (index($0, "\342\235\257")) {                         # the prompt marker
          n = split($0, part, "\342\235\257")
          rest = part[n]; gsub(/[[:space:]]/, "", rest)
          if (rest != "" && substr(rest, 1, 1) != "/") input_at = NR
        }
      }
      END {
        if (!seen)                                  print "unknown"
        else if (done_at > 0 && done_at > input_at) print "done"
        else if (output || input_at)                print "pending"
        else if (banner)                            print "empty"
        else                                        print "unknown"
      }'
}
