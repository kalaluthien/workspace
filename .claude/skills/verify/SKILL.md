---
name: verify
description: Run the workspace root repository's own checks — the docs contract, the checker's test, the session classifier, the figure rules — and report pass or fail for each.
model-invocable: false
disable-model-invocation: true
---

# Verify

Four checks, all read-only, all run from the workspace root, `~/workspace`.
Run every one even after a failure: a person typing `/verify` wants the whole
picture, not the first stumble. Each check prints its own verdict and exits
non-zero when it fails.

## The checks

1. **The docs contract.**

       python3 scripts/check-docs

   Checks this repository's `docs/` against the `json contract=docs` block in
   `docs/README.md`: every view catalogued, every catalogued view present, the
   provenance block, the doctype, its chapter, and the Updated date. Prints
   the repository path followed by `ok` when the tree holds. With no
   argument it checks the tree the script itself sits in, so a copy run
   from a worktree judges that worktree.

2. **The docs checker's own test.**

       python3 scripts/check-docs-test

   Four cases, each building a throwaway git repository, wiring the real
   `hooks/pre-commit` into it, and committing. They prove the checker judges
   the tree the commit ships rather than the working directory. Prints one
   `ok` line per case and a count.

3. **The session classifier.**

       .claude/skills/cleaning-sessions/scripts/verify-verdicts

   Runs the pane classifier against captured screens with a stub herdr, so it
   touches no live session. Prints one `ok` line per screen. A session's screen
   markers are the classifier's only evidence, so a change to them breaks the
   sweep silently, and this is the check that catches it.

4. **The figure rules.**

       python3 ~/.claude/git-hooks/check-figures docs/*.html

   The annotation floor, the pan wiring, and the viewBox maximum, over the
   views in the working tree. Silent when every view passes. The checker sits
   in `~/.claude`, beside the rule it enforces, so a machine without that
   repository has no rule to read: a missing file is skipped, not failed.

## The wiring

`hooks/pre-commit` runs checks 1 and 4 on any commit that stages `docs/`, but
git does not clone a hook. Confirm the machine still carries the wiring:

    git config core.hooksPath
    ls -l "$(git config core.hooksPath)/pre-commit"

The first must print this repository's `.git/local-hooks`, and the second
must show an executable file. Read the path from `core.hooksPath`, never
from `git rev-parse --git-dir`, which answers with the worktree's own git
directory when the check runs in a worktree. An unwired repository passes all four checks above
and still lets a broken `docs/` through, because nothing runs at commit time.

## What is not checked here

Rendering. The `writing` skill's `scripts/render-check` opens one view in
Chrome and reports what the render shows. It belongs to authoring a single
view, not to a repository-wide pass, and it needs Chrome on the machine.

## Report

- One bullet per check: its name, `pass` or `fail`, and for a failure the line
  the check printed.
- One bullet for the wiring: `wired` or what is missing.
- Close with what waits on the person. When every check passes, stop at the
  outcome.
