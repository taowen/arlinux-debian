#!/bin/sh
set -eu

root=${BIONICX_ROOTFS:?missing BIONICX_ROOTFS}
guest=$root/usr/lib/arlinux/guest
manifest=$guest/opencode-downloads.tsv

row=$(awk -F '\t' '$1 == "opencode-desktop" { print; exit }' "$manifest")
[ -n "$row" ] || { echo 'Invalid OpenCode download manifest' >&2; exit 1; }
old_ifs=$IFS
IFS=$(printf '\t')
set -- $row
IFS=$old_ifs
version=$2
expected=$3

installed=$(dpkg-query -W -f '${Version}' opencode 2>/dev/null || true)
if [ "$installed" = "$version" ] &&
        [ -x "$root/opt/OpenCode/ai.opencode.desktop" ]; then
    exit 0
fi

package=$root/usr/lib/arlinux/packages/opencode-desktop.deb
[ -f "$package" ] &&
    [ "$(sha256sum "$package" | awk '{print $1}')" = "$expected" ] || {
    echo 'Bundled OpenCode Desktop package is missing or corrupt' >&2
    exit 1
}

echo "ARLINUX:Installing OpenCode Desktop $version..."
apt-get install -y --no-install-recommends "$package"
[ -x "$root/opt/OpenCode/ai.opencode.desktop" ] || {
    echo 'OpenCode Desktop executable is missing after installation' >&2
    exit 1
}
