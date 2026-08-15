# Draft rules

Read at step 5. The draft passes all fifteen. A to I are nine prohibitions,
so a writer who obeys them writes boxes, arrows, and nothing else. J to O are
the positive half, and they are what puts something on the page.

| | prohibition | | positive |
|---|---|---|---|
| A | No prologue and no colophon | J | The glyph, not its name |
| B | One block per set | K | Group a long enumeration |
| C | Bare noun phrase for a section name | L | The fewest components |
| D | One number set | M | One example per claim |
| E | Plain English | N | The figure leads, the prose follows |
| F | Exact scope in every name | O | A chip or a badge where one is owed |
| G | One component, one mission | | |
| H | No sentence that expires | | |
| I | No sentence about the document | | |

## A · No prologue and no colophon

The title and the provenance block are followed by the first section. Six
shapes carry the same fault: a subtitle, a scope note, a metadata table, a
source pin block, a summary paragraph, and a footer. A metadata table is a
prologue with a border, and a footer is a prologue at the other end. A commit
a reader needs belongs on the citation it pins, inline.

- Rejected: a kicker line above the title, a sentence under it saying what
  the page covers, a `Commit` field, and a Sources footer.
- Accepted: `<h1>`, `dl.provenance`, then section 1. Every commit sits on its
  own citation.

## B · One block per set

Show a set as one block: a file map for files, one figure plus a grouped
table for items. Never one card per member.

- Rejected: three bordered cards, one per doctype.
- Accepted: one grouped table, three rows, two group headers.

## C · Bare noun phrase for a section name

No article, no verb, no claim of importance.

- The loop → Run sequence. The article, and "loop" is the writer's metaphor.
- What it does not do → Run triggers. A sentence, and a negative framing.
- Parts → File map. Vague scope.
- Steps → merged into the figure legend. A second heading for one thing.

Banned words in a heading: `core`, `key`, `powerful`, `deep dive`,
`under the hood`, `magic`, `the real`, `essential`.

## D · One number set

The figure and the step list share one number set.

- Rejected: a figure keyed 1 to 4 above a legend numbered 1 to 6.
- Accepted: the same numerals in the drawing and in the legend.

## E · Plain English

One idea, active voice, no compound sentence. The caps, the twelve writing
rules, and the word lists are in `plain-writing.md`, which step 5 reads
beside this file.

## F · Exact scope in every name

Name the object and the property.

- Lifecycle → Notification state of a task record
- Events and States → Frontmatter change to Slack action
- Message sequence → Message sequence, one task from creation to report
- Frontmatter fields → Frontmatter fields of a task record

The test: read the heading alone, with no page around it. When it does not
say what object it is about, it fails.

## G · One component, one mission

Events go to a step chain, states to a state machine, actor order to a
sequence diagram. The caption states the mission as a fact about the system,
never as a fact about the drawing.

- Rejected: "Figure 2 shows the lifecycle of a task."
- Accepted: "`diffing` compares the old status value against the new one. It
  does not check the order, so a record can move from announced straight to
  done."

## H · No sentence that expires

Cut every sentence addressed to the person who asked, and every count or
state true only on the day of the read.

- Rejected: "Two failure modes are worth remembering, because both look like
  the service being broken. Four records are held right now."
- Accepted: the two mechanisms, stated as facts, inside the table that
  already covers that behaviour.

The test: when a code change or a new run can make it false while the
mechanism stays the same, it belongs in the return message.

## I · No sentence about the document

Cut the read path, the read date, the item count, the tool, and the re-pin
note. A source citation is not text about the document.

- Rejected: "This page was built by reading the three modules listed above."
- Accepted: the citation on each claim.

## J · The glyph, not its name

Show the glyph a reader sees. ✅ reaches the reader, and `white_check_mark`
is its name.

- `white_check_mark` → ✅
- `hourglass_flowing_sand` → ⏳
- `question` → ❓

Show the shortcode beside the glyph when a reader must type it or search for
it. Show the glyph alone when the reader only has to recognise it.

## K · Group a long enumeration

Group an enumeration of 6 or more rows, and name each group with a noun
phrase.

- Rejected: one table, nine rows, the yes rows and the no rows interleaved by
  no principle.
- Accepted: the same nine rows under three group headers.

The threshold is 6 rows, or 3 items where one grouping is the point. A group
of one is not a group: fold it into its neighbour, or drop the grouping.

## L · The fewest components

Use the fewest components that cover the subject. Five clauses:

1. One component per reader question. A section with two figures has two
   questions in it, or one redundant figure.
2. Reuse a kind before you add a kind. A new visual grammar for the same job
   makes the reader learn a second symbol set for nothing.
3. Merge a code sample plus a field table into one specimen anatomy.
4. Cut a component whose facts the neighbouring component already carries.
5. Prefer a table when the shape carries no information. A list of trigger
   inputs does not have a shape.

Rule L never trims the negative-space section.

## M · One example per claim

Every definition, every rule, and every mechanism is shown with one concrete
instance: a real file snippet, a real command with its output, a real record,
a real path. The instance comes from a file the run read, at the pinned
commit. The prose then connects the instances and adds nothing a reader
cannot check against one of them.

A section that states a concept and shows no instance is a defect, however
clear the sentence reads. A reader who does not already know the concept
cannot tell a correct statement from a wrong one, and a reader who does know
it learns nothing.

- Rejected: "A runner never edits the tree it checks."
- Accepted: the same sentence, then
  `scripts/check-figures <view.html>` with its two output lines, showing a
  run that reads and reports and writes nothing.

Two instances beat one where a term has an edge: show what the term covers,
then show the nearest thing it does not. A definition in a proposal's Domain
section carries both, per `doctypes.md`.

## N · The figure leads, the prose follows

A section opens with its figure, its file map, or its keyed panels. The prose
comes after, as keyed items tied to the numerals in the drawing, one item per
numeral.

Beyond the figure, its caption, its legend, and its keyed items, a section
carries at most two connective paragraphs. A third paragraph means the
section holds a second subject, or holds prose that a component should be
carrying.

- Rejected: four paragraphs describing a flow, then a drawing of the flow.
- Accepted: the drawing, its caption, one keyed item per stage, and one
  sentence connecting the section to the next.

## O · A chip or a badge where one is owed

A component no rule selects is never drawn, so three marks have a rule that
selects them.

- **A count chip** wherever the page states how many of something exist —
  every group in a file map, every side of a mapping, every set a reader
  might think is longer. Write `<span class="ct">4&times; entrypoint</span>`,
  not "there are four entrypoints".
- **A value chip** on every state name, status, mode, and doctype that sits
  inside a sentence. The test is one question: could the reader run, open, or
  paste this? A path, a command, an identifier, and a field name are things a
  reader copies, so they stay code spans. A value drawn from a set the page
  names elsewhere is a thing a reader scans for, so it takes the chip:
  `<span class="chip">Open</span>`, not `<code>Open</code>`.
- **A human badge** on the one transition no code performs. A page with no
  such transition carries none.

A page that states a number in words, or a state name in plain text, has
skipped a mark a reader scans for.
