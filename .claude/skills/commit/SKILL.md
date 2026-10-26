---
name: commit
description: Split staged changes into logical commits with clean Conventional Commits messages
---

Split staged changes into multiple logical commits, each with a clean [Conventional
Commits](https://www.conventionalcommits.org/) message.

## Flags

- Default: run the whole flow without stopping for confirmation — plan, then commit.
- `--confirm`: pause at Step 4 and wait for explicit user confirmation before committing.

## Step 0 — Create the feature branch (only when on `main`)

Run `git branch --show-current` first.

- If you are already on a feature branch (anything other than `main`), skip this
  step entirely and continue to Step 1.
- If you are on `main`, create a feature branch before doing anything else:

1. Determine the primary Conventional Commits type for this work (`feat`, `fix`,
   `chore`, `docs`, `refactor`, `perf`, `build`, `ci`), based on the staged diff.
2. Build the branch name as `<type>/short-name`, where `short-name` is a short,
   lowercase, hyphen-separated description of the work, derived from the staged
   changes (e.g. `feat/gnome-tactile-extension`).
3. Run: `git checkout -b <type>/short-name`

**Do not proceed to Step 1 until the branch is created.**

## Step 1 — Collect staged context

Run these in parallel:
- `git diff --cached --stat` — list of staged files
- `git diff --cached` — full staged diff
- `git branch --show-current` — branch name

If nothing is staged, tell the user and stop.

## Step 2 — Analyse and group

Read the full diff carefully. Group staged files into logical commits where each commit:
- Represents one cohesive unit of change (single responsibility)
- Can be understood and reviewed in isolation
- Tells a clear story when reading the history top-to-bottom

A single package/tool touched by unrelated changes should still split into more than
one commit. Do NOT create a group that mixes unrelated concerns just to avoid a small
commit. A genuinely small, single-concern diff may stay as one commit — don't split
just to hit a count.

## Step 3 — Assign a Conventional Commits type to each group

For each group, pick exactly one type:
- `feat` — new functionality (e.g. a new extension, a new keybind)
- `fix` — bug fix
- `refactor` — code change that neither fixes a bug nor adds a feature
- `docs` — documentation only (README)
- `perf` — performance improvement
- `build` — packaging/installer changes (`Brewfile`, `flatpak/apps.txt`,
  `distrobox.ini`, `mise/`, `bootstrap.sh`)
- `ci` — CI-adjacent tooling
- `chore` — everything else (tooling, config, maintenance)

Add a scope in parentheses matching the stow package or area touched (e.g.
`feat(gnome):`, `fix(nvim):`, `chore(zsh):`); omit it when the type alone
already says enough.

## Step 4 — Present the commit plan

Present the full plan to the user as a numbered list:

```
Commits (in order):

1. feat(gnome): install extensions missing from the image
   Files: gnome/apply.sh, gnome/extensions.txt

2. feat(gnome): enable tactile and keep its settings
   Files: gnome/shell.dconf, gnome/capture.py

3. docs: describe how extra extensions are installed
   Files: README.md
```

- Without `--confirm` (default): this is a status update, not a question — go
  straight to Step 5.
- With `--confirm`: ask **"Does this split look right? Confirm or tell me what
  to change."** and do not proceed to Step 5 until the user explicitly confirms.

## Step 5 — Execute commits in order

For each commit in the confirmed plan:
1. `git reset HEAD -- <all staged files>` to unstage everything first (only on the first iteration)
2. `git add <files for this commit>`
3. `git commit -m "<message>"`

After all commits, run `git log --oneline -<n>` where n = number of commits made, and show the result to the user.

## Commit message rules

- Language: **English only**
- Format: Conventional Commits — `<type>(<scope>): <description>` (scope optional)
- Tense: imperative mood (`add`, `fix`, `expose`, `remove` — not `adds`, `fixed`, `adding`)
- Case: lowercase description, no trailing period
- Length: max 72 characters total
- Scope: one responsibility per message — no "and", no "also"
- No vague words: "update", "change", "misc", "wip", "stuff"
- Do NOT add `Co-Authored-By` or any AI attribution
- Do NOT use `--no-verify`
