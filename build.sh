#!/usr/bin/env bash
set -euo pipefail
product="$(cd "$(dirname "$0")" && pwd)"
export ARDESK_DIR="${ARDESK_DIR:-$product/third_party/ardesk}"
exec python3 "$ARDESK_DIR/tools/build-product.py" "$product" "$@"
