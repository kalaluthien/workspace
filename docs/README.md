# docs/ — catalogue of the document system

The workspace root's document store: self-contained `.html` views about the
container itself, reviewable from `file://` with nothing else installed.
Every rule of the system lives inside the three templates — each template is
a whole filled example carrying its own contract — so this file only says
what exists and where.

| chapter | template | reader's question | holds |
|---|---|---|---|
| Principles | `templates/principle.html` | why is it this way? | a decision argued (Open) or recorded (Accepted), with the reasons that keep it true |
| Patterns | `templates/pattern.html` | what shape does it have? | a structure or relation drawn and named, existing or proposed |
| Practices | `templates/practice.html` | how do I do it? | one procedure walked to a goal at a known commit |

- `INDEX.md` — the catalogue of documents: every document, its chapter, one
  line of scope. Changes in the same commit as the document.
- `templates/` — the three templates above. To add a document, follow the
  practice template's own example, which is that procedure.
- Filing summary (normative text in each template's header): one topic, one
  file, `<plane>-<kebab-slice>.html` with plane prefix `agent-` or
  `service-`, updated in place; the workspace's normative rules stay in
  `.claude/CLAUDE.md`.
