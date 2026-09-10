# ardesk-debian

An independent Android Linux desktop application built from Ardesk's shared
Android library, process runtime and graphics stack.

Application ID: `io.taowen.ardesk.debian`. This APK has its own
Android UID, private rootfs, package database and home directory. It does not
replace the older `io.taowen.ardesk` application.

## Build

```sh
git submodule update --init --recursive
export JAVA_HOME=/path/to/jdk17
export ANDROID_HOME=/path/to/android-sdk
export HYBRIS_LIB_DIR=/path/to/libhybris/install/usr/lib/hybris
# Build the shared native graphics components once:
third_party/ardesk/tools/build.sh ndk
third_party/ardesk/tools/build.sh mesa
./build.sh
```

The output is `build/ardesk-debian-debug.apk`. `--prepare-only` builds userspace
assets; `--apk-only` assembles existing assets. For development, set
`ARDESK_DIR=/path/to/ardesk` to use a separate working checkout.
Host requirements and the application input contract are described in
[Ardesk](https://github.com/taowen/ardesk).

`product.json` selects package identity, glibc recipe and library/module paths.
`tools/seed.sh` produces the distribution rootfs. `guest/first-boot.sh` owns
package-manager configuration and desktop initialization. `native/product-policy.h`
is compiled into this product's copy of the common runtime; it is not loaded
as a runtime plugin. Android Activity, input, JNI, sessions, GPU selection,
asset installation and build orchestration are shared without copied Java.

The shared checkout is pinned as a Git submodule. Do not commit generated
rootfs archives, APKs or package caches into this source repository.

## Checks

The product uses the shared glibc 2.41 recipe. After installing and starting
its APK, run:

```sh
ARDESK_DIR=third_party/ardesk ANDROID_SERIAL=DEVICE tests/test-direct-apt-device.sh
third_party/ardesk/tests/test-product-device.py --product . --serial DEVICE
third_party/ardesk/tests/test-teapot-device.py --serial DEVICE \
  --package io.taowen.ardesk.debian --gpu turnip
```

The apt test verifies native Pre-Depends ordering, maintainer scripts, package
marks, cache-only dynamic loading and purge using disposable local packages.
Graphical screenshot checks need unobscured windows; hide the extra-key bar
with a three-finger swipe down, or start the debug Activity with
`--ez io.taowen.ardesk.extra.HIDE_EXTRA_KEYS true`.

Validated on 2026-09-10 using a Redmi K40 (Android 13, Adreno 650): fresh
bootstrap to xterm, APK update preserving home and package records, apt
Pre-Depends/cache/purge, runtime identity and nested exec, and Turnip hardware
GLX plus Wayland EGL teapot presentation and resize. These checks cover this
recipe; they do not certify every application or future distribution update.
