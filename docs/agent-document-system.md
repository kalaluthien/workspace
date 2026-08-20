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

## Decision: the writing skill replaces the writer subagent (2026-08-15, owner)

The normative site moved from the `document-writer` subagent's constitution
to the `writing` skill, `~/workspace/.claude/skills/writing/`: `SKILL.md`
with `references/` (doctypes, components, svg-rules, draft-rules,
plain-writing, page-html), `scripts/render-check`, and
`evals/trigger-cases.md`. The skill runs in a forked context
(`context: fork`, `model: opus`): a five-field brief goes in, one HTML view
and a five-section return message come out. The structural baseline is the
`documenting` skill recipe the owner supplied on 2026-08-15 (a saved page,
extracted to plain HTML); the constitution was quarried for what the recipe
missed — the phone-width figure rules, the docs contract's provenance
fields, the `Reviewed` semantics — and then retired, together with its
`templates/` and `components/` directories, which the skill's `references/`
replace. Acceptance: a separate evaluator scored the skill 86/100 on
simplicity, completeness, and modularity against a 50-point first-version
anchor, and its render script was proved able to fail before being trusted.

Confirmed by the owner on 2026-08-20. The read this decision still owed
(backlog-ticket `workspace-t16`, filed 2026-08-12) came back with no veto and
no change asked for, so the skill stands as the normative site. It was read as
it stands today, six commits past `ea84832`, three of which encode owner
feedback on the pages it wrote.

What the 2026-08-04 decision bought is kept: one normative site, loaded by
the one actor that writes views. What changes: the site now lives inside
the workspace repository, so a rule change and the workspace documents that
follow it land in one commit — the cost that decision accepted (rules in
`~/.claude`, documents in the entries) is retired with it. The half of that
decision that still stands, re-verified today: every other site holds at
most a pointer plus the machine contract its own tools parse.

## Decision: the writer constitution is the one normative site (2026-08-04, owner)

Superseded 2026-08-15 by the decision above; kept with its reasons.

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
  2026-08-04, half closed. The workspace's own five views were re-rendered on
  2026-08-05 (`01d2800`), and board's shelf on 2026-08-11 (board `1739016`,
  released `v1.13.4`) — ten views by then, not the five this bullet counted,
  and re-rendered under the compacted constitution rather than the style layer
  alone: kicker, boxed conclusion and highlights, every rationale in a
  disclosure, and the open page a third shorter across the shelf. Camera's
  five still carry no kicker, and whether to spend that re-render is the
  owner's call.
