# Arlinux Debian

Debian rootfs recipe for [arlinux-rootfs](https://github.com/taowen/arlinux-rootfs).
It produces an AArch64 Debian bundle; it is not an Android application and has
no host-specific build entry point.

From an `arlinux-rootfs` checkout:

```bash
./build.sh build debian
./build.sh verify out/debian.arlinux-rootfs
```

`rootfs.lock.json` pins the Debian suite, mirror, debootstrap variant and base
packages. `tools/seed.sh` creates the root filesystem, `guest/` contains files
installed into the guest, and `native/product-policy.h` contains the small
distribution-specific compatibility policy. Shared glibc, GPU and bundle logic
belongs to `arlinux-rootfs`.
