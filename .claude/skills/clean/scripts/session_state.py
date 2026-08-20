#!/usr/bin/python3
"""Classify and retire herdr panes from typed evidence, never from the screen.

The old classifier had one proof of completion: the literal line
"DONE <agent-name>" rendered in the pane. A pane whose agent carries no name
-- every session started by hand or from the phone -- had no such line to
match and could never be classified closable, whatever it had finished.

Here a pane names its own session (the `herdr-session-link` hook writes
`agent_session` over herdr's socket), the session names its own transcript,
and every verdict is read off typed fields: herdr's pane record and the
transcript's row types. The only literals are contract keys -- herdr's
schema field names and Claude Code's JSONL row types -- which change with a
version bump, not with a redraw.

Safety is asymmetric by construction. Absent, ambiguous or stale evidence
produces a hold, never a close; the failure mode is a pane that outlives its
work, never work that dies with its pane.

    session_state.py list  [--repo R] [--all] [--quiet-min N]
    session_state.py close [--repo R] [--all] [--quiet-min N] [--pane P ...]
    session_state.py verdict --pane P

`list` prints one JSON object per pane. `close` retires the closable ones
after re-reading each pane, and prints what it did.
"""
import argparse
import glob
import json
import os
import re
import socket
import subprocess
import sys
import time
from datetime import datetime, timezone

WORKSPACE_ROOT = os.path.expanduser("~/workspace")
PROJECTS = os.path.expanduser("~/.claude/projects")
DEFAULT_QUIET_MIN = 30

# A pane is closable only from these two herdr states. Every other state --
# working, blocked, unknown -- is live work, a dialog, or no evidence at all.
IDLE_STATUSES = ("done", "idle")


# --------------------------------------------------------------- herdr socket

class Herdr:
    """herdr's unix socket. Every call returns parsed JSON or raises."""

    def __init__(self):
        self.path = os.environ.get("HERDR_SOCKET_PATH")
        if not self.path:
            sys.exit("HERDR_SOCKET_PATH is unset: no herdr server to read.")

    def rpc(self, method, params=None):
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(5.0)
            s.connect(self.path)
            s.sendall((json.dumps({
                "id": "session-state:%d" % os.getpid(),
                "method": method,
                "params": params or {},
            }) + "\n").encode())
            buf = b""
            while not buf.endswith(b"\n"):
                chunk = s.recv(65536)
                if not chunk:
                    break
                buf += chunk
        reply = json.loads(buf.decode() or "{}")
        if "error" in reply:
            raise RuntimeError(reply["error"])
        return reply.get("result") or {}

    def roster(self):
        """Every pane, with its agent row merged in and focus resolved.

        The snapshot publishes panes and agents as two arrays: the pane row
        carries cwd, revision and the display label, the agent row carries
        the delegation name. Reuse decisions key on the name, so the join is
        not optional.
        """
        snap = self.rpc("session.snapshot").get("snapshot") or {}
        agents = {a["pane_id"]: a for a in snap.get("agents") or []}
        focused = snap.get("focused_pane_id")
        rows = []
        for pane in snap.get("panes") or []:
            row = dict(pane)
            row["name"] = (agents.get(pane["pane_id"]) or {}).get("name")
            row["is_focused"] = pane["pane_id"] == focused
            rows.append(row)
        return rows

    def pane(self, pane_id):
        """The pane record, or {} when herdr no longer has that pane.

        A closed pane answers `pane_not_found`, which is the success case
        for the read that confirms a close -- so absence is returned, not
        raised.
        """
        try:
            return (self.rpc("pane.get", {"pane_id": pane_id}).get("pane") or {})
        except RuntimeError:
            return {}

    def process_info(self, pane_id):
        return (self.rpc("pane.process_info", {"pane_id": pane_id})
                .get("process_info") or {})

    def close_pane(self, pane_id):
        self.rpc("pane.close", {"pane_id": pane_id})

    def working_rules(self, pane_id):
        """Detection rules that matched `working` but lost on priority.

        herdr reports one winning state; a background shell or a live
        subagent can match a working rule and still be outranked. Those
        holds are exactly the ones a quiet screen hides, so read them all.
        """
        try:
            out = self.rpc("agent.explain", {"pane_id": pane_id})
        except Exception:
            return []
        return [r.get("id") for r in out.get("evaluated_rules") or []
                if r.get("matched") and r.get("state") == "working"]


