# English learning system 🇬🇧💼

Goal: get hired for international remote developer jobs. Practice happens while I work.

## How it works

| What | How |
|------|-----|
| **Practice while I work** | Write any message in English. A hook (`~/.claude/hooks/en-auto.py`) detects it and runs the `en` skill: correction → log → the real task, answered in English. `/en <msg>` still works manually. |
| **Mock interviews** | `/en-interview [behavioral \| technical \| intro \| salary \| <job description>]`: one question at a time, feedback on language + answer quality, model answer, recruiter-style debrief. |
| **Weekly review** | `/en-review [days]`: stats, recurring mistakes, a quiz built from my own mistakes, a study plan, job-readiness. Saved to `reviews/`. |

Every 5th logged message ends with a 🎯 mini-challenge. Mistakes that repeat are flagged with 🔁.

Turn auto-detection off temporarily with `touch ~/.claude/english/auto-off` (turn it back on with `rm ~/.claude/english/auto-off`).

## Files

- `~/.claude/skills/en/SKILL.md`, `en-review/SKILL.md`, `en-interview/SKILL.md` — the skills
- `~/.claude/skills/en/scripts/entool.py` — `log` (validates the entry and stamps the real UTC time), `stats` (for the review), `context` (recurring mistakes, loaded into each lesson)
- `~/.claude/hooks/en-auto.py` — detects English prompts (registered under `UserPromptSubmit` in `~/.claude/settings.json`)
- `log.jsonl` — one line per practiced message (`source`: `chat` or `interview`)
- `vocab.jsonl` — terms taught to me
- `reviews/YYYY-MM-DD.md` — weekly snapshots
- `backup-2026-10-15/` — versions from before the 2026-10-15 upgrade

### `log.jsonl` schema
```json
{"ts": "2026-10-15T14:00:00Z", "source": "chat", "original": "...", "corrected": "... | null",
 "natural": "... | null", "errors": [{"type": "preposition", "wrong": "depends of", "right": "depends on", "note": "..."}],
 "did_well": ["..."], "score": 7, "level_estimate": "B1"}
```
Note: entries before 2026-10-15 have approximate timestamps.

## Versioning

The tooling is versioned in `~/Dotfiles/claude/.claude/` and stowed by `bootstrap.sh`, so every
machine gets it. Personal data (`log.jsonl`, `vocab.jsonl`, `reviews/`, `auto-off`) stays local —
the dotfiles repo is public. Edit the skills through the symlinks (or in the repo) and commit.
