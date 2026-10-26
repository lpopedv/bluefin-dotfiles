# Environment

The machine runs Bluefin (immutable Fedora, bootc). Work normally happens inside `dev`, an
Arch distrobox that shares `$HOME` with the host. `$CONTAINER_ID` is `dev` there and unset
on the host.

- Host commands need `distrobox-host-exec` from the box: `rpm-ostree`, `bootc`, `ujust`,
  `flatpak`, `brew`, `podman`, `distrobox`, `systemctl` (system and `--user`), `gsettings`,
  `dconf`. `docker` works directly: it talks to the host daemon.
- `sudo` on the host asks for a password: give the user the command to run with `!` instead.
- Never layer packages on the host with `rpm-ostree install`.
- Packages installed ad hoc in the box are lost when it is recreated. Lasting ones go in
  `~/Projects/bluefin-dotfiles`: pacman packages in `distrobox.ini`, runtimes and CLIs in
  `mise/.config/mise/config.toml`, host CLIs in `Brewfile`, GUI apps in `flatpak/apps.txt`.
  Project-specific tools go in the project's own `mise.toml`.
