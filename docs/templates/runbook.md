# Runbook: <situation>

<!--
  Doctype: runbook — one operational situation and the standing procedure
  that answers it: a service down, a resource full, a scheduled rotation.
  Copy to docs/runbook-<kebab-situation>.md and fill in. Delete every
  comment, including this one; the document must read as if written
  directly.

  A spec is normative: the runbook owns the procedure; a guide view may
  walk one dated execution of it. The reader is an operator — possibly an
  agent — acting under time pressure: the trigger must be recognizable
  from observable signals, and every step must be executable without
  consulting a second document.

  required-fields: Doctype, Status, Scope, Last verified
  required-sections: Trigger, Procedure, Verification, Rollback

  rubric:
  - [ ] Trigger states the observable signals that select this runbook,
        and the ones that look similar but do not.
  - [ ] Every procedure step is executable as written, naming the script
        where one exists.
  - [ ] Verification states the observable state that says the situation
        is resolved.
  - [ ] Rollback says how to undo the procedure's own actions when it made
        things worse, or states why it cannot.
-->

- **Doctype**: runbook
- **Status**: Active <!-- or: Superseded by <file> -->
- **Scope**: <!-- one sentence: the situation this runbook answers -->
- **Last verified**: <!-- YYYY-MM-DD — last executed or checked against
                          the environment -->

## Trigger

<!-- The observable signals that select this runbook, and the look-alike
     signals that select a different one. -->

## Procedure

<!-- Numbered steps, executable as written; a branch exit is a labelled
     sub-item under the step that branches. -->

## Verification

<!-- The observable state that says the situation is resolved. -->

## Rollback

<!-- How to undo this procedure's own actions, or why that is impossible
     and what to do instead. -->
