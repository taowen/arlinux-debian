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
printf 'force-not-root\nforce-script-chrootless\nforce-confnew\nroot=%s\nadmindir=%s/var/lib/dpkg\n' "$root" "$root" \
    > "$root/etc/dpkg/dpkg.cfg.d/arlinux"
mkdir -p "$root/etc/ld.so.conf.d"
printf '/usr/lib/arlinux-platform\n' > "$root/etc/ld.so.conf.d/arlinux.conf"
mkdir -p "$root/etc/fonts/conf.d"
cp "$guest/50-arlinux-wps-fonts.conf" \
    "$root/etc/fonts/conf.d/50-arlinux-wps-fonts.conf"

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
    ibus ibus-gtk3 ibus-gtk4 gir1.2-ibus-1.0 \
    python3-dogtail python3-pip mpg123 \
    wl-clipboard wtype xclip xdotool \
    libwayland-egl1 libwayland-client0 libwayland-server0 libx11-xcb1 \
    libasound2-plugins
missing=
for pkg do
    if ! dpkg-query -W -f '${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
        missing=1
        break
    fi
done
if [ -n "$missing" ]; then
    echo "ARLINUX:Updating Debian package metadata..."
    apt-get update
    echo "ARLINUX:Installing Debian desktop components..."
    apt-get install -y --no-install-recommends "$@"
    # apt may have replaced libc and the loader beneath this still-running
    # process. Ask Android for a fresh bionicx execution boundary before any
    # newly installed program is launched.
    exit 75
fi

# edge-tts uses Microsoft's online Edge speech service.  Pin the Python client
# so initial installations remain reproducible; mpg123 plays through PulseAudio
# without launching a media-player window.
if ! python3 -c 'import edge_tts' >/dev/null 2>&1; then
    echo "ARLINUX:Installing online speech support..."
    python3 -m pip install --break-system-packages --no-cache-dir 'edge-tts==7.2.8'
fi
mkdir -p "$root/usr/lib/python3/dist-packages"
mkdir -p "$root/usr/lib/python3/dist-packages/arlinux"
rm -f "$root/usr/lib/python3/dist-packages/arlinux/_accessibility.py"
cp "$guest/arlinux/"*.py "$root/usr/lib/python3/dist-packages/arlinux/"
rm -f "$root/usr/lib/python3/dist-packages/arlinux_tts.py"

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
