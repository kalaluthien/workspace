# Draft rules

Read at step 5. The draft passes all twelve. A to I are nine prohibitions, so
a writer who obeys them writes boxes, arrows, and nothing else. J to L are the
positive half.

| | prohibition | | positive |
|---|---|---|---|
| A | No prologue and no colophon | J | The glyph, not its name |
| B | One block per set | K | Group a long enumeration |
| C | Bare noun phrase for a section name | L | The fewest components |
| D | One number set | | |
| E | Plain English | | |
| F | Exact scope in every name | | |
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
