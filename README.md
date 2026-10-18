# Arlinux Debian

Arlinux Debian is the minimal Debian reference distribution for
[arlinux-rootfs](https://github.com/taowen/arlinux-rootfs). It boots directly
into the Apps launcher with all startup packages included,
and includes standard Debian package management, Linux
desktop accessibility, online progress speech, and optional WPS launchers.
The Apps menu includes OpenCode: its first launch downloads and installs the
pinned official desktop package. The AI voice entry uses the same installer.
First-time installation requires internet and may take several minutes; later
launches use the installed app. It includes the Wayland-native foot terminal. Codex CLI is optional and is
installed by the user inside the running Debian instance, not bundled in the
rootfs. In foot, run `arlinux-install-codex` and then `codex login`.

This repository contains only the Linux distribution recipe. It does not
contain or require the Android host source.

Builds and releases follow the [canonical build and release guide](https://github.com/taowen/arlinux-rootfs/blob/main/docs/BUILD.md). This repository provides a distribution recipe and does not maintain a separate build entry point.

## Repository layout

- `rootfs.lock.json` pins the Debian suite and bootstrap inputs.
- `tools/seed.sh` creates the foreign-architecture rootfs seed.
- `guest/build-desktop.sh` installs desktop packages and Python dependencies in a disposable Linux/WSL QEMU chroot.
- `guest/first-boot.sh` writes device-local configuration without network access.
- `guest/install-codex.sh` installs Codex CLI on the device on request.
- `profile.json` keeps the desktop session on the host-provided display alive.
- `tests/` covers installer idempotency and generated launchers.

Package installation runs on the Linux/WSL build host. First boot only writes device-local settings.
Thunar and Mousepad are included for local file and text work. Online AI and
speech services still require internet; optional applications are not preinstalled.

Shared runtime, graphics, bundle, and Android integration code belongs to
`arlinux-rootfs` or the host, not this repository.

## License

GPL-3.0-or-later. Downloaded applications retain their respective licenses.
