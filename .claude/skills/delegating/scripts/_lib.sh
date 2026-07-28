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

# role_of <name> -> the role prefix of a session name
role_of() { printf '%s\n' "${1%%-*}"; }

# role_launch <role> -> "<model> <effort>"
#
# The role decides the model, so the name never has to carry it. The mapping is
# the global sub-agent preference: search, coding and script runs get Opus
# medium; planning and other knowledge work Opus high; a delegate that must
# orchestrate its own sub-agents gets Fable. An unlisted role reads as ordinary
# work and gets the medium default — launch-session prints what it picked, so a
# mistyped role shows up in the launch output instead of in the bill.
role_launch() {
  case $1 in
    plan|curate) printf 'opus high\n' ;;
    drive)       printf 'fable high\n' ;;
    *)           printf 'opus medium\n' ;;
  esac
}

# free_name <requested> -> a herdr-legal agent name no live session holds
#
# Session names read <role>-<task>, so the request must carry both. herdr
# requires [a-z][a-z0-9_-]{0,31} and uniqueness across the server, so the
# request is folded to lower-case kebab, cut to leave room for a "-NN" suffix,
# and disambiguated against the live roster.
free_name() {
  local base name n taken
  base=$(printf '%s' "$1" | tr 'A-Z' 'a-z' |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-29)
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
