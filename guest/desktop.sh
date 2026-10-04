#!/bin/sh
# Local files remain usable even when the optional AI service is offline.
set -eu
mkdir -p "$HOME/Documents"
thunar "$HOME/Documents" &
exec /opt/OpenCode/ai.opencode.desktop --force-renderer-accessibility
