#!/usr/bin/env bash
# A newly unpacked library must load without an ldconfig cache entry.
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
core=${ARLINUX_DIR:-$(cd "$repo/../.." && pwd)}
: "${ANDROID_SERIAL:?select an Arlinux Debian device}"
package=io.taowen.arlinux.debian
root=/data/user/0/$package/files/rootfs
out=$repo/build/multiarch-loader-test
mkdir -p "$out"
cat > "$out/lib.c" <<'C'
int arlinux_uncached_value(void) { return 42; }
C
cat > "$out/client.c" <<'C'
#include <stdio.h>
extern int arlinux_uncached_value(void);
int main(void) {
    int value = arlinux_uncached_value();
    printf("uncached multiarch library: %d\n", value);
    return value != 42;
}
C
(
    cd "$out"
    aarch64-linux-gnu-gcc -shared -fPIC lib.c \
        -Wl,-soname,libarlinux-uncached-test.so.1 -o libarlinux-uncached-test.so.1
    aarch64-linux-gnu-gcc client.c -L. -l:libarlinux-uncached-test.so.1 -o client
)
adb=("${ADB:-adb}" -s "$ANDROID_SERIAL")
cleanup() {
    "${adb[@]}" shell run-as "$package" rm -f \
        "$root/usr/lib/aarch64-linux-gnu/libarlinux-uncached-test.so.1" \
        "$root/tmp/arlinux-uncached-client"
}
trap cleanup EXIT
"${adb[@]}" push "$out/libarlinux-uncached-test.so.1" /data/local/tmp/
"${adb[@]}" push "$out/client" /data/local/tmp/arlinux-uncached-client
"${adb[@]}" shell run-as "$package" cp /data/local/tmp/libarlinux-uncached-test.so.1 \
    "$root/usr/lib/aarch64-linux-gnu/"
"${adb[@]}" shell run-as "$package" cp /data/local/tmp/arlinux-uncached-client "$root/tmp/"
# Bypass the runtime, environment paths and cache. The platform overlay must
# supply libc; the loader's distribution fallback must supply the test library.
"${adb[@]}" shell run-as "$package" /system/bin/env LD_PRELOAD= LD_LIBRARY_PATH= \
    "$root/usr/lib/arlinux-platform/ld-linux-aarch64.so.1" --inhibit-cache \
    --library-path "$root/usr/lib/arlinux-platform" "$root/tmp/arlinux-uncached-client"
echo 'multiarch loader fallback: PASS'
