#!/usr/bin/python3
"""The board rows a sweep is responsible for, and the one write it makes.

A pane and the row behind it go stale together: when the session that held a
row is gone, the row still reads `working` and the board waits on a session
that no longer exists. This module answers which rows those are, and releases
them back to `open` so the wait ends.

It never closes a row. Closing says the work shipped, which only a reader of
the session's report can know; releasing says nobody is working it, which the
empty pane already proves.
"""
import json
import os
import urllib.error
import urllib.request

BOARD = os.environ.get("BOARD_URL", "http://localhost:8300")
TIMEOUT = 5


def snapshot():
    """The board's whole view, or None when the service is not answering."""
    try:
        with urllib.request.urlopen(BOARD + "/api/snapshot", timeout=TIMEOUT) as r:
            return json.load(r)
    except (urllib.error.URLError, OSError, ValueError):
        return None


def tickets(snap):
    for group in (snap.get("board") or {}).get("groups") or []:
        for ticket in group.get("tickets") or []:
            yield ticket


def action(ticket, live):
    """What a sweep owes one row: None, or a row naming the action.

    `live` holds the ids *and* names of every session still running -- board
    dispatches sessions that never take a herdr pane, and those are named
    rather than paned, so a row is orphaned only when neither form of its own
    holders is in there.
    """
    if ticket.get("state") != "working":
        return None
    held = set()
    for session in ticket.get("sessions") or []:
        held.update(v for v in (session.get("id"), session.get("name")) if v)
    if held & set(live):
        return None
    verdict = "held" if "need-you" in (ticket.get("tags") or []) else "release"
    return {
        "ticket": ticket.get("id"),
        "title": ticket.get("title"),
        "state": "working",
        "action": verdict,
        # The tag holds the row's next transition, so the sweep leaves it.
        "reason": "need-you" if verdict == "held" else "no session holds it",
    }


def release(ticket_id, actor, session_id, session_name):
    """Set one row back to `open`. Omitted fields are left as they are."""
    body = json.dumps({
        "state": "open",
        "actor": actor,
        "session_id": session_id or "",
        "session_name": session_name or "",
    }).encode()
    request = urllib.request.Request(
        "%s/api/backlog-tickets/%s/head" % (BOARD, ticket_id),
        data=body, method="PATCH",
        headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT) as r:
            return json.load(r).get("state") == "open"
    except (urllib.error.URLError, OSError, ValueError):
        return False


def sweep(live_sessions, do_release, actor, session_id=None, session_name=None):
    """Every row needing attention, with `released` set under do_release."""
    snap = snapshot()
    if snap is None:
        # Silence would read as "no rows", so the outage is a row of its own.
        return [{"ticket": None, "action": "unreachable", "reason": BOARD}]
    live = set(live_sessions)
    # Board knows its own dispatched sessions, pane or no pane. Trusting the
    # pane roster alone would read one of those as gone and free its row
    # under it.
    for session in snap.get("sessions") or []:
        if session.get("live"):
            live.update(v for v in (session.get("id"), session.get("name")) if v)
    rows = [r for r in (action(t, live) for t in tickets(snap)) if r]
    for row in rows:
        if row["action"] == "release":
            row["released"] = (do_release
                               and release(row["ticket"], actor,
                                           session_id, session_name))
    return rows
