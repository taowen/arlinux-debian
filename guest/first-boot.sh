#!/bin/sh
# Install desktop packages with standard apt/dpkg. The runtime supplies paths.
set -eu
root=${BIONICX_ROOTFS:?missing BIONICX_ROOTFS}
export DPKG_ROOT=$root BIONICX_VIRTUAL_ROOT=1
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

guest=$root/usr/lib/arlinux/guest
mkdir -p "$root/etc/apt/sources.list.d" "$root/etc/dpkg/dpkg.cfg.d" \
    "$root/var/lib/apt/lists/partial" "$root/var/cache/apt/archives/partial" "$root/var/log/apt"
if [ ! -f "$root/etc/apt/sources.list.d/debian.sources" ]; then
    cp "$guest/debian.sources" "$root/etc/apt/sources.list.d/debian.sources"
fi
sed "s|@ROOT@|$root|g" "$guest/apt.conf.in" > "$root/etc/apt/apt.conf"
printf 'force-not-root\nforce-script-chrootless\nroot=%s\nadmindir=%s/var/lib/dpkg\n' "$root" "$root" \
    > "$root/etc/dpkg/dpkg.cfg.d/arlinux"
mkdir -p "$root/etc/ld.so.conf.d"
printf '/usr/lib/arlinux-platform\n' > "$root/etc/ld.so.conf.d/arlinux.conf"

# Keep the Android glibc ldconfig across libc-bin upgrades using dpkg's own
# diversion database. No shell replacement or ignored cache-generation errors.
dpkg-divert --local --no-rename --add /usr/sbin/ldconfig
dpkg-divert --local --no-rename --add /usr/bin/sudo
cp "$root/usr/lib/arlinux-platform/ldconfig" "$root/usr/sbin/ldconfig"
chmod 755 "$root/usr/sbin/ldconfig"
ldconfig

# dpkg owns interrupted transaction state; no parallel snapshots/manifests.
if ! dpkg --configure -a; then
    apt-get update
    apt-get -f install -y
fi
set -- xterm curl ca-certificates fonts-dejavu-core fonts-noto-cjk fontconfig \
    x11-xserver-utils x11-utils dbus-x11 at-spi2-core python3-dbus python3-pyatspi \
    libwayland-egl1 libwayland-client0 libwayland-server0 libx11-xcb1 \
    libasound2-plugins fcitx5 fcitx5-chinese-addons \
    fcitx5-frontend-gtk3 fcitx5-frontend-qt5
missing=
for pkg do
    if ! dpkg-query -W -f '${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
        missing=1
        break
    fi
done
if [ -n "$missing" ]; then
    echo "ARLINUX:正在更新 Debian 软件源…"
    apt-get update
    echo "ARLINUX:正在安装 Debian 桌面组件…"
    apt-get install -y --no-install-recommends "$@"
fi

"$root/bin/sh" "$guest/opencode-install.sh"
"$root/bin/sh" "$guest/opencode-instructions.sh"

mkdir -p "$root/etc/pulse/client.conf.d" "$root/etc/alsa/conf.d"
printf 'default-server = unix:%s/runtime/pulse-native\nautospawn = no\nenable-shm = no\n' \
    "$BIONICX_FILES" > "$root/etc/pulse/client.conf.d/arlinux.conf"
# Debian's standard ALSA pulse plugin connects to the Android host service.
cat > "$root/etc/alsa/conf.d/99-arlinux-pulse.conf" <<'ALSA'
pcm.!default { type pulse }
ctl.!default { type pulse }
ALSA

# Refresh product shortcuts for new installations and APK upgrades.
"$root/bin/sh" "$root/usr/lib/arlinux/guest/wps-shortcuts.sh"
