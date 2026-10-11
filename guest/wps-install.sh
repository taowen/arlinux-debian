#!/bin/sh
set -eu
root=${BIONICX_ROOTFS:?missing BIONICX_ROOTFS}
guest=$root/usr/lib/arlinux/guest

fetch() {
    row=$(awk -F '\t' -v p="$1" '$1 == p { print; exit }' "$guest/wps-downloads.tsv")
    [ -n "$row" ] || { echo "Missing download: $1" >&2; exit 1; }
    version=$(printf '%s\n' "$row" | cut -f2)
    checksum=$(printf '%s\n' "$row" | cut -f3)
    echo "Preparing $1 ($version)..." >&2
    # URLs contain no spaces; the shared helper verifies and locks each blob.
    download=$(python3 "$root/usr/lib/arlinux/shared.py" "$checksum" .deb \
        $(printf '%s\n' "$row" | cut -f4- | tr '\t' '\n'))
}

install_wps() {
    ready=1
    for package in wps-office ttf-wps-fonts libwebp6 libtiff5; do
        status=$(dpkg-query -W -f '${Status}' "$package" 2>/dev/null || true)
        [ "$status" = 'install ok installed' ] || ready=0
    done
    fonts_ready=1
    for weight in Regular Bold; do
        [ -s "$root/usr/share/fonts/opentype/noto/NotoSerifCJK-$weight.ttc" ] || fonts_ready=0
    done
    if [ "$ready" -eq 0 ] || [ "$fonts_ready" -eq 0 ]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
    fi
    if [ "$ready" -eq 0 ]; then
        echo 'Installing WPS dependencies...'
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
    fi
    if [ "$fonts_ready" -eq 0 ]; then
        echo 'Installing Chinese, Japanese and Korean document fonts...'
        apt-get install -y --no-install-recommends --reinstall fonts-noto-cjk
    fi
    if [ "$ready" -eq 0 ] || [ "$fonts_ready" -eq 0 ]; then
        fc-cache -f
    fi
}

install_wps
