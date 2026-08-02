# docs/ — the parent document system

This directory is two things at once: the workspace's own document store, and
the **parent of every `docs/` directory** in the project entries. The
templates and components here define how all of them write; an entry's
`docs/` follows this system and adds only its own subject matter.

The system is deliberately minimal (2026-08-02, owner decision): four
templates, one shared component set, and no more machinery than a document
needs to be reviewed. A shape that recurs becomes a section pattern inside
an existing template, never a new doctype. Migrating the entries' existing
documents (camera's nine-template set, board's views on the retired
vocabulary) is deferred to its own change (2026-08-02, owner decision — no
backward compatibility owed yet).

## Two kinds, split by extension

| kind | extension | authority | written by | read by |
|---|---|---|---|---|
| **specification** | `.md` | normative — when spec and artifact disagree, one of them is wrong | the main or project agent | agents |
| **view** | `.html` | derived — pinned to a commit, expected to go stale | the `document-writer` subagent | the owner |

A spec records what must stay true and why; a view renders a documented
topic for human review. A view never decides anything: a decision it
surfaces is recorded in a spec in the same change. Workspace-level specs
cover the agent orchestration layer and the service coordination layer;
workspace-level views render topics those specs and `.claude/` files
already document.

Specs share one template, `templates/spec.md`, whose section shapes
(decision, rule, procedure, capability, ledger) cover product scope,
architecture rules, processes, features, and runbooks alike.

## View doctypes

Three, chosen by the reader's question; a document answering two questions
is two documents. Each view carries a `Doctype` field and the one field its
doctype adds.

| doctype | the reader's question | stands on | field it adds |
|---|---|---|---|
| **explanation** | how does it work, why is it this way, what shape does it have, what did we find | the tree at the pinned commit, a recorded decision, or a re-runnable protocol | Question |
| **guide** | how do I do it | one walk through the procedure at a known commit | Goal |
| **proposal** | what should change, and to what | grounded facts for the problem; options — argued or drawn — for everything after | Status |

An explanation and a guide are claims the repository can settle, and a
claim it cannot settle is a defect in them. A proposal is the one view
allowed to describe what does not exist — a mockup is a proposal whose
option is drawn.

## Templates and components

- `templates/` — one file per doctype plus `spec.md`. Each carries its
  whole skeleton (an author copies it once and owns the result), an
  instruction header, a machine contract (`required-fields`,
  `required-sections`), and a **rubric** — binary checks the writer
  verifies before delivering and the reviewer scores against.
- `components/` — the doctype-independent layer, copied never linked:
  `base` (page skeleton), `provenance` (header block), `callout`
  (notice/gap/warning/recovery blocks), `figure` (form choice and
  notation), `disclosure` (accessible detail). Each file demonstrates
  itself and states its own rules.

## Writing pipeline

1. A spec is written by the agent doing the work, in the same change as
   what it governs.
2. A view is delegated to the `document-writer` subagent
   (`.claude/agents/document-writer.md`) with the doctype, the target
   path, and the named sources. The writer fills the template, checks the
   rubric, and reports the rubric result with the file.
3. The reviewer scores against the same rubric. A rubric failure is fixed
   in the document; a rubric ambiguity is fixed in the template.

## Naming and catalogue

One topic, one file, updated in place — git history holds earlier states,
and a view's header pins the commit it rendered. A title is generic
against change (no state, verdict, or measurement in the name) and
specific about scope (it names the slice it owns, not the genre).
Workspace files carry a plane prefix, `agent-` or `service-`; an entry's
files follow the entry's own naming. `INDEX.md` is the catalogue — every
document, its chapter, one line of scope — and changes in the same commit
as the document.
