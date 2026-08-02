# Feature: <name>

<!--
  Doctype: feature — one atomic capability: independently specifiable,
  testable, removable. Copy to docs/feature-<kebab-name>.md and fill in.
  Delete every comment, including this one; the document must read as if
  written directly.

  A spec is normative: when it and the artifact disagree, one of them is
  wrong — fix whichever lost, in the same change. A project that groups
  features under surfaces or categories adds its own field for that (the
  project's product spec owns the grouping model).

  required-fields: Doctype, Status, Scope, Last verified
  required-sections: Behavior, Configuration, Acceptance

  rubric:
  - [ ] Scope states in one sentence what this one capability is.
  - [ ] Behavior is predicates the artifact must keep true, naming the
        owner of every piece of state read — not a paraphrase.
  - [ ] Configuration answers "can I change this?" even when the answer is
        "None — <why>".
  - [ ] Acceptance is observable checks, pointing at the test that
        automates each, marking manual ones as manual.
-->

- **Doctype**: feature
- **Status**: Active <!-- or: Superseded by <file> -->
- **Scope**: <!-- one sentence: what this one feature is; doubles as its
                 purpose — add a Purpose section only when the why needs
                 more than a sentence -->
- **Last verified**: <!-- YYYY-MM-DD — checked against the artifact -->

## Behavior

<!-- Predicates the artifact must keep true. -->

## Configuration

<!-- The control surface and its persistence: where it is changed, the
     default, whether the value survives a restart. A feature with no
     control surface writes "None — <why>" and names what decides the
     value. -->

## Acceptance

<!-- Observable checks a reader can run, not internals. -->

## Non-goals and deferred work

<!-- Optional: what was consciously left out, with reason and date. Delete
     when empty. -->
