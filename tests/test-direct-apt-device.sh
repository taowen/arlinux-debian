#!/usr/bin/env bash
# Run after installing the current APK. Uses two disposable test packages.
# Checks native apt ordering, maintainer scripts, real cache lookup, and purge.
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${ANDROID_SERIAL:?select a device with the current Arlinux APK}"
export ANDROID_SERIAL
adb_bin="${ADB:-adb}"
adb=("$adb_bin" -s "$ANDROID_SERIAL")
export PACKAGE=io.taowen.arlinux.debian
package=$PACKAGE
core="${ARLINUX_DIR:-$repo_dir/third_party/arlinux}"
files="/data/user/0/$package/files"
root="$files/rootfs"
out="$repo_dir/build/direct-apt-test"
mkdir -p "$out/lib/DEBIAN" "$out/lib/usr/lib/arlinux-apt-test" \
    "$out/lib/etc/ld.so.conf.d" "$out/client/DEBIAN" \
    "$out/client/usr/lib/arlinux-apt-test"
cat > "$out/library.c" <<'C'
int arlinux_apt_test(void) { return 42; }
C
cat > "$out/client.c" <<'C'
#include <stdio.h>
extern int arlinux_apt_test(void);
int main(void) {
    int result = arlinux_apt_test();
    printf("cache-only value=%d\n", result);
    return result == 42 ? 0 : 1;
}
C
cat > "$out/lib/DEBIAN/control" <<'CONTROL'
Package: arlinux-apt-test-lib
Version: 1.0
Architecture: arm64
Maintainer: Arlinux <test@localhost>
Description: Disposable Arlinux ldconfig test library
CONTROL
cat > "$out/client/DEBIAN/control" <<'CONTROL'
Package: arlinux-apt-test-client
Version: 1.0
Architecture: arm64
Pre-Depends: arlinux-apt-test-lib (= 1.0)
Depends: libc6
Maintainer: Arlinux <test@localhost>
Description: Disposable Arlinux cache and Pre-Depends test
CONTROL
printf '/usr/lib/arlinux-apt-test\n' > "$out/lib/etc/ld.so.conf.d/arlinux-apt-test.conf"
printf 'activate-noawait ldconfig\n' > "$out/lib/DEBIAN/triggers"
cat > "$out/lib/DEBIAN/postinst" <<'SH'
#!/bin/sh
set -eu
# Match Chrome's maintainer script: this variable must not have acquired
# the export attribute from apt's environment.
test "${APT_CONFIG+x}" != x
APT_CONFIG="$(command -v apt-config)"
eval $("$APT_CONFIG" shell sources 'Dir::Etc::sourceparts/d')
test -d "$sources"
ldconfig -r "$DPKG_ROOT"
ldconfig -p | grep 'libarlinux-apt-test.so.1'
SH
cat > "$out/lib/DEBIAN/postrm" <<'SH'
#!/bin/sh
set -eu
ldconfig
SH
cat > "$out/client/DEBIAN/preinst" <<'SH'
#!/bin/sh
set -eu
test "$(dpkg-query -W -f '${Status}' arlinux-apt-test-lib)" = 'install ok installed'
SH
cat > "$out/client/DEBIAN/postinst" <<'SH'
#!/bin/sh
set -eu
/usr/lib/arlinux-apt-test/cache-client
SH
chmod 755 "$out/lib/DEBIAN/postinst" "$out/lib/DEBIAN/postrm" \
    "$out/client/DEBIAN/preinst" "$out/client/DEBIAN/postinst"
builder="$("$core/tools/ensure-glibc-builder.sh")"
podman run --rm --userns=keep-id --volume "$repo_dir:/work:z" \
    --workdir /work/build/direct-apt-test "$builder" sh -eu -c '
    aarch64-linux-gnu-gcc -shared -fPIC library.c -Wl,-soname,libarlinux-apt-test.so.1 \
        -o lib/usr/lib/arlinux-apt-test/libarlinux-apt-test.so.1.0
    aarch64-linux-gnu-gcc client.c -Llib/usr/lib/arlinux-apt-test \
        -l:libarlinux-apt-test.so.1.0 -o client/usr/lib/arlinux-apt-test/cache-client
    dpkg-deb --root-owner-group --build lib lib.deb
    dpkg-deb --root-owner-group --build client client.deb
'
for deb in lib client; do
    "${adb[@]}" push "$out/$deb.deb" "/data/local/tmp/arlinux-apt-$deb.deb"
    "${adb[@]}" shell run-as "$package" cp "/data/local/tmp/arlinux-apt-$deb.deb" "files/$deb.deb"
done
"$core/tools/guest-desk.sh" exec "$root/bin/sh" -s <<'SH'
set -eu
root=$BIONICX_ROOTFS
files=$BIONICX_FILES
# No bxapt, explicit apt config, or virtual-root environment from the caller.
[ "$(id -u)" != 0 ]
# Explicit envp from a shell must not replace the child's executable identity
# with its parent's. Chrome uses this to locate its ICU data and resources.
[ "$(/usr/bin/readlink /proc/self/exe)" = "$root/usr/bin/readlink" ]
apt-get check
apt-get install -y --no-install-recommends "$files/client.deb" "$files/lib.deb"
apt-mark showmanual | grep -x arlinux-apt-test-client
apt-mark auto arlinux-apt-test-lib
apt-mark showauto | grep -x arlinux-apt-test-lib
SH
# Bypass both launchers and the preload: this ELF has no RPATH/RUNPATH.
# Only the real cache can supply the library from the private directory.
"${adb[@]}" shell run-as "$package" /system/bin/env LD_PRELOAD= LD_LIBRARY_PATH= \
    "$root/usr/lib/arlinux-platform/ld-linux-aarch64.so.1" \
    --library-path "$root/usr/lib/arlinux-platform" "$root/usr/lib/arlinux-apt-test/cache-client"
"$core/tools/guest-desk.sh" exec "$root/bin/sh" -s <<'SH'
set -eu
root=$BIONICX_ROOTFS
files=$BIONICX_FILES
[ -L "$root/usr/lib/arlinux-apt-test/libarlinux-apt-test.so.1" ]
ldconfig -p | grep 'libarlinux-apt-test.so.1.*=> /data/'
# A cache write error must propagate to the caller.
if ldconfig -C "$root/no-such-directory/cache"; then
    echo 'FAIL: ldconfig swallowed an error' >&2
    exit 1
fi
apt-get purge -y arlinux-apt-test-client arlinux-apt-test-lib
if ldconfig -p | grep -q libarlinux-apt-test; then
    echo 'FAIL: purged library remains in cache' >&2
    exit 1
fi
apt-get check
dpkg --audit
[ "$(id -u)" != 0 ]
rm "$files/client.deb" "$files/lib.deb"
# ldconfig-created SONAME links are not owned by the test package.
rm -f "$root/usr/lib/arlinux-apt-test/libarlinux-apt-test.so.1"
rmdir "$root/usr/lib/arlinux-apt-test"
echo 'direct apt, Pre-Depends, ldconfig cache and purge: PASS'
SH
