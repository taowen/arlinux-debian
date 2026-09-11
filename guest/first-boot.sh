#!/bin/sh
# Install desktop packages with standard apt/dpkg. The runtime supplies paths.
set -eu
root=${BIONICX_ROOTFS:?missing BIONICX_ROOTFS}
export DPKG_ROOT=$root BIONICX_VIRTUAL_ROOT=1
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

guest=$root/usr/lib/ardesk/guest
mkdir -p "$root/etc/apt/sources.list.d" "$root/etc/dpkg/dpkg.cfg.d" \
    "$root/var/lib/apt/lists/partial" "$root/var/cache/apt/archives/partial" "$root/var/log/apt"
if [ ! -f "$root/etc/apt/sources.list.d/debian.sources" ]; then
    cp "$guest/debian.sources" "$root/etc/apt/sources.list.d/debian.sources"
fi
sed "s|@ROOT@|$root|g" "$guest/apt.conf.in" > "$root/etc/apt/apt.conf"
printf 'force-not-root\nforce-script-chrootless\nroot=%s\nadmindir=%s/var/lib/dpkg\n' "$root" "$root" \
    > "$root/etc/dpkg/dpkg.cfg.d/ardesk"
mkdir -p "$root/etc/ld.so.conf.d"
printf '/usr/lib/ardesk-platform\n' > "$root/etc/ld.so.conf.d/ardesk.conf"

# Keep the Android glibc ldconfig across libc-bin upgrades using dpkg's own
# diversion database. No shell replacement or ignored cache-generation errors.
dpkg-divert --local --no-rename --add /usr/sbin/ldconfig
dpkg-divert --local --no-rename --add /usr/bin/sudo
cp "$root/usr/lib/ardesk-platform/ldconfig" "$root/usr/sbin/ldconfig"
chmod 755 "$root/usr/sbin/ldconfig"
ldconfig

# dpkg owns interrupted transaction state; no parallel snapshots/manifests.
if ! dpkg --configure -a; then
    apt-get update
    apt-get -f install -y
fi
set -- xterm fonts-dejavu-core fonts-noto-cjk fontconfig \
    x11-xserver-utils dbus-x11 at-spi2-core \
    libwayland-egl1 libwayland-client0 libwayland-server0 libx11-xcb1
missing=
for pkg do
    if ! dpkg-query -W -f '${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
        missing=1
        break
    fi
done
if [ -n "$missing" ]; then
    echo "ARDESK:正在更新 Debian 软件源…"
    apt-get update
    echo "ARDESK:正在安装 Debian 桌面组件…"
    apt-get install -y --no-install-recommends "$@"
fi

# Refresh product shortcuts for new installations and APK upgrades.
"$root/bin/sh" "$root/usr/lib/ardesk/guest/wps-shortcuts.sh"
