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
# A board-dispatched worker is named inside its ticket's namespace,
# ticket-<id>--<role>-<task>, so the role is read after the "--" boundary
# rather than off the head of the name — where it would say "ticket" for
# every worker a board mission launches.
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
# A board-dispatched worker carries its ticket's namespace in front,
# ticket-<id>--<role>-<task>. Each side of that "--" folds on its own, because
# the fold collapses every run of separators to a single dash and would
# otherwise eat the boundary — which is what tells the board which ticket owns
# the pane. The cut lands on the joined name, so the namespace spends from the
# same budget and the task part is what loses letters.
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

# session_verdict <pane> <name> <status> -> empty | done | pending | unknown | <status>
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
#
# A usage-limit stop reads as blocked, and it outranks an earlier sentinel:
# a /goal session can print its sentinel, have the judge send it back to
# work, and then hit the limit — a screen whose last event is the limit
# message is a session waiting on the clock, whatever it printed before.
# The limit line counts only when nothing came after it: a later prompt or
# a later assistant bullet means the session already resumed.
session_verdict() {
  case $3 in
    idle|done) ;;
    *) printf '%s\n' "$3"; return ;;
  esac
  local v
  v=$(herdr pane read "$1" --source recent-unwrapped --lines "${SESSION_READ_LINES:-200}" |
    awk -v name="$2" '
      BEGIN { sentinel = (name == "" ? "" : "DONE " name) }
      { seen = NR }
      index($0, "\342\217\272") { output_at = NR }               # the assistant bullet
      index($0, "\342\226\220\342\226\233") { banner = 1 }       # the welcome banner
      index($0, "hit your session limit") { limit_at = NR }      # the usage-limit stop
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
        else if (limit_at > done_at && limit_at > input_at \
                 && limit_at > output_at)           print "blocked"
        else if (done_at > 0 && done_at > input_at) print "done"
        else if (output_at || input_at)             print "pending"
        else if (banner)                            print "empty"
        else                                        print "unknown"
      }')
  if [ "$v" = unknown ] && [ -n "$2" ]; then
    if transcript_says_done "$1" "$2"; then v=done; fi
  fi
  printf '%s\n' "$v"
}

# transcript_says_done <pane> <name> -> exit 0 when the delegate's transcript
# holds "DONE <name>" as assistant output after the last user message.
#
# The screen is a lossy record, but the session's jsonl transcript under
# ~/.claude/projects/<encoded-cwd>/ is durable: a sentinel that repainted
# away still sits there as an assistant row. Consulted only when the screen
# scores unknown. The scoping matters twice over: only the pane's own cwd
# directory is searched, because the orchestrator's transcript quotes the
# sentinel inside the prompt it sent, and only assistant rows count, because
# the delegate's own transcript quotes it in the user row that delivered the
# prompt. The last-prompt comparison mirrors the screen rule
# done_at > input_at: a prompt sent after the sentinel reopened the session,
# so the old sentinel no longer answers for it. A user row is a prompt only
# when it is real work: tool results, hook injections (isMeta), and command
# echoes (<command-name>, <local-command-stdout>) do not reopen a session —
# a delegate's Stop hook routinely appends a filing round after the
# sentinel, and counting its feedback as a prompt would deny every verdict.
transcript_says_done() {
  local cwd dir f
  cwd=$(herdr agent list |
    jq -r --arg p "$1" \
      'first(.result.agents[] | select(.pane_id == $p) | .cwd) // empty')
  [ -n "$cwd" ] || return 1
  dir="$HOME/.claude/projects/$(printf '%s' "$cwd" | sed 's,[/.],-,g')"
  [ -d "$dir" ] || return 1
  for f in "$dir"/*.jsonl; do
    [ -e "$f" ] || break
    grep -q "DONE $2" "$f" 2>/dev/null || continue
    if jq -r --arg s "DONE $2" '
         def usertext:
           if (.message.content | type) == "string" then .message.content
           else ([.message.content[]? | select(.type? == "text") | .text]
                 | join(" "))
           end;
         select(.type == "user" or .type == "assistant")
         | if .type == "assistant"
           then "assistant\t\(
             [.message.content[]? | .text? // empty] | join(" ")
             | contains($s))"
           else "user\t\(
             (.isMeta != true)
             and (usertext | length > 0)
             and ((usertext
                   | startswith("<command-name>")
                     or startswith("<local-command-stdout>")) | not))"
           end
       ' "$f" 2>/dev/null |
       awk -F'\t' '
         $1 == "user" && $2 == "true"      { u = NR }
         $1 == "assistant" && $2 == "true" { d = NR }
         END { exit !(d && d > u) }'
    then return 0; fi
  done
  return 1
}
