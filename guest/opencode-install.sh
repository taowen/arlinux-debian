#!/bin/sh
set -eu

root=${BIONICX_ROOTFS:?missing BIONICX_ROOTFS}
files=${BIONICX_FILES:?missing BIONICX_FILES}
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
url=$4

installed=$(dpkg-query -W -f '${Version}' opencode 2>/dev/null || true)
if [ "$installed" = "$version" ] &&
        [ -x "$root/opt/OpenCode/ai.opencode.desktop" ]; then
    exit 0
fi

cache=$files/downloads
package=$cache/opencode-desktop-$version-arm64.deb
mkdir -p "$cache"
if [ ! -f "$package" ] ||
        [ "$(sha256sum "$package" | awk '{print $1}')" != "$expected" ]; then
    rm -f "$package.part"
    echo "ARLINUX:Downloading OpenCode Desktop $version..."
    curl -fL --retry 3 --connect-timeout 20 -o "$package.part" "$url"
    actual=$(sha256sum "$package.part" | awk '{print $1}')
    [ "$actual" = "$expected" ] || {
        rm -f "$package.part"
        echo 'OpenCode Desktop SHA-256 verification failed' >&2
        exit 1
    }
    mv "$package.part" "$package"
fi

echo "ARLINUX:Installing OpenCode Desktop $version..."
apt-get install -y --no-install-recommends "$package"
[ -x "$root/opt/OpenCode/ai.opencode.desktop" ] || {
    echo 'OpenCode Desktop executable is missing after installation' >&2
    exit 1
}
