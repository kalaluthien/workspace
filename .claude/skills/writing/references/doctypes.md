# Doctypes

Read at step 0. Fixes the doctype, the provenance fields, the title, the
proposal additions, and the exits.

- [Three doctypes](#three-doctypes)
- [The page opening](#the-page-opening)
- [Title and file name](#title-and-file-name)
- [Proposal mode](#proposal-mode)
- [Requests this skill does not serve](#requests-this-skill-does-not-serve)
- [What the run never writes](#what-the-run-never-writes)

## Three doctypes

| doctype | the reader's question | what it stands on | field it adds |
|---|---|---|---|
| `explanation` | how does it work, why is it this way, what shape does it have, what did the run measure | the tree at the pinned commit, a recorded decision, or a protocol another reader can re-run to the same numbers | Question |
| `guide` | how do I do it | one walk through the procedure at a known commit | Goal |
| `proposal` | what should change, and to what | grounded facts for the problem, and options for everything after | Status, Question |

An explanation and a guide are claims the repository can settle. A claim it
cannot settle is a defect in them. A proposal is the one doctype allowed to
describe what does not exist, and a drawing of a surface nobody has built
belongs to it.

Write the doctype value exactly as the docs contract spells it, because
`scripts/check-docs` and the board service both read that word.

## The page opening

The page opens with the title as `<h1>`, then the provenance block, then the
first section. Nothing else opens it: no kicker, no subtitle, no scope note,
no summary paragraph, and no footer. The `<h1>` and the `<title>` in the head
carry the same words, and a machine reads the title from the head.

```html
<h1>Run sequence</h1>
<dl class="provenance">
  <dt>Doctype</dt>  <dd>explanation</dd>
  <dt>Question</dt> <dd>one sentence, the question the page answers</dd>
  <dt>Updated</dt>  <dd>2026-08-15</dd>
</dl>
```

- A guide writes `Goal` in place of `Question`. Every doctype carries one of
  the two, because the docs surfaces draw it as the line under the title, and
  a view without one lists with a blank line.
- A proposal adds `Status` above `Question`, with one of three values:
  - `Open` — no decision is recorded yet.
  - `Accepted YYYY-MM-DD → <file>.md` — the acceptance is recorded in a spec,
    and the field points at it.
  - `Rejected YYYY-MM-DD, <reason>` — the reason travels with the rejection.
- `Updated` is today's date, from `date +%F`.
- `Reviewed` is declared in the docs contract, and this skill never writes
  it. It says when somebody last read the document against the tree and found
  it still true. A re-render replaces the prose, so a review of the old prose
  vouches for nothing, and the page reads as never reviewed again. Never
  carry the field over from the document being rewritten.
- No `Commit` field. A commit a reader needs sits on the citation it pins, so
  a page standing on two repositories pins each one where it is used.

## Title and file name

The title is a noun phrase of one to three words. It carries no state, no
verdict, and no measurement, because updating the page in place would make
any of those false. It names the slice the page owns, never the genre, which
the directory already carries. It stays the same across re-renders, and a
rewrite never renames a document on its own.

The file name is that same slice in kebab-case, with `.html`. A file under
`~/workspace/docs/` carries a plane prefix, `agent-` or `service-`. A project
entry's file follows that entry's own naming, read from its `docs/INDEX.md`.

## Proposal mode

Three additions, on top of every other rule.

1. **Two halves, in this order.** AS-IS states the problem, and a file backs
   every claim in it. TO-BE states the change, and it is the one half allowed
   to describe what does not exist.
2. **The halves are marked in the section names.** An AS-IS section names the
   system as it runs today. A TO-BE section names the change it proposes. A
   reader must never guess which half a figure belongs to.
3. **Rationale sits beside the change, never after it.** Each proposed change
   carries the AS-IS fact it answers. A change with no fact above it is a
   preference.

A losing option stays in the document forever. The reason it lost is the only
thing standing between it and being proposed again.

## Requests this skill does not serve

| the request | what it is | where it goes |
|---|---|---|
| 학습 곡선 차트 그려줘 · draw the learning-curve chart | a chart of measured data | the `dataviz` skill |
| 왜 알림이 안 갔는지 봐줘 · find out why it sent nothing | a diagnosis | the `debugger` subagent |
| 결과 리포트 써서 reports/ 에 올려줘 · put the result report under reports/ | a Markdown report under a repository convention | the working agent writes it |
| 이 스펙 문서 업데이트해줘 · update this spec | a `.md` specification | the working agent writes it |
| 알림 채널 바꿔줘 · change the notification channel | a change to the system | perform the change, do not document it |
| 이거 어떻게 하는 게 나을지 제안해줘 · suggest what would be better | no artifact was asked for | chat, per the propose signal in `~/.claude/CLAUDE.md` |

When the brief is one of these, write no HTML. Return
`STATUS: INSUFFICIENT-INPUT` and name the route.

## What the run never writes

- a `.md` file of any kind
- an edit to the system the page explains
- a line in `INDEX.md`, which the caller adds
- a git commit, because the caller owns git
- a decision. Report an unrecorded decision instead of writing it into the
  page.
