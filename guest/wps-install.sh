#!/bin/sh
set -eu
root=${BIONICX_ROOTFS:?missing BIONICX_ROOTFS}
guest=$root/usr/lib/arlinux/guest
cache=$HOME/.cache/arlinux-wps
mkdir -p "$cache"

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
            echo "Downloading $1 ($version)..." >&2
            if curl --fail --location --retry 3 --retry-all-errors \
                    --connect-timeout 30 -o "$download.partial" "$url" &&
                    printf '%s  %s\n' "$checksum" "$download.partial" | sha256sum -c - >&2; then
                fetched=1
                break
            fi
            rm -f "$download.partial"
            echo "The primary source is unavailable; trying the fallback..." >&2
        done
        [ -n "$fetched" ] || {
            echo "Could not download or verify $1 ($version)" >&2
            return 1
        }
        mv "$download.partial" "$download"
    fi
}

install_wps() {
    ready=1
    for package in wps-office ttf-wps-fonts libwebp6 libtiff5; do
        status=$(dpkg-query -W -f '${Status}' "$package" 2>/dev/null || true)
        [ "$status" = 'install ok installed' ] || ready=0
    done
    if [ "$ready" -eq 0 ]; then
        echo 'Installing WPS dependencies...'
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y --no-install-recommends curl ca-certificates xdg-utils \
            fonts-liberation fontconfig libxkbcommon-x11-0 libxslt1.1 libglu1-mesa \
            libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 \
            libxcb-xinerama0 libxcb-xkb1 libxcb-util1 shared-mime-info \
            bsdextrautils
        set --
        for package in libwebp6 libtiff5 wps-office ttf-wps-fonts; do
            fetch "$package"
            set -- "$@" "$download"
        done
        apt-get install -y --no-install-recommends "$@"
        fc-cache -f
    fi
}

install_wps
