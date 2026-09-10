#!/bin/sh
install_wps() {
    ready=1
    for package in wps-office ttf-wps-fonts libwebp6 libtiff5; do
        status=$(dpkg-query -W -f '${Status}' "$package" 2>/dev/null || true)
        [ "$status" = 'install ok installed' ] || ready=0
    done
    if [ "$ready" -eq 0 ]; then
        echo '正在安装 WPS 依赖…'
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
