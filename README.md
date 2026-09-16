# arlinux-debian

An independent Android Linux desktop application built from Arlinux's shared
Android library, process runtime and graphics stack.

Application ID: `io.taowen.arlinux.debian`. This APK has its own
Android UID, private rootfs, package database and home directory. It does not
replace the older `io.taowen.arlinux` application.

## Build

```sh
git -C /path/to/arlinux submodule update --init --recursive
cd /path/to/arlinux
export JAVA_HOME=/path/to/jdk21
export ANDROID_HOME=/path/to/android-sdk
export HYBRIS_LIB_DIR=/path/to/libhybris/install/usr/lib/hybris
# Build the shared native graphics components once:
tools/build.sh ndk
tools/build.sh mesa
distributions/debian/build.sh
```

The output is `distributions/debian/build/arlinux-debian-debug.apk`. `--prepare-only` builds userspace
assets; `--apk-only` assembles existing assets. For development, set
`ARLINUX_DIR=/path/to/arlinux` to use a separate working checkout.
Host requirements and the application input contract are described in
[Arlinux](https://github.com/taowen/arlinux).

`product.json` selects package identity, glibc recipe and library/module paths.
`tools/seed.sh` produces the distribution rootfs. `guest/first-boot.sh` owns
package-manager configuration and desktop initialization. `native/product-policy.h`
is compiled into this product's copy of the common runtime; it is not loaded
as a runtime plugin. Android Activity, input, JNI, sessions, GPU selection,
asset installation and build orchestration are shared without copied Java.

This repository is pinned by the parent Arlinux checkout under
`distributions/debian`; it does not embed another copy of Arlinux. Do not commit
generated rootfs archives, APKs or package caches into this source repository.

## Checks

The product uses the shared glibc 2.41 recipe. After installing and starting
its APK, run:

```sh
ANDROID_SERIAL=DEVICE distributions/debian/tests/test-direct-apt-device.sh
ANDROID_SERIAL=DEVICE distributions/debian/tests/test-multiarch-loader-device.sh
tests/test-product-device.py --product distributions/debian --serial DEVICE
tests/test-teapot-device.py --serial DEVICE \
  --package io.taowen.arlinux.debian --gpu turnip
```

The apt test verifies native Pre-Depends ordering, maintainer scripts, package
marks, cache-only dynamic loading and purge using disposable local packages.
The multiarch test loads a new library with the cache disabled, checking the
fallback needed by maintainer scripts before the ldconfig trigger runs.
Audio playback uses Debian's ALSA pulse plugin and the APK's PulseAudio-to-AAudio
service. System fragments in `/etc/alsa/conf.d/99-arlinux-pulse.conf` and
`/etc/pulse/client.conf.d/arlinux.conf` provide defaults; user audio configuration
is preserved. Android media volume controls the final speaker output.
Validated on X300 on 2026-09-12: xterm `sudo apt install -y blender`
installed all 345 packages, including the first shared-mime-info configuration;
dpkg audit, apt dependency checks and both loader/apt regressions passed.
Graphical screenshot checks need unobscured windows; hide the extra-key bar
with a three-finger swipe down, or start the debug Activity with
`--ez io.taowen.arlinux.extra.HIDE_EXTRA_KEYS true`.

Validated on 2026-09-10 using a Redmi K40 (Android 13, Adreno 650): fresh
bootstrap to xterm, APK update preserving home and package records, apt
Pre-Depends/cache/purge, runtime identity and nested exec, and Turnip hardware
GLX plus Wayland EGL teapot presentation and resize. These checks cover this
recipe; they do not certify every application or future distribution update.

## WPS shortcuts

Run `./wps-writer`, `./wps-spreadsheet`, `./wps-presentation` or `./wps-pdf`
from the initial terminal. The same names are available on PATH, and four
`.desktop` entries are installed for application menus. The first launch
installs dependencies and downloads WPS; later launches use the installed copy.
Pass a document filename after the command to open it.

The product owns `guest/wps-*.sh`, its download lock (`wps-downloads.tsv`) and
font aliases. Downloads use the previously tested WPS 11.1.0.11720 ARM64 build
from the Pi-Apps mirror plus WPS formula fonts, all checked with SHA-256.
WPS is downloaded on demand and is not bundled in the APK. Existing Office
settings are preserved. The local-office preset disables the optional cloud
helper, which is incompatible with this runtime. Failed downloads or installations can be retried by
running the shortcut again. APK updates refresh shortcuts without replacing
home or package databases.

Debian installs the vendor packages and legacy codec dependencies with apt.

Launcher checks: `python3 tests/test-wps-launcher.py`.

Validated on Redmi K40 / Android 13 on 2026-09-10: on-device downloads and
checksums, apt installation with vendor maintainer scripts, all four component
windows, a local document with spaces in its filename, and APK updates preserving
package records and the stopped application's Office.conf. The final APK's
terminal shortcut was also exercised. This covers local startup and document
opening, not cloud services or every editing feature.
