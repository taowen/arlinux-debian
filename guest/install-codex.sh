#!/bin/sh
# Optional on-device Codex CLI installation. Nothing is downloaded at boot.
set -eu

if ! command -v npm >/dev/null 2>&1; then
    apt-get update
    apt-get install -y --no-install-recommends nodejs npm
fi

npm install -g @openai/codex@latest
codex --version
printf '\nSign in with: codex login\n'
