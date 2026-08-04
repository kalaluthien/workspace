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
doctype adds, and closes with a sources footer — the header carries no
Source field.

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
  `base` (page skeleton), `provenance` (header block and sources footer), `callout`
  (notice/gap/warning/recovery blocks), `figure` (form choice and
  notation), `disclosure` (accessible detail). Each file demonstrates
  itself and states its own rules.

## House style

Five rules bind every view; each template's rubric checks them.

- **Naming** — the title and every section heading are noun phrases of one
  to three words. The conclusion is a full sentence in the lead paragraph
  (or the Goal field), never in the heading.
- **Prose rhythm** — a paragraph holds one topic in at most three
  sentences. Prefer one full sentence that carries a claim together with
  its qualifier over two clipped sentences that split them.
- **MECE structure** — the section set partitions the document's question:
  every fact has exactly one home, and a fact that fits two sections marks
  a wrong split. Fix the split before writing prose into it.
- **Figures and tables** — many and small: one figure carries one relation
  among at most seven elements, and a denser subject splits into panel rows
  or per-section figures; three or more parallel facts are a table, never
  prose. No text in a figure touches another mark
  (`components/figure.html` carries the geometry rule). Form follows the
  subject: a directory anatomy is a file map, a text artifact whose field
  order is the grammar is a specimen anatomy, and a sequence with a
  feedback edge is a keyed stage figure — `components/figure.html`
  demonstrates all three. A figure wider than 360 viewBox units pans
  (`figure.pan`) instead of shrinking, and dashed marks the speculative
  and nothing else.
- **Design language** — manual-style minimalism (owner decision,
  2026-08-02): flat black-on-white, system sans-serif, thin rules, numbered
  landmarks, generous whitespace, and near-wordless drawings whose words
  live in the elements table.

## Writing pipeline

1. A spec is written by the agent doing the work, in the same change as
   what it governs.
2. A view is delegated to the `document-writer` subagent, defined at the
   user level (`~/.claude/agents/document-writer.md`) so a session in any
   project entry can spawn it, with the doctype, the target path, and the
   named sources. The writer fills the template, checks the
   rubric, and reports the rubric result with the file.
3. The reviewer scores against the same rubric. A rubric failure is fixed
   in the document; a rubric ambiguity is fixed in the template.

## Naming and catalogue

One topic, one file, updated in place — git history holds earlier states,
and a view's header pins the commit it rendered. A title is a noun phrase
of one to three words, generic against change (no state, verdict, or
measurement in the name) and specific about scope (it names the slice it
owns, not the genre).
Workspace files carry a plane prefix, `agent-` or `service-`; an entry's
files follow the entry's own naming. `INDEX.md` is the catalogue — every
document, its chapter, one line of scope — and changes in the same commit
as the document.

## The docs contract

The block below is this system's machine copy: where a `docs/` directory
keeps its views, how `INDEX.md` spells a chapter and a member link, which
`<dt>` terms carry which provenance role, and which chapter a doctype
belongs to. A program that reads any entry's `docs/` parses it instead of
carrying its own copy — the board service's docs surface and the
`scripts/check-docs` checker both do — so a change to the system's machine
shape is made here, in the same commit as the prose it follows. A rule
encoded twice is a rule that drifts.

Each role lists its accepted `<dt>` terms, primary first. The retired
`Category` term was read beside `Doctype` while the entries migrated; the
migration finished on 2026-08-03 (board `4ee9f83`, camera `140ac74`), and
the contract reads `Doctype` alone.

```json contract=docs
{
  "contract": "docs",
  "version": 1,
  "updated": "2026-08-03",

  "view": { "dir": "docs", "extension": ".html", "depth": 1 },

  "index": {
    "file": "INDEX.md",
    "chapter_prefix": "## ",
    "link": "markdown-link-to-sibling-view",
    "ignore_lines": ["Template:"]
  },

  "provenance": {
    "selector": "dl.provenance",
    "roles": {
      "doctype": ["Doctype"],
      "question": ["Question", "Goal"],
      "updated": ["Updated"]
    }
  },

  "doctypes": [
    { "name": "spec", "chapter": "Specifications" },
    { "name": "explanation", "chapter": "Explanations" },
    { "name": "guide", "chapter": "Guides" },
    { "name": "proposal", "chapter": "Proposals" }
  ],

  "unlisted_chapter": "Unlisted",
  "title": "head-only"
}
```

`spec` is the `.md` kind: it holds a chapter in every `INDEX.md` and is
never a view, so a reader that lists views only catalogues the chapter and
serves nothing under it. `unlisted_chapter` names where a reader files a
document its `INDEX.md` does not list; it is declared so every reader
agrees on the word, and each reader owns whether it degrades that way at
all.
