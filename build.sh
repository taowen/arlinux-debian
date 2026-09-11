#!/usr/bin/env bash
set -euo pipefail
product="$(cd "$(dirname "$0")" && pwd)"
export ARLINUX_DIR="${ARLINUX_DIR:-$product/third_party/arlinux}"
exec python3 "$ARLINUX_DIR/tools/build-product.py" "$product" "$@"
