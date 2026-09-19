#!/bin/sh
# Product-owned WPS shortcuts. Downloads are pinned in wps-downloads.tsv.
set -eu
export LANG=C.UTF-8 LC_ALL=C.UTF-8
root=${BIONICX_ROOTFS:?missing BIONICX_ROOTFS}
guest=$root/usr/lib/arlinux/guest
app=${1:-writer}
case "$app" in
    writer) binary=wps ;; spreadsheet) binary=et ;;
    presentation) binary=wpp ;; pdf) binary=wpspdf ;;
    *) echo 'Usage: wps-office [writer|spreadsheet|presentation|pdf] [FILE ...]' >&2; exit 2 ;;
esac
[ "$#" -eq 0 ] || shift
cache=$HOME/.cache/arlinux-wps
mkdir -p "$cache"
# Serialize installation, including different component shortcuts.
exec 9>"$cache/install.lock"
flock 9
fetch() {
    row=$(awk -F '\t' -v p="$1" '$1 == p { print; exit }' "$guest/wps-downloads.tsv")
    [ -n "$row" ] || { echo "Missing download: $1" >&2; exit 1; }
    version=$(printf '%s\n' "$row" | cut -f2)
    checksum=$(printf '%s\n' "$row" | cut -f3)
    download=$cache/$1-$version.deb
    if ! printf '%s  %s\n' "$checksum" "$download" | sha256sum -c - >/dev/null 2>&1; then
        rm -f "$download.partial"
        fetched=
        for url in $(printf '%s\n' "$row" | cut -f4- | tr '\t' '\n'); do
            echo "下载 $1 ($version)…" >&2
            if curl --fail --location --retry 3 --retry-all-errors \
                    --connect-timeout 30 -o "$download.partial" "$url" &&
                    printf '%s  %s\n' "$checksum" "$download.partial" | sha256sum -c - >&2; then
                fetched=1
                break
            fi
            rm -f "$download.partial"
            echo "下载源不可用，尝试备用地址…" >&2
        done
        [ -n "$fetched" ] || {
            echo "无法下载或校验 $1 ($version)" >&2
            return 1
        }
        mv "$download.partial" "$download"
    fi
}
. "$guest/wps-install.sh"
install_wps
# Preserve the tested local-office preset: the optional cloud helper crashes
# under this runtime. Leave document editors and local file handling enabled.
cloud=$root/opt/kingsoft/wps-office/office6/wpscloudsvr
if [ -x "$cloud" ]; then chmod a-x "$cloud"; fi
mkdir -p "$HOME/Documents"
flock -u 9
exec 9>&-
# Preserve the user's Office.conf; WPS presents its own first-run agreement.
office=$root/opt/kingsoft/wps-office/office6
export QT_QPA_PLATFORM=xcb QT_X11_NO_MITSHM=1
export QT_PLUGIN_PATH=$office/qt/plugins
export QT_QPA_PLATFORM_PLUGIN_PATH=$office/qt/plugins/platforms
export XKB_CONFIG_ROOT=${BIONICX_FILES:-${root%/rootfs}}/xkb
export QT_XKB_CONFIG_ROOT=$XKB_CONFIG_ROOT
export FONTCONFIG_PATH=$root/etc/fonts FONTCONFIG_FILE=fonts.conf FONTCONFIG_SYSROOT=$root
exec "$office/$binary" "$@"
