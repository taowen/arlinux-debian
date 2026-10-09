#!/bin/sh
# Run only in a fresh, disposable device build instance, never on consumer boot.
set -eu
export DEBIAN_FRONTEND=noninteractive
unset DPKG_ROOT
if [ ! -s /etc/passwd ]; then cp /usr/share/base-passwd/passwd.master /etc/passwd; fi
if [ ! -s /etc/group ]; then cp /usr/share/base-passwd/group.master /etc/group; fi
guest=/usr/lib/arlinux/guest
mkdir -p /etc/apt/sources.list.d /etc/dpkg/dpkg.cfg.d \
    /var/lib/apt/lists/partial /var/cache/apt/archives/partial /var/log/apt
printf 'force-confnew\n' > /etc/dpkg/dpkg.cfg.d/arlinux
cp "$guest/debian.sources" /etc/apt/sources.list.d/debian.sources
rm -f /etc/apt/sources.list
cp "$guest/apt.conf.in" /etc/apt/apt.conf
if [ ! -f /usr/share/arlinux/desktop-packages-installed ]; then
ldconfig
if ! dpkg --configure -a; then
    apt-get update
    apt-get -f install -y
fi
apt-get update
apt-get install -y --no-install-recommends /usr/lib/arlinux/mesa-packages/*.deb libegl1 libgles2 libopengl0
apt-get install -y --no-install-recommends \
    foot curl ca-certificates fonts-dejavu-core fonts-noto-cjk fontconfig \
    x11-utils dbus-x11 at-spi2-core python3-dbus python3-pyatspi \
    ibus ibus-gtk3 ibus-gtk4 gir1.2-ibus-1.0 gir1.2-gtk-3.0 python3-dogtail python3-pip mpg123 \
    wl-clipboard wtype xclip xdotool libwayland-egl1 libwayland-client0 \
    libwayland-server0 libx11-xcb1 libasound2-plugins thunar mousepad
mkdir -p /usr/share/arlinux
touch /usr/share/arlinux/desktop-packages-installed
# Restart after apt replaces libc or the loader under the running process.
exit 75
fi
apt-get autoremove -y
rm -f /usr/lib/arlinux/mesa-packages/*.deb
python3 -m pip install --break-system-packages --no-cache-dir \
    --index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple 'edge-tts==7.2.8'
python3 -c 'import edge_tts, pyatspi'
test -x /usr/bin/arlinux-opencode
test -z "$(dpkg --audit)"
update-alternatives --set x-terminal-emulator /usr/bin/foot
dpkg-divert --local --no-rename --add /usr/bin/sudo
apt-get clean
mkdir -p /usr/share/arlinux
dpkg-query -W -f '${binary:Package}\t${Version}\n' > /usr/share/arlinux/packages.tsv
printf '1\n' > /usr/share/arlinux/offline-desktop
