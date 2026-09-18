#!/bin/sh
set -eu

root=${BIONICX_ROOTFS:?missing BIONICX_ROOTFS}
files=${BIONICX_FILES:?missing BIONICX_FILES}
guest=$root/usr/lib/arlinux/guest
manifest=$guest/opencode-downloads.tsv

row=$(awk -F '\t' '$1 == "opencode-desktop" { print; exit }' "$manifest")
[ -n "$row" ] || { echo 'OpenCode 下载清单无效' >&2; exit 1; }
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
    echo "ARLINUX:正在下载 OpenCode Desktop $version…"
    curl -fL --retry 3 --connect-timeout 20 -o "$package.part" "$url"
    actual=$(sha256sum "$package.part" | awk '{print $1}')
    [ "$actual" = "$expected" ] || {
        rm -f "$package.part"
        echo 'OpenCode Desktop SHA-256 校验失败' >&2
        exit 1
    }
    mv "$package.part" "$package"
fi

echo "ARLINUX:正在安装 OpenCode Desktop $version…"
apt-get install -y --no-install-recommends "$package"
[ -x "$root/opt/OpenCode/ai.opencode.desktop" ] || {
    echo 'OpenCode Desktop 安装后缺少主程序' >&2
    exit 1
}
