# bluefin-dotfiles

Dotfiles for [Bluefin](https://projectbluefin.io) (`bluefin-dx`, GNOME), managed with
[GNU Stow](https://www.gnu.org/software/stow/). The terminal-side configs come from the
Arch/Hyprland repo; everything desktop-specific is rebuilt for GNOME.

## Where things go on Bluefin

| What | Where | Why |
|------|-------|-----|
| Dev environment | `distrobox.ini` | An Arch box named `dev` that shares `$HOME` with the host. Editor, git UI and cloud CLIs are `pacman` packages in it. Upgraded weekly by a user timer. |
| Host-only tools | `Brewfile` (Homebrew) | Just `stow`, `gh` and `eza`. |
| GUI apps | `flatpak/apps.txt` | Bluefin's preferred route. The file lists only what the image doesn't ship (Zen, Obsidian, Telegram). |
| Language runtimes, LSPs, herdr, Claude Code | `mise/` | Installed inside the box (compiled against Arch), pinned per user and locked in `mise.lock`. Project-specific ones belong in the project's own `mise.toml`. |
| Claude Code settings | `claude-settings/` | Merged into `~/.claude/settings.json` by `apply.py`, not stowed: Claude Code and its integrations write to that file, and their keys stay out of the repo. |
| GNOME settings | `gnome/*.dconf` | Replayed with `dconf load`. |
| System DNS | `system/etc/` | Dropped into `/etc` (writable and persistent on Bluefin) by `bootstrap.sh`. |
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
docker group check, `dconf load`, DNS-over-TLS drop-ins (sudo), Zen as default browser, user
tmpfiles. After pulling changes, `dotup` (zsh function) pulls and re-runs it.

## Packages

| Package   | Configures |
|-----------|------------|
| `claude`  | Claude Code hooks, theme, English-learning skills (settings: `claude-settings/`) |
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
  `Super+1..4` workspaces, `Shift+Super+1..4` move window, app-switch shortcuts cleared) and
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
at login. `~/.cache` is **not** tmpfs here (that needs root and an image change), and Zen
and VS Code keep their own profiles on disk.

## DNS

`system/etc/` makes systemd-resolved use Cloudflare over TLS (1.1.1.1 / 1.0.0.1, IPv4 and IPv6),
DNSSEC validated upstream by Cloudflare and LLMNR/mDNS off. A NetworkManager drop-in stops it
pushing the DHCP-advertised DNS. It is opportunistic: on a network that blocks port 853 (hotel or
airport wi-fi with a login page) queries go to Cloudflare unencrypted, so that network can see
them; anything that can block 853 can force that downgrade. The name you visit still shows in
TLS SNI (no ECH). Undo steps are in `bootstrap.sh`.

## Known gaps

- The Arch repo's other system hardening (nftables, sysctl, Secure Boot, tmpfs `/var/log`)
  is not ported: on Bluefin that is image-level work (`bootc`, [finpilot](https://github.com/projectbluefin/finpilot)).
