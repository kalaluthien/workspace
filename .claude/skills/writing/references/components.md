# Components

Read at step 3. Routes one section question to one component, and fixes what
each component must show.

- [The vocabulary](#the-vocabulary)
- [Choosing a form](#choosing-a-form)
- [The elements carrier](#the-elements-carrier)
- [File map](#file-map)
- [Specimen anatomy](#specimen-anatomy)

## The vocabulary

Route each section question to exactly one component. Never draw two
components of one kind for one content.

| the reader's question | component | its mission | its form |
|---|---|---|---|
| **Page-level figures, 6** | | | |
| Which parts exist, and where? | File map | Locate each part, and state its role in six words | below |
| What happens in one run? | Keyed step chain | The order, and the two ends | `svg-rules.md` |
| Which states exist, and how does it move? | State machine | The legal transitions, and their writers | `svg-rules.md` |
| Which input produces which output? | Three-column mapping | The count on each side | `svg-rules.md` |
| Who acts, in which order? | Sequence diagram | The channel between the actors | `svg-rules.md` |
| Which items share a fault, and where do they sit? | Location map | The count per group, and the position of each item | `svg-rules.md` |
| **Components below the figure level, 6** | | | |
| What triggers it, and what does not? | Grouped table | Coverage, sorted into named groups | `page-html.md` |
| Which of two paths is right here? | Do and do-not pair | The path that looks legal and is not. Once per page | `page-html.md` |
| Which fields does one record hold, and from where? | Specimen anatomy | Replaces a code sample plus a field table | below |
| Which step does no code perform? | Human-action badge | That transition, and nothing else | `page-html.md` |
| How many parts are in this set? | Count badge | The complete set | `page-html.md` |
| Where did this claim come from? | Source citation | The file, the line, and the pinned commit | `page-html.md` |

## Choosing a form

The form follows the data and the reader's task, never the domain noun. State
the item count and the task first.

- A relation that is not genuinely two-dimensional is a table or a list, and
  the section owes no drawing. A list drawn as boxes is worse than a list.
- Three or more parallel facts are a table, never prose.
- A straight-line sequence with no branch and no loop is `<ol class="steps">`.
- One figure carries one relation and at most seven elements. A denser
  subject becomes a row of small panels in a `div.figure-row`, each panel
  with its own caption, read left to right, sharing one elements table under
  the row.
- Prose that describes a shape a figure could draw is a defect.

## The elements carrier

Every figure names its parts in one of two ways, and never in both.

- A table under the drawing, with a row per element: the name, the type, and
  a one-line description.
- A numbered legend keyed to the figure's numerals, same three parts per
  entry. Order is the legend's extra claim over the table.

Four components name their own parts in place and take no key: the file map
names them in its role column, the do-and-do-not pair in its two headings,
the grouped table in its group header rows, and the specimen anatomy on its
leader lines. The five SVG figures all take numbered circles and a legend.

The caption states the diagram type and its scope, and it carries the key.
Rule G in `draft-rules.md` fixes what the caption says. A figure may carry
invented illustrative values only when its caption says so. A file map and a
specimen never invent.

## File map

A directory whose nesting is part of the answer. Use it at depth two or more,
where a child's role depends on its parent. A flat directory is a plain
table.

```html
<figure id="fig-map">
  <table class="filemap">
    <tbody>
      <tr><td>writing/</td><td>the skill directory</td></tr>
      <tr><td>├── SKILL.md</td><td>entry point, steps 0 to 8</td></tr>
      <tr><td>└── references/</td><td>one file per step that needs one</td></tr>
    </tbody>
  </table>
  <figcaption>File map of the skill directory at the pinned commit. Key:
    indentation — directory nesting; right column — the part's role. One
    entry point, five references.</figcaption>
</figure>
```

The table aligns the two columns, so no hand-counted spaces drift, and the
role column is the map's own elements carrier. Transcribe every path from the
tree at the pinned commit. Counts go in the caption as a sentence.

## Specimen anatomy

A text artifact whose field order is the grammar: a filename pattern, a log
line, a message format, a flag string. Put one real instance from the pinned
commit in a `<pre>`, rule each field with box-drawing characters on the lines
below, and end each leader at the field's name alone. Every ruler character
sits under a character of the field it spans. The meaning lives in the
elements carrier under the figure.

```
agent-config-scopes.html
└─┬─┘ └─────┬─────┘ └─┬┘
  │         │         └── extension
  │         └── slice
  └── plane
```

An artifact whose fields name themselves, such as JSON or `key=value`, is a
table and not a specimen.
