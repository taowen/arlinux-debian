#!/usr/bin/env bash
# Assert a packed/userspace seed keeps Debian PT_INTERP on key ELFs.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rootfs="${1:-$repo_dir/build/rootfs}"
want=/lib/ld-linux-aarch64.so.1

if [[ ! -x "$rootfs/usr/bin/apt-get" ]]; then
    echo "missing $rootfs/usr/bin/apt-get (build seed first)" >&2
    exit 2
fi

fail=0
for rel in usr/bin/apt-get usr/bin/dpkg usr/bin/bash; do
    path="$rootfs/$rel"
    [[ -e "$path" ]] || continue
    got="$(patchelf --print-interpreter "$path" 2>/dev/null || true)"
    if [[ "$got" != "$want" ]]; then
        echo "FAIL $rel INTERP=$got want=$want" >&2
        fail=1
    else
        echo "ok $rel"
    fi
done

# Helpers must not ship the archived rewriter.
if [[ -e "$rootfs/usr/lib/ardesk/rootfs-elf-fixup.sh" ]]; then
    echo "FAIL seed still ships rootfs-elf-fixup.sh" >&2
    fail=1
fi

[[ "$fail" -eq 0 ]]
echo "seed Debian INTERP: PASS"
