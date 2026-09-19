#!/usr/bin/env bash
set -euo pipefail
product="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:?rootfs output required}"
readarray -t config < <(python3 - "$product/rootfs.lock.json" <<'PY'
import json, sys
x = json.load(open(sys.argv[1]))
print(x['suite']); print(x['mirror']); print(x['variant']); print(x['include'])
PY
)
rm -rf "$out"
mkdir -p "$out"
debootstrap --arch=arm64 --foreign --variant="${config[2]}" \
    --include="${config[3]}" "${config[0]}" "$out" "${config[1]}"
# Foreign stage downloads include packages but does not unpack them. Seed the
# architecture-independent Debian CA data so the first apt invocation can use
# HTTPS; normal package installation takes ownership of it on the device.
ca_deb=("$out"/var/cache/apt/archives/ca-certificates_*_all.deb)
[[ -f "${ca_deb[0]}" ]] || { echo "ca-certificates package missing from seed" >&2; exit 1; }
dpkg-deb --extract "${ca_deb[0]}" "$out"
mkdir -p "$out/etc/ssl/certs"
find "$out/usr/share/ca-certificates" -type f -name '*.crt' -print0 \
    | sort -z | xargs -0 cat > "$out/etc/ssl/certs/ca-certificates.crt"
[[ -s "$out/etc/ssl/certs/ca-certificates.crt" ]]
# --foreign has not run mawk's alternatives postinst yet. Never let a guest
# shell fall through to Android's /system/bin/awk during first boot.
ln -s mawk "$out/usr/bin/awk"
cp "$product/guest/debian.sources" "$out/etc/apt/sources.list.d/debian.sources"
rm -f "$out/etc/apt/sources.list"
