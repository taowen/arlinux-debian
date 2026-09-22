# Arlinux Debian

Arlinux Debian is the minimal Debian reference distribution for
[arlinux-rootfs](https://github.com/taowen/arlinux-rootfs). It boots directly
into OpenCode Desktop and includes standard Debian package management, Linux
desktop accessibility, online progress speech, and optional WPS launchers.

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
- `guest/first-boot.sh` finishes package configuration on the device.
- `profile.json` launches OpenCode on the host-provided display.
- `tests/` covers installer idempotency and generated launchers.

Shared glibc, graphics, bundle, and Android integration code belongs to
`arlinux-rootfs` or the host, not this repository.

## License

GPL-3.0-or-later. Downloaded applications retain their respective licenses.