# ----------------------------------------------------------------- transcript

def transcript_for(session_id):
    """The one transcript file for a session id, or None if not exactly one.

    The uuid is the filename stem, so the match is exact by construction.
    The directory encodes the session's *startup* cwd, which a session can
    leave, so glob across projects rather than deriving the directory.
    """
    hits = glob.glob(os.path.join(PROJECTS, "*", "%s.jsonl" % session_id))
    return hits[0] if len(hits) == 1 else None


def read_rows(path):
    rows = []
    with open(path, "r", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except ValueError:
                continue
    return rows


def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def assistant_text(row):
    content = (row.get("message") or {}).get("content")
    if isinstance(content, str):
        return content
    return " ".join(part.get("text", "") for part in content or []
                    if isinstance(part, dict) and part.get("type") == "text")


ENDS_IN_QUESTION = re.compile(r"[?？]\s*$")


class TranscriptState:
    """What a session's own record says about whether it owes anything.

    Every field is derived from row types and tool-call bookkeeping. The one
    judgement made on prose is `asks_question`, and it can only ever add a
    hold -- language is not evidence enough to close on, but it is evidence
    enough to keep a pane alive.
    """

    def __init__(self, rows):
        self.rows = rows
        self.last_ts = None
        self.open_tools = {}          # tool_use id -> tool name, unanswered
        self.turn_closed = False      # last event is a completed turn
        self.has_prompt = False
        self.asks_question = False
        self.cwds = set()             # every directory the session worked in
        self._scan()

    def _scan(self):
        last_assistant = None
        for row in self.rows:
            kind = row.get("type")
            ts = parse_ts(row.get("timestamp"))
            if ts and (self.last_ts is None or ts > self.last_ts):
                self.last_ts = ts
            if row.get("cwd"):
                self.cwds.add(row["cwd"])

            if kind == "assistant":
                content = (row.get("message") or {}).get("content") or []
                for part in content if isinstance(content, list) else []:
                    if isinstance(part, dict) and part.get("type") == "tool_use":
                        self.open_tools[part.get("id")] = part.get("name")
                if assistant_text(row).strip():
                    last_assistant = row
                self.turn_closed = False

            elif kind == "user":
                content = (row.get("message") or {}).get("content") or []
                answered = False
                for part in content if isinstance(content, list) else []:
                    if isinstance(part, dict) and part.get("type") == "tool_result":
                        self.open_tools.pop(part.get("tool_use_id"), None)
                        answered = True
                if not answered and not row.get("isMeta"):
                    self.has_prompt = True
                    self.turn_closed = False

            elif kind == "system" and row.get("subtype") == "turn_duration":
                # The harness stamps this when a turn completes. It is the
                # one positive assertion in the record that nothing is
                # mid-flight -- the structural replacement for the sentinel.
                self.turn_closed = True

        if last_assistant is not None:
            self.asks_question = bool(
                ENDS_IN_QUESTION.search(assistant_text(last_assistant).strip()))

    @property
    def is_empty(self):
        return not self.has_prompt

    def quiet_minutes(self, now=None):
        if self.last_ts is None:
            return None
        now = now or datetime.now(timezone.utc)
        return (now - self.last_ts).total_seconds() / 60.0


# --------------------------------------------------------------------- backfill

def pane_claude_pid(herdr, pane_id):
    for proc in herdr.process_info(pane_id).get("foreground_processes") or []:
        if (proc.get("argv") or [""])[0] == "claude":
            return proc.get("pid")
    return None


def session_from_argv(herdr, pane_id):
    """The session id a launcher passed on the command line, if any.

    Authoritative and free: `claude --session-id <uuid>` names the session
    the process is running, with none of a heuristic's ambiguity.
    """
    for proc in herdr.process_info(pane_id).get("foreground_processes") or []:
        argv = proc.get("argv") or []
        if argv and argv[0] == "claude" and "--session-id" in argv:
            index = argv.index("--session-id")
            if index + 1 < len(argv):
                return argv[index + 1]
    return None


def title_index():
    """Map each session's latest self-assigned title to its session ids.

    Claude Code writes an `ai-title` row naming the session; herdr shows the
    same string as the terminal title. That shared value links a pane that
    predates the linking hook to its own transcript.

    A session titles itself twice over: `ai-title` rows carry the generated
    title, `custom-title` rows the one a person typed with /rename. Both are
    read, last one wins, because the pane shows whichever came last -- index
    only the generated one and a renamed session becomes unfindable.

    One title routinely names several files: `/clear` and `/resume` fork a
    new session id mid-process and the new session keeps the old title. So
    this maps to a list, and the caller judges every candidate rather than
    picking one -- a title with two files is normal, not a defect.
    """
    titles = {}
    for path in glob.glob(os.path.join(PROJECTS, "*", "*.jsonl")):
        title = None
        try:
            with open(path, "r", errors="replace") as fh:
                for line in fh:
                    if '"ai-title"' not in line and '"custom-title"' not in line:
                        continue
                    try:
                        row = json.loads(line)
                    except ValueError:
                        continue
                    named = row.get("aiTitle") if row.get("type") == "ai-title" \
                        else row.get("customTitle") if row.get("type") == "custom-title" \
                        else None
                    if named:
                        title = named
        except OSError:
            continue
        if title:
            titles.setdefault(title.strip(), []).append(
                os.path.basename(path)[:-len(".jsonl")])
    return titles


def backfill_sessions(herdr, pane, titles, claimed, pid):
    """Every session a pane the hook never stamped could be running.

    Two filters, both structural: the transcript must have been written
    while this pane's claude process was alive, and it must not already be
    claimed by another pane. What survives is judged as a set -- a pane is
    finished only if every candidate is, so an ambiguous title can hold the
    pane but never close one that is still owed something.
    """
    title = (pane.get("terminal_title_stripped") or "").strip()
    if not title:
        return []
    started = process_start_epoch(pid) if pid else None
    found = []
    for session_id in titles.get(title, []):
        if session_id in claimed:
            continue
        path = transcript_for(session_id)
        if not path:
            continue
        if started and os.path.getmtime(path) < started:
            continue                    # written before this process existed
        found.append(session_id)
    return found


def process_start_epoch(pid):
    try:
        out = subprocess.run(["ps", "-p", str(pid), "-o", "lstart="],
                             capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.SubprocessError):
        return None
    stamp = out.stdout.strip()
    if not stamp:
        return None
    try:
        return time.mktime(time.strptime(stamp))
    except ValueError:
        return None


# -------------------------------------------------------------------- git gate

_REPO_CACHE = {}


def unclean_repos(paths):
    """The repositories among `paths` holding work that a close would strand.

    A pane's own directory is the wrong place to ask. Every agent pane here
    starts at the container root, which is a whitelist repository ignoring
    every entry -- so a root pane reads clean while its actual edits sit
    uncommitted in a project worktree. The session's transcript records the
    directory of each turn, so it names the repositories the session really
    touched, worktrees included.
    """
    unclean = set()
    for path in sorted(paths):
        if not path or not os.path.isdir(path):
            continue

        def git(*args):
            return subprocess.run(["git", "-C", path] + list(args),
                                  capture_output=True, text=True, timeout=15)
        try:
            top = git("rev-parse", "--show-toplevel").stdout.strip()
            if not top:
                continue
            if top in _REPO_CACHE:
                if _REPO_CACHE[top]:
                    unclean.add(top)
                continue
            dirty = bool(git("status", "--porcelain").stdout.strip())
            unpushed = bool(git("log", "--oneline", "@{u}..HEAD").stdout.strip())
            state = dirty or unpushed
        except (OSError, subprocess.SubprocessError):
            unclean.add(path)           # cannot tell: hold
            continue
        _REPO_CACHE[top] = state
        if state:
            unclean.add(top)
    return sorted(unclean)


# ------------------------------------------------------------------ classifier

def repo_label(pane):
    """The workspace entry a pane belongs to, by its startup directory."""
    cwd = pane.get("cwd") or ""
    if cwd == WORKSPACE_ROOT:
        return os.path.basename(WORKSPACE_ROOT)
    prefix = WORKSPACE_ROOT + os.sep
    if cwd.startswith(prefix):
        return cwd[len(prefix):].split(os.sep)[0]
    return None


def classify(herdr, pane, roster, titles, quiet_min, me, explicit=False):
    """One pane's verdict and every reason it is being held.

    `holds` is the whole safety argument: a pane closes only when the list
    is empty, so any evidence that cannot be read lands here as a reason
    rather than being resolved by a guess.

    `explicit` marks a pane the caller named by id rather than one a sweep
    happened across. It drops only the focus hold, which exists to keep a
    broad sweep away from the pane the owner is looking at -- naming that
    pane is the owner saying so.
    """
    pane_id = pane["pane_id"]
    out = {
        "pane": pane_id,
        "repo": repo_label(pane),
        "name": pane.get("name"),
        "title": pane.get("terminal_title_stripped"),
        "status": pane.get("agent_status"),
        "session": None,
        "link": None,
        "quiet_min": None,
        "holds": [],
        "verdict": None,
        "revision": pane.get("revision"),
    }
    hold = out["holds"].append

    if not pane.get("agent"):
        info = herdr.process_info(pane_id)
        busy = info.get("foreground_process_group_id") != info.get("shell_pid")
        out["verdict"] = "shell-busy" if busy else "shell"
        if busy:
            hold("shell-busy")
        return out

    if pane_id == me:
        hold("self")
    if pane.get("is_focused") and not explicit:
        hold("focused")

    status = pane.get("agent_status")
    if status not in IDLE_STATUSES:
        hold("status:%s" % status)
    for rule in herdr.working_rules(pane_id):
        hold("rule:%s" % rule)

    # A worker pane is named <parent>--<suffix>; a parent owes its report
    # until every such worker is done, and that debt leaves no trace in the
    # parent's own transcript.
    name = pane.get("name")
    if name:
        for other in roster:
            other_name = other.get("name") or ""
            if (other_name.startswith(name + "--")
                    and other.get("agent_status") not in IDLE_STATUSES):
                hold("worker:%s" % other_name)

    # Three ways a pane names its session, all gathered rather than ranked.
    # herdr's stamp is write-once per pane, so a `/clear` -- which forks a new
    # session id inside the same process -- leaves the stamp pointing at the
    # transcript it abandoned. Collecting every candidate and taking the most
    # recently active one below covers that without preferring a guess over a
    # record: each source contributes, none is trusted alone.
    pid = pane_claude_pid(herdr, pane_id)
    sessions, sources = [], []
    stamped = pane.get("agent_session") or {}
    if stamped.get("kind") == "id" and stamped.get("value"):
        sessions.append(stamped["value"])
        sources.append("hook")
    from_argv = session_from_argv(herdr, pane_id)
    if from_argv and from_argv not in sessions:
        sessions.append(from_argv)
        sources.append("argv")
    claimed = {(p.get("agent_session") or {}).get("value")
               for p in roster if p["pane_id"] != pane_id}
    by_title = [s for s in backfill_sessions(herdr, pane, titles, claimed, pid)
                if s not in sessions]
    if by_title:
        sessions.extend(by_title)
        sources.append("title")
    out["link"] = "+".join(sources) or None

    paths = [p for p in (transcript_for(s) for s in sessions) if p]
    if not paths:
        # A transcript is created on the first prompt, so an authoritative id
        # with no file behind it is a pane nobody has asked anything yet --
        # the one case where missing evidence is itself the evidence. A id
        # guessed from a title earns no such reading.
        if sources and sources[0] in ("hook", "argv"):
            out["session"] = sessions[0]
            out["verdict"] = "empty"
            return out
        hold("unlinked")
        out["verdict"] = "unlinked"
        return out

    # A link is only as good as its freshness: a pane recycled for a new
    # session keeps the old id until the hook fires again.
    started = process_start_epoch(pid) if pid else None
    if started and all(os.path.getmtime(p) < started for p in paths):
        hold("stale-link")
        out["verdict"] = "unlinked"
        return out

    # `/clear` and `/resume` fork a new transcript and abandon the old one,
    # so among candidates the pane is running the most recently active. An
    # abandoned fork is dead evidence; reading it would hold every pane that
    # ever cleared its context. Picking the newest also fails safe: a stub
    # left mid-turn holds the pane, it never releases one.
    scanned = sorted(((p, TranscriptState(read_rows(p))) for p in paths),
                     key=lambda pair: pair[1].last_ts or datetime.min.replace(
                         tzinfo=timezone.utc))
    path, state = scanned[-1]
    out["session"] = os.path.basename(path)[:-len(".jsonl")]
    out["superseded"] = len(scanned) - 1
    out["quiet_min"] = (None if state.quiet_minutes() is None
                        else round(state.quiet_minutes(), 1))

    if state.is_empty:
        out["verdict"] = "empty"
    else:
        awaiting = sorted({name or "?" for name in state.open_tools.values()})
        if awaiting:
            hold("awaiting:%s" % ",".join(awaiting))
        if not state.turn_closed:
            hold("mid-turn")
        if state.asks_question:
            hold("asks-question")
        out["verdict"] = "done"
    del scanned

    if out["quiet_min"] is not None and out["quiet_min"] < quiet_min:
        hold("fresh:%.0fm" % out["quiet_min"])
    touched = set(state.cwds)
    touched.add(pane.get("foreground_cwd"))
    touched.add(pane.get("cwd"))
    for repo in unclean_repos(touched):
        hold("unclean:%s" % os.path.basename(repo))

    return out


def closable(row):
    return row["verdict"] in ("empty", "done") and not row["holds"]


# ------------------------------------------------------------------------ main

def gather(herdr, args, me, titles=None):
    roster = herdr.roster()
    titles = title_index() if titles is None else titles
    rows = []
    for pane in roster:
        label = repo_label(pane)
        if label is None:
            continue
        if args.repo and label != args.repo:
            continue
        if not args.repo and not args.all \
                and label == os.path.basename(WORKSPACE_ROOT):
            # Container-root panes are the orchestrators; reaching them is an
            # explicit request, not a side effect of sweeping the entries.
            continue
        if args.pane and pane["pane_id"] not in args.pane:
            continue
        rows.append(classify(herdr, pane, roster, titles, args.quiet_min, me,
                             explicit=bool(args.pane)))
    return rows


def do_close(herdr, args, me):
    # One title index for the sweep and every re-read: rebuilding it is a
    # scan of every transcript, and an empty one silently unlinks each pane
    # it is asked about -- a refusal that reads like a hold.
    titles = title_index()
    rows = gather(herdr, args, me, titles)
    results = []
    for row in rows:
        if not closable(row):
            row["closed"] = False
            results.append(row)
            continue
        # Re-read immediately before closing: a pane that woke between the
        # sweep and now must survive, and only a fresh classification can
        # say so.
        fresh = herdr.pane(row["pane"])
        if not fresh:
            row["closed"] = False
            row["holds"].append("vanished")
            results.append(row)
            continue
        fresh["name"] = row["name"]
        fresh["is_focused"] = False
        recheck = classify(herdr, fresh, herdr.roster(), titles,
                           args.quiet_min, me, explicit=bool(args.pane))
        if not closable(recheck):
            # It woke up, or grew a hold, between the sweep and now. The
            # re-classification is the guard, not the pane revision: that
            # counter moves on any repaint, so an idle pane bumps it while
            # nothing about the session changed.
            recheck["closed"] = False
            recheck["holds"].append("raced")
            results.append(recheck)
            continue
        herdr.close_pane(row["pane"])
        row["closed"] = not herdr.pane(row["pane"])
        results.append(row)
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("list", "close", "verdict"))
    parser.add_argument("--repo")
    parser.add_argument("--all", action="store_true",
                        help="include container-root panes")
    parser.add_argument("--pane", action="append", default=[])
    parser.add_argument("--quiet-min", type=float, default=DEFAULT_QUIET_MIN)
    args = parser.parse_args()

    herdr = Herdr()
    me = os.environ.get("HERDR_PANE_ID")

    if args.command == "verdict":
        if not args.pane:
            sys.exit("verdict needs --pane")
        roster = herdr.roster()
        pane = next((p for p in roster if p["pane_id"] == args.pane[0]), None)
        if pane is None:
            sys.exit("no such pane: %s" % args.pane[0])
        print(classify(herdr, pane, roster, title_index(),
                       args.quiet_min, me)["verdict"])
        return

    if args.command == "close" and not me:
        sys.exit("refusing to close from outside a herdr pane: "
                 "HERDR_PANE_ID is unset, so nothing excludes the caller.")

    rows = (do_close(herdr, args, me) if args.command == "close"
            else gather(herdr, args, me))
    for row in rows:
        if args.command == "list":
            row["closable"] = closable(row)
        print(json.dumps(row, ensure_ascii=False))


if __name__ == "__main__":
    main()
