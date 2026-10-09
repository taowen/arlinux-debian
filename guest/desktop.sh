#!/bin/sh
# Local files remain usable even when the optional AI service is offline.
set -eu
# OpenCode is optional: Apps and the AI voice entry install it on first use.
# Keep the desktop bus alive when users close every application.
exec sleep infinity
