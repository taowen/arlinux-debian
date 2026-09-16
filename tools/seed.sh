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
cp "$product/guest/debian.sources" "$out/etc/apt/sources.list.d/debian.sources"
rm -f "$out/etc/apt/sources.list"
