# Document system

- **Status**: Active
- **Scope**: which file holds the document system's rules, why that file and
  not another, and what the choice still owes.
- **Last verified**: 2026-08-06

## Purpose

A reader who wants to change a documentation rule needs to know which single
file to edit, and a reader who wants to reverse that arrangement needs the
reason it was chosen. This spec records the decision; the rules themselves
live in the file the decision names.

## Decision: the writer constitution is the one normative site (2026-08-04, owner)

`~/.claude/agents/document-writer.md` holds the whole normative description of
the document system — the two-kinds split, the doctypes, naming and catalogue,
the writing procedure, the style, the guardrails — with `templates/` and
`components/` beside it in `~/.claude/agents/document-writer/`. Every other
mention holds at most a pointer to it plus the machine contract its own tools
parse.

The rule that decided it: a rule lives in the single file its actor loads at
the moment the rule binds. The writer agent is the only actor that touches
every view in every entry, and its own definition is the file it always loads.

Before this decision, seven sites stated the rules (workspace `b969155`), and a
brevity rule added on 2026-08-04 reached six of them and none of the eight
entry template copies. The drift was observed, not predicted: camera's template
copy named a different filename grammar than its parent, and board's copies
carried "when the two disagree, the parent wins", which names the drift without
preventing it.

Two alternatives lost:

- **`docs/README.md` as the master.** It loses on locality. The writer needs
  the rules inside its own definition to act on them, so the README–definition
  duplication would survive as structure rather than as an accident.
- **The writer as sole author of every document.** It loses on the rule that a
  spec is written by the agent doing the work, in the same change as what the
  spec governs — that agent is the one holding the context. Routing specs
  through the writer would also serialize all documentation behind one agent.

The cost accepted: the constitution lives in `~/.claude` while the documents it
governs live in the entries, so no single commit changes a rule and the
documents that follow it together.

The reversal condition: this decision flips if that split costs more than the
locality it bought, or if the constitution grows until it reads as two
documents — at which point the spec rules split into a file that
`templates/spec.md` points at.

## Non-goals and deferred work

- **Re-rendering the entries' view shelves under the style layer** — deferred
  2026-08-04, still open. The workspace's own five views were re-rendered on
  2026-08-05 (`01d2800`), but none of camera's five or board's five carries a
  kicker. Whether to spend that re-render is the owner's call.
