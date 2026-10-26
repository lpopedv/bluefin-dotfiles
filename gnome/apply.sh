#!/usr/bin/env bash
# Load gnome/*.dconf into the running session's dconf database. Safe to re-run;
# dconf load only writes the keys named in the files.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install extensions before loading enabled-extensions. GNOME only loads a newly
# installed extension at the next login.
shell="$(gnome-shell --version | grep -oE '[0-9]+' | head -1)"
grep -vE '^[[:space:]]*(#|$)' "$HERE/extensions.txt" | while read -r uuid; do
    if gnome-extensions info "$uuid" &>/dev/null; then
        printf '    \033[32mok\033[0m extension %s\n' "$uuid"
    elif [[ "${1:-}" == "--dry-run" ]]; then
        printf '    \033[36mwould\033[0m install extension %s\n' "$uuid"
    else
        url="$(curl -fsS "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$shell" |
            python3 -c 'import json, sys; print(json.load(sys.stdin)["download_url"])')"
        zip="$(mktemp --suffix=.zip)"
        curl -fsSL -o "$zip" "https://extensions.gnome.org$url"
        gnome-extensions install --force "$zip"
        rm -f "$zip"
        printf '    \033[32mok\033[0m installed extension %s (log out and back in to load it)\n' "$uuid"
    fi
done


for f in "$HERE"/*.dconf; do
    if [[ "${1:-}" == "--dry-run" ]]; then
        printf '    \033[36mwould\033[0m dconf load / < %s\n' "${f##*/}"
    else
        dconf load / < "$f"
        printf '    \033[32mok\033[0m %s\n' "${f##*/}"
    fi
done

# Not in a .dconf file: the Ptyxis profile UUID differs on every install, and the
# box's podman ID changes when it is recreated.
if [[ "${1:-}" != "--dry-run" ]]; then
    uuid="$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'")"
    if [[ -n "$uuid" ]]; then
        dconf write "/org/gnome/Ptyxis/Profiles/$uuid/palette" "'mono'"
        dconf write "/org/gnome/Ptyxis/Profiles/$uuid/opacity" "0.85"
        printf '    \033[32mok\033[0m ptyxis profile %s: mono, opacity 0.85\n' "${uuid:0:8}"
        if box="$(podman inspect --format '{{.Id}}' dev 2>/dev/null)"; then
            dconf write "/org/gnome/Ptyxis/Profiles/$uuid/default-container" "'$box'"
            printf '    \033[32mok\033[0m ptyxis opens in the dev box\n'
        fi
    fi
fi
