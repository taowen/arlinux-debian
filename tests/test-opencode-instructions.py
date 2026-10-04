#!/usr/bin/env python3
"""Verify the managed OpenCode global instructions preserve user content."""
import os
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

product = Path(__file__).resolve().parents[1]
assert "python3-dogtail" in (product / "guest/build-desktop.sh").read_text()
assert "edge-tts==7.2.8" in (product / "guest/build-desktop.sh").read_text()
assert "mpg123" in (product / "guest/build-desktop.sh").read_text()
assert "wl-clipboard wtype xclip xdotool" in (product / "guest/build-desktop.sh").read_text()
assert 'cp "$guest/arlinux/"*.py' in (product / "guest/first-boot.sh").read_text()
with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    root = tmp / "root"
    guest = root / "usr/lib/arlinux/guest"
    shutil.copytree(product / "guest", guest)
    home = tmp / "home"
    config = home / ".config/opencode"
    config.mkdir(parents=True)
    agents = config / "AGENTS.md"
    agents.write_text("# Personal rules\n\n- Keep my note.\n")
    user_config = config / "opencode.json"
    env = {**os.environ, "BIONICX_ROOTFS": str(root), "HOME": str(home)}
    script = ["sh", str(guest / "opencode-instructions.sh")]

    assert subprocess.run(script, env=env).returncode == 0
    first = agents.read_text()
    assert first.count("BEGIN ARLINUX MANAGED INSTRUCTIONS") == 1
    assert "Keep my note" in first
    assert (guest / "opencode-AGENTS.md").read_text().strip() in first
    assert not (root / "usr/local/bin/arlinux-a11y").exists()
    plugin = config / "plugin/arlinux-environment.js"
    assert plugin.read_text() == (guest / "opencode-arlinux-environment.js").read_text()
    assert 'output.env.NO_AT_BRIDGE = "0"' in plugin.read_text()
    merged = json.loads(user_config.read_text())
    assert merged["permission"]["external_directory"] == "allow"
    assert not (config / "arlinux.json").exists()

    user_config.write_text('{"model": "example/custom"}\n')
    (guest / "opencode-AGENTS.md").write_text("# Updated Arlinux instructions\n")
    assert subprocess.run(script, env=env).returncode == 0
    second = agents.read_text()
    assert second.count("BEGIN ARLINUX MANAGED INSTRUCTIONS") == 1
    assert "Keep my note" in second
    assert "Updated Arlinux instructions" in second
    assert "usr/lib/python3/dist-packages/arlinux/__init__.py" not in second
    assert json.loads(user_config.read_text()) == {"model": "example/custom"}
    assert plugin.read_text() == (guest / "opencode-arlinux-environment.js").read_text()

print("PASS: OpenCode global instructions update without replacing user rules")
