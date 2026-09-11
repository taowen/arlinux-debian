#!/usr/bin/env python3
"""Exercise download integrity, retry, cached launches and argument preservation."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

product = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
    tmp = Path(directory)
    root = tmp / 'root'
    guest = root / 'usr/lib/arlinux/guest'
    shutil.copytree(product / 'guest', guest)
    home = tmp / 'home'
    home.mkdir()
    settings = home / '.config/Kingsoft/Office.conf'
    settings.parent.mkdir(parents=True)
    settings.write_text('user settings\n')
    (root / 'etc/fonts/conf.d').mkdir(parents=True)
    (root / 'bin').mkdir()
    (root / 'bin/sh').symlink_to('/bin/sh')
    office = root / 'opt/kingsoft/wps-office/office6'
    office.mkdir(parents=True)
    program = office / 'wps'
    program.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/arguments"\n')
    program.chmod(0o755)
    payload = b'test vendor archive\n'
    sha = hashlib.sha256(payload).hexdigest()
    (guest / 'wps-downloads.tsv').write_text(f'vendor\t1\t{sha}\thttps://example.invalid/vendor.deb\n')
    (guest / 'wps-install.sh').write_text('install_wps() { fetch vendor; }\n')
    commands = tmp / 'commands'
    commands.mkdir()
    curl = commands / 'curl'
    curl.write_text('''#!/bin/sh
printf 'download\\n' >> "$HOME/downloads"
while [ "$1" != '-o' ]; do shift; done
if [ "${CORRUPT:-0}" = 1 ]; then printf 'bad archive\\n' > "$2";
else printf 'test vendor archive\\n' > "$2"; fi
''')
    curl.chmod(0o755)
    env = {**os.environ, 'BIONICX_ROOTFS': str(root), 'HOME': str(home),
           'PATH': str(commands) + ':' + os.environ['PATH']}
    launch = ['sh', str(guest / 'wps-office.sh'), 'writer', 'a b.docx', '--literal']
    def run(args=launch, **overrides):
        return subprocess.run(args, env={**env, **overrides}, capture_output=True, text=True)
    assert run(CORRUPT='1').returncode != 0
    assert not (home / 'arguments').exists(), 'corrupt download launched WPS'
    assert not (home / '.cache/arlinux-wps/vendor-1.deb').exists()
    assert run().returncode == 0
    assert (home / 'arguments').read_text() == 'a b.docx\n--literal\n'
    assert run().returncode == 0
    assert (home / 'downloads').read_text().splitlines() == ['download', 'download']
    (home / '.cache/arlinux-wps/vendor-1.deb').write_text('corrupted cache')
    assert run().returncode == 0
    assert len((home / 'downloads').read_text().splitlines()) == 3
    assert run(['sh', str(guest / 'wps-shortcuts.sh')]).returncode == 0
    assert run([str(home / 'wps-writer'), 'from shortcut.docx']).returncode == 0
    assert (home / 'arguments').read_text() == 'from shortcut.docx\n'
    assert settings.read_text() == 'user settings\n'
    assert len(list((home / '.local/share/applications').glob('arlinux-wps-*.desktop'))) == 4
    assert run(['sh', str(guest / 'wps-office.sh'), 'invalid']).returncode == 2
print('PASS: checksum failure, retry, cache validation, shortcut and file arguments')
