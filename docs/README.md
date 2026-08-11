# docs/ — the workspace document store

This directory holds the workspace's own specs (`.md`) and views
(`.html`), over both planes (`agent-` and `service-` filename prefixes),
catalogued in `INDEX.md`. The document system that governs this and every
entry's `docs/` — doctypes, templates, components, style, naming, and the
writing pipeline — is defined once in the `document-writer` agent's own
files: the constitution `~/.claude/agents/document-writer.md`, with
`templates/` and `components/` beside it in
`~/.claude/agents/document-writer/` (the decision and its losing
alternatives: `agent-document-system.md`). This
file keeps only the two-kinds table and the machine contract below, which
`scripts/check-docs` and the board service parse at this path.

## Two kinds, split by extension

| kind | extension | authority | written by | read by |
|---|---|---|---|---|
| **specification** | `.md` | normative — when spec and artifact disagree, one of them is wrong | the main or project agent | agents |
| **view** | `.html` | derived — pinned to a commit, expected to go stale | the `document-writer` subagent | the owner |

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

Three roles are required of every view — `doctype`, `question`, `updated`.
`reviewed` is the one optional role: it carries the date somebody last read
the document against the tree and found it still true. A view without it is
valid everywhere, and it means the document has never been reviewed — not
that the review is missing. That is also what a re-render leaves behind: the
writer fills the provenance block from its template, which carries no
`Reviewed` term, so a rewritten document reads as never reviewed again. The
rule and its reason are the writer constitution's
(`~/.claude/agents/document-writer.md`); this is only where the term is
declared. A reader comparing the two dates compares *authored* dates: file
mtime is a checkout timestamp, not a written time.

```json contract=docs
{
  "contract": "docs",
  "version": 1,
  "updated": "2026-08-12",

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
      "updated": ["Updated"],
      "reviewed": ["Reviewed"]
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
