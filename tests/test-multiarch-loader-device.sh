#!/usr/bin/env bash
# A newly unpacked library must load without an ldconfig cache entry.
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
core=${ARDESK_DIR:-$repo/third_party/ardesk}
: "${ANDROID_SERIAL:?select an Ardesk Debian device}"
package=io.taowen.ardesk.debian
root=/data/user/0/$package/files/rootfs
out=$repo/build/multiarch-loader-test
mkdir -p "$out"
cat > "$out/lib.c" <<'C'
int ardesk_uncached_value(void) { return 42; }
C
cat > "$out/client.c" <<'C'
#include <stdio.h>
extern int ardesk_uncached_value(void);
int main(void) {
    int value = ardesk_uncached_value();
    printf("uncached multiarch library: %d\n", value);
    return value != 42;
}
C
builder=$("$core/tools/ensure-glibc-builder.sh")
podman run --rm --userns=keep-id --volume "$out:/work:z" --workdir /work \
    "$builder" sh -eu -c '
    aarch64-linux-gnu-gcc -shared -fPIC lib.c \
        -Wl,-soname,libardesk-uncached-test.so.1 -o libardesk-uncached-test.so.1
    aarch64-linux-gnu-gcc client.c -L. -l:libardesk-uncached-test.so.1 -o client
    '
adb=("${ADB:-adb}" -s "$ANDROID_SERIAL")
cleanup() {
    "${adb[@]}" shell run-as "$package" rm -f \
        "$root/usr/lib/aarch64-linux-gnu/libardesk-uncached-test.so.1" \
        "$root/tmp/ardesk-uncached-client"
}
trap cleanup EXIT
"${adb[@]}" push "$out/libardesk-uncached-test.so.1" /data/local/tmp/
"${adb[@]}" push "$out/client" /data/local/tmp/ardesk-uncached-client
"${adb[@]}" shell run-as "$package" cp /data/local/tmp/libardesk-uncached-test.so.1 \
    "$root/usr/lib/aarch64-linux-gnu/"
"${adb[@]}" shell run-as "$package" cp /data/local/tmp/ardesk-uncached-client "$root/tmp/"
# Bypass the runtime, environment paths and cache. The platform overlay must
# supply libc; the loader's distribution fallback must supply the test library.
"${adb[@]}" shell run-as "$package" /system/bin/env LD_PRELOAD= LD_LIBRARY_PATH= \
    "$root/usr/lib/ardesk-platform/ld-linux-aarch64.so.1" --inhibit-cache \
    --library-path "$root/usr/lib/ardesk-platform" "$root/tmp/ardesk-uncached-client"
echo 'multiarch loader fallback: PASS'
