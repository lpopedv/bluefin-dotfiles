---
name: ship
description: Ship the work end-to-end — split staged changes into logical commits, then open a draft PR
---

Ship the current work in one pass: first split the staged changes into logical
commits, then open a draft PR built from those commits. This chains the
`/commit` flow and the `/pr` flow, in that order.

The two procedures below are the **single source of truth** — follow them as
written. Ignore the YAML frontmatter at the top of each inlined file; treat the
body of each as a procedure to execute.

## Flags

- Default: run both phases end to end without stopping for confirmation.
- `--confirm`: pass through to both phases — pause at each phase's own
  confirmation gate (commit plan, then PR) and wait for explicit confirmation
  before proceeding.

## Phase 1 — Commit

Execute the full `/commit` procedure:

@.claude/skills/commit/SKILL.md

Run every step above — honoring `--confirm` if passed — and actually create
the commits before moving on. Do **not** open the PR during this phase.

If Phase 1 stops early because nothing is staged, stop here and tell the user —
do not attempt Phase 2.

## Phase 2 — Pull request

Once all commits from Phase 1 exist on the branch, execute the full `/pr`
procedure:

@.claude/skills/pr/SKILL.md

## Orchestration rules

- Run the phases strictly in order: commits first, PR second. Never open the PR
  before the commits exist.
- Without `--confirm` (default), run straight through both phases with no
  pauses. With `--confirm`, honor each phase's own confirmation gate: the user
  confirms the commit plan before commits are made, then confirms the PR
  before it is opened.
- Each phase derives its Conventional Commits type(s) from the diff the same
  way; keep the PR title's type consistent with the commits it summarizes.
- If any step fails (e.g. a commit is rejected by a hook), stop and report it.
  Do not push past a failure into the PR phase.
