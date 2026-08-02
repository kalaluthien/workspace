# docs/ — the parent document system

This directory is two things at once: the workspace's own document store, and
the **parent of every `docs/` directory** in the project entries. The
templates and components here define how all of them write; an entry's
`docs/` follows this system and adds only its own subject matter.

## Two kinds, split by extension

| kind | extension | authority | written by | read by |
|---|---|---|---|---|
| **specification** | `.md` | normative — when code and spec disagree, one of them is wrong | the main or project agent | agents |
| **view** | `.html` | derived — pinned to a commit, expected to go stale | the `document-writer` subagent | the owner |

A spec records what must stay true and why; a view renders a documented topic
for human review. A view never decides anything: a decision it surfaces is
recorded in a spec in the same change.

Workspace-level specs cover two layers: the **agent orchestration layer**
(sessions, delegation, memory, instruction scopes) and the **service
coordination layer** (long-running services, containers, tailnet exposure).
Workspace-level views render topics those specs and `.claude/` files already
document.

## View doctypes

Every view carries a `Doctype` field naming its kind. The doctype is chosen
by the reader's question; a document answering two questions is two documents.

| doctype | the reader's question | stands on | field it adds |
|---|---|---|---|
| **explanation** | how does it work, why is it this way, what shape does it have | the repository at the pinned commit, or a recorded decision | Question |
| **report** | what did we find when we looked | a protocol another reader can re-run to the same findings | — |
| **guide** | how do I do it | one walk through the procedure at a known commit | Goal |
| **proposal** | what should change, and to what | grounded facts for the problem; options for everything after | Status |
| **mockup** | what could this look like | a proposal, a survey, or nothing but the drawing | — |

The first three are claims the repository can settle, and a claim it cannot
settle is a defect in them. The last two are allowed to describe what does
not exist, which is why they come last in a catalogue. An explanation is
timeless ("what is true"); a report is dated ("what we found") — a numeric
benchmark, a connectivity check, and a survey of a tree are all reports.

## Spec doctypes

| doctype | holds |
|---|---|
| **product** | what a thing is, and the decision stack that shaped it |
| **engineering** | the rules the structure obeys, as generating rules and predicates |
| **process** | how the thing is checked, versioned, and delivered |
| **feature** | one atomic capability: behavior, configuration, acceptance |
| **runbook** | one operational situation: trigger, procedure, verification, rollback |

## Templates and components

- `templates/` — one file per doctype. Each template carries its whole
  skeleton (an author copies it once and owns the result), an instruction
  header, a machine-readable contract (`required-fields`,
  `required-sections`), and a **rubric** — binary checks the writer verifies
  before delivering and the reviewer scores against.
- `components/` — reusable pieces a document copies in: the base page style,
  the provenance header, callout blocks, the figure kit, and the disclosure
  block. Documents stay self-contained, so a component is copied, never
  linked. Each component file demonstrates itself and states its own rules.

## Writing pipeline

1. A spec is written or updated by the agent doing the work, in the same
   change as the code or configuration it governs.
2. A view is delegated to the `document-writer` subagent
   (`.claude/agents/document-writer.md`) with the doctype, the target path,
   and the named sources. The writer copies the template, fills it, checks
   the rubric, and reports the rubric result with the file.
3. The reviewer (the owner, or the delegating agent) scores the document
   against the same rubric. A rubric failure is fixed in the document; a
   rubric ambiguity is fixed in the template.

## Naming and catalogue

One topic, one file, updated in place — git history holds earlier states,
and a view's header pins the commit it rendered. A title is generic against
change (no state, verdict, or measurement in the name) and specific about
scope (it names the slice it owns, not the genre). Workspace files carry a
plane prefix, `agent-` or `service-`; an entry's files follow the entry's
own naming. `INDEX.md` is the catalogue — every document, its doctype
chapter, one line of scope — and changes in the same commit as the document.
