#!/bin/sh
# Only device-local configuration belongs here. Packages are built into the ZIP.
set -eu
guest=/usr/lib/arlinux/guest
test -f /usr/share/arlinux/offline-desktop
test -x /usr/bin/arlinux-opencode
if [ ! -s /etc/machine-id ]; then
    chmod u+w /etc/machine-id
    tr -d '-' < /proc/sys/kernel/random/uuid > /etc/machine-id
    chmod 444 /etc/machine-id
fi
install -Dm755 "$guest/install-codex.sh" /usr/local/bin/arlinux-install-codex
mkdir -p /etc/fonts/conf.d /usr/lib/python3/dist-packages/arlinux
cp "$guest/50-arlinux-wps-fonts.conf" /etc/fonts/conf.d/
cp "$guest/arlinux/"*.py /usr/lib/python3/dist-packages/arlinux/
/bin/sh "$guest/opencode-instructions.sh"
mkdir -p /etc/pulse/client.conf.d /etc/alsa/conf.d
printf 'default-server = unix:%s/runtime/pulse-native\nautospawn = no\nenable-shm = no\n' \
    "$BIONICX_FILES" > /etc/pulse/client.conf.d/arlinux.conf
printf 'pcm.!default { type pulse }\nctl.!default { type pulse }\n' \
    > /etc/alsa/conf.d/99-arlinux-pulse.conf
/bin/sh "$guest/wps-shortcuts.sh"
