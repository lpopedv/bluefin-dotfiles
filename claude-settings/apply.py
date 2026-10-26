"""Merge settings.json (next to this script) into ~/.claude/settings.json.

Claude Code itself (/model, /config) and integrations such as herdr or Orca
write to that file, so it is a real file, not a stow link: the repo owns only
the keys it sets. Objects are merged key by key, lists gain the entries they
lack (hooks other tools install are kept), anything else is overwritten.

    python3 -I apply.py [--dry-run]
"""

import json
import sys
from pathlib import Path

BASE = Path(__file__).with_name("settings.json")
LIVE = Path.home() / ".claude" / "settings.json"


def merge(live, base):
    if isinstance(live, dict) and isinstance(base, dict):
        return {**live, **{k: merge(live[k], v) if k in live else v for k, v in base.items()}}
    if isinstance(live, list) and isinstance(base, list):
        return live + [item for item in base if item not in live]
    return base


def main():
    dry = sys.argv[1:] == ["--dry-run"]
    live = json.loads(LIVE.read_text()) if LIVE.exists() else {}
    result = merge(live, json.loads(BASE.read_text()))

    if result == live and not LIVE.is_symlink():
        print("    \033[32mok\033[0m ~/.claude/settings.json")
    elif dry:
        print("    \033[36mwould\033[0m merge settings.json into ~/.claude/settings.json")
    else:
        LIVE.parent.mkdir(parents=True, exist_ok=True)
        LIVE.unlink(missing_ok=True)  # replaces a stow link left by an older layout
        LIVE.write_text(json.dumps(result, indent=2) + "\n")
        print("    \033[32mok\033[0m ~/.claude/settings.json (merged)")


if __name__ == "__main__":
    main()
