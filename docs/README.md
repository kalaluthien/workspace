# docs/ — how this directory works

The workspace root's own document store: proposals and how-to guides about
the container itself — its tooling, its layout, its agent conventions. A
document about one project entry belongs in that entry's own `docs/`, never
here.

Every document is a self-contained `.html` view. There is no specification
(`.md`) layer here — the normative record for the workspace is
`.claude/CLAUDE.md`, and a document that starts stating rules is that file
trying to get out.

Expected readers are humans and coding agents. Write for someone who has the
workspace and nothing else, and will act on what they read.

## Stable titles

One topic, one file, updated in place: `<kebab-title>.html`, flat in this
directory. Git history holds every earlier state, and a document's header
pins the commit it rendered, so dated snapshot filenames are not needed.
`INDEX.md` is the catalogue — every document, its chapter, its scope — and
changes in the same commit that adds, renames, or retires a document.

A title has to be generic against change and specific about scope at once:
it carries no state, verdict, or measurement, because updating in place makes
any of those false; and it names the slice of the workspace it owns, not the
genre, which the chapter already carries.

## Chapters and templates

| chapter | template | holds |
|---|---|---|
| How-to guides | `templates/how-to-guide.html` | one path walked through a procedure at a known commit |
| Proposals | `templates/proposal.html` | a change argued but not decided |

Copy the chapter's template and fill it in. Each template is a whole file —
doctype, inline styles, header, outline — and documents duplicate that
skeleton rather than sharing one, because an author copies a template exactly
once and then owns the result: a shared skeleton is an indirection paid on
every read to save a duplication nobody maintains. Convention carried over
from `camera/docs` (2026-08-01); these two chapters are the whole set here —
no other templates are required.

A template carries a contract: `required-fields` are the header fields a
document must have, `required-sections` the structure it should have. No hook
checks them in this repository — the author checks the document against its
template before commit.

## Rules beyond general craft

- **Self-contained, always.** One file, inline `<style>`, no JavaScript, no
  webfonts, no CDN. It must open from `file://` in ten years.
- **Readable at phone width.** Wide content scrolls inside its own container;
  the page never scrolls sideways; nothing depends on hover.
- **Nothing is decided here.** A proposal argues; acceptance lands where the
  decision lives — a rule in `.claude/CLAUDE.md`, a script, a skill — and the
  proposal's Status field then points there.
- **A guide goes stale by design.** It is pinned to a commit; when a guide
  and the tooling disagree, the guide is stale — fix it, or retire it.
