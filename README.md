# bluefin-dotfiles

Dotfiles for [Bluefin](https://projectbluefin.io) (`bluefin-dx`, GNOME), managed with
[GNU Stow](https://www.gnu.org/software/stow/). The terminal-side configs come from the
Arch/Hyprland repo; everything desktop-specific is rebuilt for GNOME.

## Where things go on Bluefin

| What | Where | Why |
|------|-------|-----|
| Dev environment | `distrobox.ini` | An Arch box named `dev` that shares `$HOME` with the host. Editor, git UI and cloud CLIs are `pacman` packages in it. Upgraded weekly by a user timer. |
| Host-only tools | `Brewfile` (Homebrew) | Just `stow`, `gh` and `eza`. |
| GUI apps | `flatpak/apps.txt` | Bluefin's preferred route. The file lists only what the image doesn't ship (Zen, Telegram, Gear Lever). |
| Language runtimes, LSPs, herdr, Claude Code | `mise/` | Installed inside the box (compiled against Arch), pinned per user and locked in `mise.lock`. Project-specific ones belong in the project's own `mise.toml`. |
| Claude Code settings | `claude-settings/` | Merged into `~/.claude/settings.json` by `apply.py`, not stowed: Claude Code and its integrations write to that file, and their keys stay out of the repo. |
| GNOME settings | `gnome/*.dconf` | Replayed with `dconf load`. |
| System config | `system/etc/`, `system/kargs.txt` | Files copied into `/etc` (writable, kept across image updates) and kernel arguments added with `rpm-ostree kargs`, both by `bootstrap.sh`. No custom image needed. |
| Everything else | stow packages | One directory per tool, mirroring `$HOME`. |

Nothing is layered with `rpm-ostree`.

## Setting up a fresh install

```sh
git clone <this repo> ~/Projects/bluefin-dotfiles
cd ~/Projects/bluefin-dotfiles
./bootstrap.sh --dry-run          # read what it would do
./bootstrap.sh
```

Put your git identity (name, email, signing) in `~/.config/git/identity`; `git/.gitconfig`
includes it and it is never committed.

Ptyxis opens new terminals in the box; the host is in its container menu. Start Claude Code
and herdr from the box, so they and the commands they run see its tools. `nvim` is
exported to `~/.local/bin`, so `EDITOR` and `git commit` work on the host too. Docker is the
host's: the box's `/var/run/docker.sock` is the host socket, so `docker` there controls the
host daemon (nothing runs Docker inside Docker). That socket and the shared `$HOME` mean the
box is a convenience, not a sandbox.

`distrobox.ini` is only read when the box is created. After changing it: `distrobox rm -f dev`,
then `bootstrap.sh` (everything worth keeping lives in `$HOME`).

`bootstrap.sh` order: brew bundle, flatpaks, stow (existing files are moved to
`~/.dotfiles-backup/<timestamp>`, never deleted), Claude Code settings merge, create the `dev`
box if missing, `mise install --locked` inside it, weekly box upgrade timer, login shell to zsh,
docker group check, `dconf load`, Zen as default browser, `/etc` files (sudo, restarting
the services they belong to), tmpfs mount for NetworkManager's state, firewall zone, tailscaled off, kernel
arguments, Secure Boot check, user tmpfiles.
After pulling changes, `dotup` (zsh function) pulls and re-runs it.

## Packages

| Package   | Configures |
|-----------|------------|
| `claude`  | Claude Code hooks, theme, English-learning skills (settings: `claude-settings/`) |
| `flatpak-overrides` | Flatpak permission overrides (`flatpak override --user`, as files) |
| `git`     | Identity include and editor |
| `herdr`   | Agent multiplexer |
| `lazygit` | Git TUI |
| `mise`    | Toolchains: node, bun, herdr, claude, typescript, biome, LSPs (run in the box) |
| `nvim`    | Neovim (`vim.pack`, needs 0.12+) |
| `ptyxis`  | The `Mono` palette for Bluefin's own terminal (applied by `gnome/apply.sh`, with opacity 0.85) |
| `systemd` | User tmpfiles that keep traces in RAM, weekly box upgrade timer |
| `zsh`     | Shell, prompt, aliases, tmpfs history |

Stow from the repo root: `stow --restow <pkg>` / `stow -D <pkg>`. `.stowrc` sets
`--no-folding` (directories stay real, only files are linked) and `--target=$HOME`.

## GNOME

`gnome/` holds three dconf files and two scripts:

- `keybindings.dconf`: window and workspace shortcuts (`Super+q` close, `Super+f` maximize,
  `Super+Enter` terminal, `Super+b` Zen, `Super+1..4` workspaces, `Shift+Super+1..4` move window, app-switch shortcuts cleared) and
  the custom launchers. `custom0`-`custom6` are Bluefin's own defaults, kept so the file is
  self-contained; add yours as new slots.
- `desktop.dconf`: dark mode, button layout, `br` keyboard, touchpad, privacy, power, Ptyxis.
- `shell.dconf`: dock favorites, enabled extensions and their settings (blur-my-shell,
  caffeine, dash-to-dock, search-light with `Super+Space`).

`gnome/apply.sh` loads them; `gnome/capture.py` re-dumps the live settings into those files
(dropping window sizes, monitor connectors and other per-machine keys). Workflow: change a
setting in GNOME, run `python3 -I gnome/capture.py`, review `git diff`, commit.

Most enabled extensions ship with Bluefin. The ones it doesn't (Tactile) are listed in
`gnome/extensions.txt`; `apply.sh` installs any missing one from extensions.gnome.org into
`~/.local/share/gnome-shell/extensions` (picked up at the next login). Add a new one there
and to `enabled-extensions`.

## Amnesia (tmpfs)

Shell and REPL histories go to `$XDG_RUNTIME_DIR` (`zsh/.zshrc`), and
`systemd/.config/user-tmpfiles.d/traces.conf` redirects state files (nvim shada/swap, lazygit,
Claude Code prompt history, herdr logs) into RAM and wipes Nautilus metadata and recent files
at login. System-wide, NetworkManager's state is in RAM too (see Hardening); the journal and
`/var/log` stay persistent, as Bluefin sets them. `~/.cache` is **not** tmpfs here (that needs root and an image change), and Zen
and VS Code keep their own profiles on disk.

## DNS

`system/etc/` makes systemd-resolved use Cloudflare over TLS (1.1.1.1 / 1.0.0.1, IPv4 and IPv6),
DNSSEC validated upstream by Cloudflare. A NetworkManager drop-in stops it
pushing the DHCP-advertised DNS. It is strict: nothing falls back to plain DNS, so a network
can't downgrade it, and one that blocks port 853 (hotel or airport wi-fi with a login page)
resolves nothing. To reach a login page, send that link's queries to the network's own DNS
until the next `resolvectl revert`:

```sh
iface=$(ip route show default | awk '{print $5; exit}')
sudo resolvectl dns "$iface" "$(ip route show default | awk '{print $3; exit}')"
sudo resolvectl dnsovertls "$iface" no
sudo resolvectl domain "$iface" '~.'
# logged in:
sudo resolvectl revert "$iface"
```

LLMNR is off (it asks the LAN for unknown names and trusts whoever answers); avahi still
resolves `.local`. The name you visit still shows in TLS SNI (no ECH).

## Hardening

Ported from the Arch repo to Bluefin's own tools, as drop-ins next to the image's files. Nothing
replaces or masks a file from the image, and nothing overrides a setting Bluefin made on purpose
(persistent journal, chrony, `/tmp` cleanup, Wi-Fi MAC per network). Everything is in `system/`:

- **Firewall**: firewalld zone `stealth` (default) drops everything unsolicited without
  replying, except GSConnect (1714-1764), mDNS and the ICMPv6 and DHCPv6 that IPv6 needs.
  Bluefin's default zone accepts every port above 1024. Docker publishes ports on 127.0.0.1
  unless a compose file names another address (`docker/daemon.json`); existing containers keep
  their ports until recreated.
- **Kernel**: `sysctl.d/99-hardening.conf` (io_uring off, ptrace needs sudo, no ICMP
  redirects...) and `kargs.txt` (memory zeroed on free, no
  vsyscall). Only what Fedora's kernel doesn't already do. Kernel arguments apply from the next
  boot.
- **Secure Boot**: not automatic. Run `ujust enroll-secure-boot-key`, reboot to enroll Bluefin's
  key (its kernel modules are signed with it), then enable Secure Boot in the firmware. Fedora's
  kernel then also enforces lockdown (integrity mode).
- **Traces**: core dumps off; NetworkManager's leases and seen access points live in RAM.
- **Network identity**: new MAC on Ethernet, DHCP IDs and IPv6 address every boot; hostname never
  sent to DHCP servers.
- **Unused services**: `tailscaled` ships with the image and is disabled (`bootstrap.sh`), so
  nothing listens on its port. `sudo systemctl enable --now tailscaled` brings it back.
- **Flatpak permissions**: user overrides in `flatpak-overrides/`. Telegram gets the GPU but
  no other device (camera included).

To undo a file, delete it from `/etc` and restart its service; to drop a kernel argument,
`sudo rpm-ostree kargs --delete=<arg>`. If you re-enable Tailscale, `tailscale0` lands in the
stealth zone too.
