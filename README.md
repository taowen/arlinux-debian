# Arlinux Debian

Arlinux Debian is the minimal Debian reference distribution for
[arlinux-rootfs](https://github.com/taowen/arlinux-rootfs). It boots directly
into an offline desktop with all startup packages included,
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

From an `arlinux-rootfs` checkout:

```bash
./build.sh build debian
./build.sh verify out/debian.zip
```

The build produces `out/debian.zip`. See the rootfs project's
[distribution authoring guide](https://github.com/taowen/arlinux-rootfs/blob/main/docs/DISTRIBUTION-AUTHORING.md)
for the interface implemented here.

## Repository layout

- `rootfs.lock.json` pins the Debian suite and bootstrap inputs.
- `tools/seed.sh` creates the foreign-architecture rootfs seed.
- `guest/build-desktop.sh` installs desktop packages and Python dependencies in a disposable Android build instance.
- `guest/first-boot.sh` writes device-local configuration without network access.
- `guest/install-codex.sh` installs Codex CLI on the device on request.
- `profile.json` keeps the desktop session on the host-provided display alive.
- `tests/` covers installer idempotency and generated launchers.

The normal Linux build creates a foreign seed without QEMU or chroot. Use
`arlinux-rootfs/tools/device-desktop.py prepare` to create a preparation ZIP,
install it in a fresh build-only Android instance, then stop and export that
instance's rootfs. `device-desktop.py seal` turns the snapshot into an offline
ZIP, removing device-specific state. See the rootfs distribution authoring guide.
Package installation and mirror downloads run natively on the phone; the Linux
host only assembles and compresses files. Never export a personal instance.
Thunar and Mousepad are included for local file and text work. Online AI and
speech services still require internet; optional applications are not preinstalled.

Shared runtime, graphics, bundle, and Android integration code belongs to
`arlinux-rootfs` or the host, not this repository.

## License

GPL-3.0-or-later. Downloaded applications retain their respective licenses.
