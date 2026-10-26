#!/usr/bin/env python3
"""Dump the dconf sections this repo manages into gnome/*.dconf.

Run it after changing a setting in GNOME, review `git diff`, commit. Only the
sections matched below are kept, and per-machine or purely transient keys
(window sizes, monitor connectors, toggled state) are dropped so the files
replay cleanly on another install: `gnome/apply.sh`.
"""
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent

# file -> section-path regexes (matched against the full path, e.g. org/gnome/shell)
GROUPS = {
    "keybindings.dconf": [
        r"org/gnome/settings-daemon/plugins/media-keys(/.*)?",
        r"org/gnome/desktop/wm/keybindings",
        r"org/gnome/shell/keybindings",
        r"org/gnome/mutter/keybindings",
    ],
    "desktop.dconf": [
        r"org/gnome/desktop/interface",
        r"org/gnome/desktop/wm/preferences",
        r"org/gnome/desktop/input-sources",
        r"org/gnome/desktop/peripherals/.*",
        r"org/gnome/desktop/privacy",
        r"org/gnome/desktop/session",
        r"org/gnome/settings-daemon/plugins/(power|color)",
        r"org/gnome/nautilus/preferences",
        r"org/gtk/gtk4/settings/file-chooser",
        r"org/gnome/Ptyxis",
    ],
    "shell.dconf": [
        r"org/gnome/shell",
        r"org/gnome/shell/extensions/(blur-my-shell(/.*)?|caffeine|dash-to-dock|search-light|tactile)",
    ],
}

# Keys that describe this machine or this moment, not a preference.
DROP_KEYS = re.compile(
    r"^(window-size|window-state|last-panel|migrated-gtk-settings|"
    r"app-picker-layout|welcome-dialog-last-shown-version|"
    r"preferred-monitor.*|monitor-count|user-enabled)="
)

# The list of custom-keybinding slots comes from Bluefin's system defaults, so
# `dconf dump` doesn't contain it; without it the slots below stay inactive.
MEDIA_KEYS = "org/gnome/settings-daemon/plugins/media-keys"


def sections(dump):
    name, lines = None, []
    for line in dump.splitlines():
        m = re.fullmatch(r"\[(.+)\]", line)
        if m:
            if name is not None:
                yield name, lines
            name, lines = m.group(1), []
        elif name is not None and line.strip():
            lines.append(line)
    if name is not None:
        yield name, lines


def main():
    dump = subprocess.run(["dconf", "dump", "/"], capture_output=True, text=True, check=True).stdout
    slots = subprocess.run(
        ["gsettings", "get", "org.gnome.settings-daemon.plugins.media-keys", "custom-keybindings"],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    found = {name: lines for name, lines in sections(dump)}
    found.setdefault(MEDIA_KEYS, [])
    if not any(l.startswith("custom-keybindings=") for l in found[MEDIA_KEYS]):
        found[MEDIA_KEYS].insert(0, f"custom-keybindings={slots}")

    for fname, patterns in GROUPS.items():
        rx = [re.compile(p) for p in patterns]
        out = []
        for name in sorted(found):
            if not any(r.fullmatch(name) for r in rx):
                continue
            body = [l for l in found[name] if not DROP_KEYS.match(l)]
            if body:
                out.append(f"[{name}]\n" + "\n".join(body) + "\n")
        (HERE / fname).write_text("\n".join(out))
        print(f"{fname}: {len(out)} sections", file=sys.stderr)


if __name__ == "__main__":
    main()
