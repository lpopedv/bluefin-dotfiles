---
name: pr
description: Open a draft PR with a clean, community-standard body derived from the branch's commits and diff
---

Open a draft pull request against `main`, with a body written from the branch's commits and diff. This repo has no PR template file, so the structure below is the standard to follow every time.

## Flags

- Default: run the whole flow without stopping for confirmation — build the PR, then open it.
- `--confirm`: pause at Step 4 and wait for explicit user confirmation before opening the PR.

## Step 1 — Collect context

Run all in parallel:
- `git branch --show-current` — current branch name
- `git log main..HEAD --oneline` — all commits on this branch
- `git diff main..HEAD` — full diff against main

If `git log main..HEAD` returns nothing, tell the user there are no commits ahead of main and stop.

## Step 2 — Derive the title

- Determine the Conventional Commits type of the branch's dominant change (`feat`, `fix`,
  `chore`, `docs`, `refactor`, `perf`, `build`, `ci`) — usually the type shared by
  most commits, or the most significant one if the branch mixes types.
- Title format: `<type>: <what was built>`.
  - Imperative mood, English, lowercase after the prefix, max 72 chars.
  - Must be specific — describe the change, not the action ("install missing gnome extensions" not "update gnome").
  - Example: `feat: install gnome extensions the image doesn't ship`.

## Step 3 — Fill the PR body

Using the commits and diff as source of truth, fill this exact structure:

```markdown
## Summary

<1-3 sentences: what changed and why, written for a reader with zero context.>

## Changes

- <bullet per logical change, grouped by package/area (e.g. `gnome/`, `nvim/`, `system/etc/`)>

## Test plan

- [ ] <concrete, verifiable check>
```

**Test plan** — this repo has no build/test/lint pipeline, so derive
checks from the project's own verification method instead of a generic test suite:
- A stowed config: `stow -n --restow <pkg>` shows no conflicts
- A shell script: `bash -n <script>` passes, and it was actually run (`./bootstrap.sh --dry-run` when available)
- A Lua config (nvim): syntax checked (`luac5.1 -p`, the LuaJIT dialect nvim runs) and, ideally, nvim was restarted to confirm it loads
- A dconf file (`gnome/`): `gnome/apply.sh` loaded it on the host and the setting took effect
- A host change (`system/etc/`, flatpaks, brew): checked on the host via `distrobox-host-exec`
- Anything else: re-read the target application's own config-loading rules and state what was checked

**Verify every item before writing it down.** For each one, actually run the check (or
reuse one already performed this session) and mark it `- [x]` once confirmed. Leave a
box unchecked (`- [ ]`) only when it genuinely could not be verified — say so explicitly
rather than defaulting to an all-unchecked list.

## Step 4 — Present the PR

Present the full PR title and body to the user.

- Without `--confirm` (default): this is a status update, not a question — go
  straight to Step 5.
- With `--confirm`: ask **"Does this look right? Confirm to open the draft PR,
  or tell me what to adjust."** and do not open the PR until the user
  explicitly confirms.

## Step 5 — Open the draft PR

The branch is never already pushed in this workflow — always push it first, without asking, then create the PR:
```
git push -u origin <branch>
gh pr create --draft --title "<title>" --body "<body>"
```

After creation, output the PR URL so the user can open it directly.

## Rules

- Always open as **draft** — never as a ready-for-review PR
- Target branch is always `main`
- Do not invent functionality that isn't visible in the diff
- Do not add `Co-Authored-By` or AI attribution anywhere
