#!/bin/sh
# Local files remain usable even when the optional AI service is offline.
set -eu
/opt/OpenCode/ai.opencode.desktop --force-renderer-accessibility &
# Keep the desktop bus alive when users close every application.
exec sleep infinity
