#!/usr/bin/env bash
# Bring a Bluefin install up to match this repo. Idempotent: every step checks
# its own state first, so it is safe to re-run (`dotup` does).
#
#   ./bootstrap.sh              apply everything
#   ./bootstrap.sh --dry-run    print what would change, touch nothing
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY=1 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

STOW_PACKAGES=(claude flatpak-overrides git herdr lazygit mise nvim ptyxis systemd zsh)

log()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32mok\033[0m %s\n' "$*"; }
warn() { printf '    \033[33m!\033[0m %s\n' "$*"; }
plan() { printf '    \033[36mwould\033[0m %s\n' "$*"; }

run() {
    if (( DRY )); then plan "$*"; else "$@"; fi
}

read_list() { grep -vE '^[[:space:]]*(#|$)' "$1"; }

if [[ $EUID -eq 0 ]]; then
    echo "Run as your normal user, not root. sudo is called where needed." >&2
    exit 1
fi

if ! grep -q '^ID=bluefin' /etc/os-release; then
    warn "this is not Bluefin; the steps below assume it"
fi

(( DRY )) && log "DRY RUN - nothing will be modified"

log "Homebrew"
if ! command -v brew >/dev/null; then
    [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
if ! command -v brew >/dev/null; then
    echo "brew not found; Bluefin ships it, check 'ujust' or https://brew.sh" >&2
    exit 1
fi
if brew bundle check --file "$DOTFILES/Brewfile" >/dev/null 2>&1; then
    ok "Brewfile satisfied"
else
    run brew bundle --file "$DOTFILES/Brewfile"
fi

log "Flatpaks"
mapfile -t want < <(read_list "$DOTFILES/flatpak/apps.txt")
mapfile -t missing < <(comm -23 \
    <(printf '%s\n' "${want[@]}" | sort -u) \
    <(flatpak list --app --columns=application | sort -u))
if (( ${#missing[@]} )); then
    run flatpak install -y --noninteractive flathub "${missing[@]}"
else
    ok "all ${#want[@]} already installed"
fi

log "Dotfiles"
cd "$DOTFILES"
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
moved=0
# stow refuses to replace a regular file, and a fresh Bluefin home already has
# ~/.zshrc, ~/.gitconfig... Those are moved aside (never deleted) first.
for pkg in "${STOW_PACKAGES[@]}"; do
    while IFS= read -r -d '' f; do
        rel="${f#"$pkg"/}"
        target="$HOME/$rel"
        if [[ -e "$target" || -L "$target" ]] && [[ "$(readlink -f "$target")" != "$DOTFILES/$f" ]]; then
            run mkdir -p "$backup/$(dirname "$rel")"
            run mv "$target" "$backup/$rel"
            moved=$((moved + 1))
        fi
    done < <(find "$pkg" -type f -print0)
done
(( moved )) && warn "$moved existing file(s) moved to $backup"

for pkg in "${STOW_PACKAGES[@]}"; do
    if (( DRY )) && ! command -v stow >/dev/null; then
        plan "stow --restow $pkg (stow arrives with the Brewfile)"
    elif (( DRY )); then
        if stow -n --restow "$pkg" >/dev/null 2>&1; then ok "$pkg"; else warn "$pkg would conflict"; fi
    elif stow --restow "$pkg" 2>/dev/null; then
        ok "$pkg"
    else
        warn "$pkg conflicts with an existing file - resolve, then: stow --restow $pkg"
    fi
done

log "Claude Code settings"
# Merged, not stowed: Claude Code and its integrations write to that file.
if (( DRY )); then
    python3 -I "$DOTFILES/claude-settings/apply.py" --dry-run
else
    python3 -I "$DOTFILES/claude-settings/apply.py"
fi

log "Dev box"
# The editor, herdr and language runtimes live in the box; the host only creates it.
if ! command -v distrobox >/dev/null; then
    warn "distrobox not found; Bluefin ships it"
elif distrobox list --no-color 2>/dev/null | awk -F'|' 'NR>1 {gsub(/ /,"",$2); print $2}' | grep -qx dev; then
    ok "dev box exists (recreate: distrobox rm -f dev, then re-run)"
else
    run distrobox assemble create --file "$DOTFILES/distrobox.ini"
fi

log "Toolchain"
# Runs inside the box so runtimes are compiled against Arch, not the host.
run distrobox enter dev -- mise install --locked

log "Dev box upgrades"
if systemctl --user is-enabled --quiet distrobox-upgrade.timer; then
    ok "weekly timer enabled"
else
    run systemctl --user daemon-reload
    run systemctl --user enable --now distrobox-upgrade.timer
fi

log "Login shell"
if [[ "$(getent passwd "$USER" | cut -d: -f7)" == /usr/bin/zsh ]]; then
    ok "zsh"
else
    run sudo usermod -s /usr/bin/zsh "$USER"
fi

log "Containers"
if id -nG | tr ' ' '\n' | grep -qx docker; then
    ok "in the docker group"
else
    warn "not in the docker group: run 'ujust dx-group', then log out and back in"
fi

log "GNOME"
if (( DRY )); then
    "$DOTFILES/gnome/apply.sh" --dry-run
else
    "$DOTFILES/gnome/apply.sh"
fi

log "Default browser"
if [[ "$(xdg-settings get default-web-browser 2>/dev/null)" == app.zen_browser.zen.desktop ]]; then
    ok "Zen"
else
    # Bluefin defaults to Firefox; this writes the override to ~/.config/mimeapps.list.
    run xdg-settings set default-web-browser app.zen_browser.zen.desktop
fi

log "System config"
# /etc is writable and kept across image updates. To undo a file: delete it from
# /etc and restart the service it belongs to (listed below).
# Some /etc directories (firewalld) are root-only, so comparing them needs sudo.
# Returns 0 if identical, 1 if different or missing, 2 if it can't tell (dry run).
same() {
    local dir="${2%/*}"
    until [[ -e "$dir" ]]; do dir="${dir%/*}"; done
    if [[ -r "$dir" && -x "$dir" ]]; then cmp -s "$1" "$2" || return 1
    elif (( DRY )); then return 2
    else sudo cmp -s "$1" "$2" || return 1
    fi
}
changed=()
while IFS= read -r -d '' f; do
    rel="${f#"$DOTFILES"/system/etc/}"
    rc=0; same "$f" "/etc/$rel" || rc=$?
    if (( rc == 0 )); then
        ok "$rel"
    elif (( rc == 2 )); then
        plan "compare $rel (root-only, needs sudo)"
    else
        # -Z: SELinux label from policy, not inherited from the source file.
        run sudo install -DZm644 "$f" "/etc/$rel"
        changed+=("$rel")
    fi
done < <(find "$DOTFILES/system/etc" -type f -print0 | sort -z)
touched() {
    local rel
    for rel in "${changed[@]}"; do [[ "$rel" == "$1"* ]] && return 0; done
    return 1
}
touched systemd/resolved.conf.d && run sudo systemctl restart systemd-resolved
touched NetworkManager/ && run sudo systemctl reload NetworkManager
touched sysctl.d/ && run sudo systemctl restart systemd-sysctl
touched firewalld/ && run sudo firewall-cmd --quiet --reload
# Checked against the daemon's start time, not `touched`, so a restart that had to
# wait is still reported on later runs. A restart stops running containers.
started="$(systemctl show docker -P ActiveEnterTimestamp)"
if touched docker/ || { [[ -f /etc/docker/daemon.json && -n "$started" ]] &&
        (( $(stat -c %Y /etc/docker/daemon.json) > $(date -d "$started" +%s) )); }; then
    if [[ -z "$(docker ps -q 2>/dev/null)" ]]; then
        run sudo systemctl restart docker
    else
        warn "containers running: stop them, then 'sudo systemctl restart docker' to apply daemon.json"
    fi
fi
touched systemd/system/ && run sudo systemctl daemon-reload
if touched systemd/resolved.conf.d && (( ! DRY )); then
    sleep 2
    if resolvectl query cloudflare.com >/dev/null 2>&1; then
        ok "resolving through DNS-over-TLS"
    else
        warn "DNS lookup failed"
    fi
fi

log "Volatile /var"
# Mounted from the next boot, not over the state the running services hold open.
for f in "$DOTFILES"/system/etc/systemd/system/*.mount; do
    unit="${f##*/}"
    if systemctl is-enabled --quiet "$unit" 2>/dev/null; then
        ok "$unit"
    else
        run sudo systemctl enable "$unit"
        warn "$unit takes effect at the next boot"
    fi
done

log "Firewall"
if [[ "$(firewall-cmd --get-default-zone 2>/dev/null)" == stealth ]]; then
    ok "default zone: stealth"
else
    run sudo firewall-cmd --quiet --set-default-zone=stealth
fi

log "Unused services"
# Ships with the image and starts by default; disabling it is kept in /etc.
if systemctl is-enabled --quiet tailscaled 2>/dev/null; then
    run sudo systemctl disable --now tailscaled
else
    ok "tailscaled disabled"
fi

log "Kernel arguments"
# Applied to a new deployment: they take effect at the next boot.
current=" $(rpm-ostree kargs) "
missing=()
while IFS= read -r arg; do
    [[ "$current" == *" $arg "* ]] || missing+=("--append-if-missing=$arg")
done < <(read_list "$DOTFILES/system/kargs.txt")
if (( ${#missing[@]} )); then
    run sudo rpm-ostree kargs "${missing[@]}"
    warn "reboot to boot with the new kernel arguments"
else
    ok "all present"
fi

log "Secure Boot"
# With Secure Boot on, Fedora's kernel also enforces lockdown (integrity mode).
if mokutil --sb-state 2>/dev/null | grep -q enabled; then
    ok "enabled"
else
    warn "disabled: run 'ujust enroll-secure-boot-key', reboot to enroll the key, then enable Secure Boot in the firmware"
fi

log "Trace retention"
if systemctl --user is-enabled --quiet systemd-tmpfiles-setup.service; then
    ok "user tmpfiles applied at login"
else
    run systemctl --user enable systemd-tmpfiles-setup.service
fi
run systemd-tmpfiles --user --create

log "Done"
