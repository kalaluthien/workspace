# spec/ — the workspace specification store

This directory holds the workspace's own specifications. A specification is
normative: when it and the artifact disagree, one of them is wrong, and
somebody has to say which. That is what separates it from a document, which
is drawn for a reader and is allowed to go stale.

Both are written in natural language. Nothing else about them is shared, so
they are kept apart: `docs/` and its contract (`docs/README.md`) govern
views only, and nothing here is catalogued, rendered, or served as a
document. (Owner decision, 2026-08-20.)

## What belongs here

A file here states a predicate on the system, a rule that generates system
structure, or a decision with its reason. Anything that mirrors what an
artifact already says belongs in neither directory — it is redundant the day
it is written and false after the artifact's next change.

Name a file for the slice of the system it owns, with the plane prefix
`docs/` uses: `agent-` for the entries and the sessions that work them,
`service-` for the long-running things they expose.

## Writing one

`templates/spec.md` is the shape. It declares the header fields a spec
carries; an entry's docs checker resolves that path to decide what a `.md`
is checked against, so the file stays where it is.

There is no index. The directory lists itself, and a catalogue would be a
second copy able to disagree with the first. Add one when the ordering of
specs starts carrying meaning that the filenames cannot.
