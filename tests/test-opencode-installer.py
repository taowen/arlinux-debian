#!/usr/bin/env python3
"""Check OpenCode's pinned download, checksum rejection and idempotency."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

product = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    root = tmp / "root"
    guest = root / "usr/lib/arlinux/guest"
    shutil.copytree(product / "guest", guest)
    files = tmp / "files"
    commands = tmp / "commands"
    commands.mkdir()
    payload = b"test opencode package\n"
    digest = hashlib.sha256(payload).hexdigest()
    (guest / "opencode-downloads.tsv").write_text(
        f"opencode-desktop\t1.2.3\t{digest}\thttps://example.invalid/opencode.deb\n"
    )
    (commands / "curl").write_text("""#!/bin/sh
printf 'download\n' >> "$BIONICX_FILES/calls"
while [ "$1" != -o ]; do shift; done
if [ "${CORRUPT:-0}" = 1 ]; then printf 'bad\n' > "$2"
else printf 'test opencode package\n' > "$2"; fi
""")
    (commands / "apt-get").write_text("""#!/bin/sh
printf 'install\n' >> "$BIONICX_FILES/calls"
mkdir -p "$BIONICX_ROOTFS/opt/OpenCode"
printf '#!/bin/sh\n' > "$BIONICX_ROOTFS/opt/OpenCode/ai.opencode.desktop"
chmod 755 "$BIONICX_ROOTFS/opt/OpenCode/ai.opencode.desktop"
printf '1.2.3\n' > "$BIONICX_FILES/installed-version"
""")
    (commands / "dpkg-query").write_text("""#!/bin/sh
cat "$BIONICX_FILES/installed-version" 2>/dev/null
""")
    for command in commands.iterdir():
        command.chmod(0o755)
    env = {
        **os.environ,
        "BIONICX_ROOTFS": str(root),
        "BIONICX_FILES": str(files),
        "PATH": str(commands) + ":" + os.environ["PATH"],
    }
    script = ["sh", str(guest / "opencode-install.sh")]
    failed = subprocess.run(script, env={**env, "CORRUPT": "1"})
    assert failed.returncode != 0
    package = files / "downloads/opencode-desktop-1.2.3-arm64.deb"
    assert not package.exists(), "bad package entered the cache"
    assert subprocess.run(script, env=env).returncode == 0
    assert package.read_bytes() == payload
    assert subprocess.run(script, env=env).returncode == 0
    assert (files / "calls").read_text().splitlines() == [
        "download", "download", "install"
    ]

print("PASS: OpenCode checksum failure, retry, install and idempotency")
