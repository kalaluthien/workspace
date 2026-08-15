# Page HTML

Read at step 6, when the file is built. Fixes the page skeleton, the CSS
baseline, the table rules, and the four components that are markup rather
than drawing.

- [Skeleton](#skeleton)
- [CSS baseline](#css-baseline)
- [Tables](#tables)
- [Do and do-not pair](#do-and-do-not-pair)
- [Count badge and human-action badge](#count-badge-and-human-action-badge)
- [Source citation](#source-citation)
- [Collapsed detail](#collapsed-detail)

## Skeleton

Copy this whole shape. Three head lines are load-bearing and silently break
the page when dropped: `charset` keeps the box-drawing characters, the Korean
in a subject, and a quoted glyph from turning into replacement characters;
`viewport` stops a phone from laying the page out at 980 px, which throws
away the 42rem measure and every stacking rule below; `lang` tells a screen
reader which language to speak.

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Run sequence</title>
<style>
  …the CSS baseline…
</style>
</head>
<body>
<article>

  <h1>Run sequence</h1>
  <dl class="provenance">
    <dt>Doctype</dt>  <dd>explanation</dd>
    <dt>Question</dt> <dd>one sentence, the question the page answers</dd>
    <dt>Updated</dt>  <dd>2026-08-15</dd>
  </dl>

  <h2>First section</h2>
  …

</article>
</body>
</html>
```

The page carries one `<style>` element, no external asset, and no script. A
figure whose subject is Korean keeps `lang="en"` on `<html>` and takes
`lang="ko"` on the element that holds the Korean.

## CSS baseline

```css
:root { --ink:#111; --mute:#555; --hair:#e4e4e4; --wash:#f4f4f4; }
html { font-size: 16px; }
body { max-width: 42rem; margin: 0 auto; padding: 4rem 1.5rem 8rem;
       background: #ffffff; color: var(--ink);
       font-family: system-ui, -apple-system, "Helvetica Neue", Arial, sans-serif;
       line-height: 1.55; overflow-wrap: break-word; }
h1 { font-size: 2rem; line-height: 1.15; margin: 0 0 .9rem; font-weight: 700; letter-spacing: -.01em; }
h2 { font-size: 1.25rem; margin: 3rem 0 .5rem; font-weight: 700; }
h3 { font-size: 1rem; margin: 2rem 0 .3rem; font-weight: 700; }
h4 { font-size: .95rem; margin: 0 0 .4rem; font-weight: 700; }
p, li { margin: .6rem 0; }
ul, ol { padding-left: 1.2rem; }
ol.steps { padding-left: 1.6rem; }
ol.steps > li { margin: 1.3rem 0; }
ol.steps > li::marker { font-weight: 700; }
a { color: #14459b; text-decoration-color: #9bb0d8; }
code, pre, .provenance dd, .src { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: .85em; }
pre { overflow-x: auto; background: var(--wash); padding: 1rem; line-height: 1.45; margin: 1.4rem 0; }
.src { color: var(--mute); }
table { border-collapse: collapse; width: 100%; margin: 1.4rem 0; font-size: .9rem; }
th, td { text-align: left; vertical-align: top; padding: .45rem .8rem .45rem 0; border-bottom: 1px solid var(--hair); }
th { font-weight: 700; }
tr.grp td { background: var(--wash); font-weight: 700; font-size: .8rem; letter-spacing: .06em; text-transform: uppercase; }
@media (max-width: 42rem) {
  table { display: block; overflow-x: auto; }
  th, td { min-width: 9rem; }
  table.stack, table.stack tbody, table.stack tr, table.stack td { display: block; }
  table.stack thead { display: none; }
  table.stack tr { border-bottom: 1px solid var(--hair); padding: .5rem 0; }
  table.stack td { min-width: 0; border-bottom: none; padding: .12rem 0; }
  table.stack td:first-child { font-weight: 700; }
  table.stack td[data-label]::before { content: attr(data-label); display: inline-block;
    width: 7.5rem; color: var(--mute); font-size: .82em; }
}
.provenance { display: grid; grid-template-columns: max-content 1fr; gap: .15rem 1rem;
  margin: 0 0 2.4rem; font-size: .85rem; color: var(--mute); }
.provenance dt { font-variant: small-caps; letter-spacing: .04em; }
.provenance dd { margin: 0; }
figure { margin: 2.2rem 0; }
figure svg { display: block; width: 100%; height: auto; }
figure pre { margin: 0; }
figure.pan { overflow-x: auto; }
figcaption { margin-top: .7rem; font-size: .85rem; color: var(--mute); line-height: 1.5; }
.figure-row { display: grid; grid-template-columns: repeat(auto-fit, minmax(15rem, 1fr));
  gap: 1.2rem; margin: 2.2rem 0; }
.figure-row figure { margin: 0; }
table.filemap td { border-bottom: none; padding: .12rem .8rem .12rem 0; }
table.filemap td:first-child { font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: .85em; white-space: pre; }
.pair { display: grid; grid-template-columns: 1fr 1fr; gap: 1.1rem; margin: 1.4rem 0; }
.do, .dont { border: 2px solid var(--ink); padding: .8rem 1rem; }
.dont { border-style: dashed; }
.do h4::before { content: "\2713\00a0"; }
.dont h4::before { content: "\2715\00a0"; }
.ct { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: .72rem;
  border: 1px solid var(--ink); border-radius: 3px; padding: 1px 4px; }
.hum { display: inline-flex; align-items: center; gap: .3rem; font-size: .8rem;
  border: 1px solid var(--ink); border-radius: 11px; padding: 1px 8px; }
details { border: 1px solid var(--hair); padding: .45rem .9rem; margin: 1.2rem 0; font-size: .92rem; }
details summary { cursor: pointer; font-weight: 600; font-size: .88rem; }
details[open] summary { margin-bottom: .5rem; }
/* Last, so it wins over the two-column .pair declared above. */
@media (max-width: 42rem) { .pair { grid-template-columns: 1fr; } }
```

The type split carries a signal a reader learns once: monospace text is
copyable, and sans text is not. `--ink` takes the body text, every box
border, and every solid arrow. `--mute` takes a caption, a role comment, and
an axis label. `--hair` takes a table cell border, and `--wash` takes the
ground under code and under a group header row.

## Tables

A table wider than three columns stacks at the narrow measure instead of
panning: `class="stack"` on the table, and `data-label` naming the column on
every cell after each row's first, which is the row's title. Columns past the
third must never sit off-screen. Panning stays for `pre`, for a pan figure,
and for tables of three columns or fewer.

Reach this rule only after `components.md` says the content is a table at
all. A stacked row prints one label above each value, so stacking a
comparison whose cells hold sentences produces exactly the repeated
label-value form that file rules out. A three-column table whose last cell is
a sentence pans instead, and the sentence leaves the screen.

A group header row replaces a yes-or-no column. Nine flat rows with a
yes-or-no column make a reader sort them; three groups of three state the
sorting as the answer.

```html
<tr class="grp"><td colspan="4">Settled by the repository</td></tr>
<tr><td>explanation</td><td data-label="question">how does it work</td>…</tr>
```

## Do and do-not pair

Two panels, once per page. The dashed border carries the same meaning it
carries in a drawing, so a reader who learned it in a figure does not learn
it again.

```html
<div class="pair">
  <div class="do"><h4>Brief that names the paths</h4><p>…</p></div>
  <div class="dont"><h4>Brief that names no readable source</h4><p>…</p></div>
</div>
```

## Count badge and human-action badge

`<span class="ct">4&times; entrypoint</span>` states the size of a complete
set, against a group of files and against each side of a mapping. A reader
then knows what a complete set looks like before reading the members.

`<span class="hum">a person writes the brief</span>` marks the one transition
no code performs, and marks nothing else.

## Source citation

A citation is the file, the line, and the commit the claim was read from. The
commit pins the bytes forever, which is what makes a citation checkable. A
page standing on two repositories carries each file's own commit.

```html
<span class="src">src/board/server/docs.py:101 @ 8fd13c1</span>
```

A citation takes an `<a href>` only when the reader can open the target
without a login. These repositories are private, so a file citation stays
plain text. An `<a>` carries an anchor inside the page, or a sibling view in
the same `docs/` directory.

## Collapsed detail

`<details>` is the one carrier for evidence a reader may want and does not
need: a raw command, a long enumeration, a transcript. Its summary states the
conclusion, so a reader who never opens it loses nothing. A page with nothing
to collapse writes none.
