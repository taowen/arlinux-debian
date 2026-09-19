#!/usr/bin/env python3
"""Exercise download integrity, retry, cached launches and argument preservation."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

product = Path(__file__).resolve().parents[1]


def shell_path(path):
    """Use one path spelling throughout an MSYS shell and its child scripts."""
    cygpath = shutil.which('cygpath')
    if os.name == 'nt' and cygpath:
        return subprocess.check_output([cygpath, '-u', str(path)], text=True).strip()
    return str(path)


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
    guest_sh = root / 'bin/sh'
    guest_sh.write_text('#!/bin/sh\nexec /bin/sh "$@"\n')
    guest_sh.chmod(0o755)
    office = root / 'opt/kingsoft/wps-office/office6'
    office.mkdir(parents=True)
    program = office / 'wps'
    program.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/arguments"\n')
    program.chmod(0o755)
    payload = b'test vendor archive\n'
    sha = hashlib.sha256(payload).hexdigest()
    (guest / 'wps-downloads.tsv').write_text(
        f'vendor\t1\t{sha}\thttps://primary.invalid/vendor.deb'
        '\thttps://fallback.invalid/vendor.deb\n'
    )
    (guest / 'wps-install.sh').write_text('install_wps() { fetch vendor; }\n')
    commands = tmp / 'commands'
    commands.mkdir()
    curl = commands / 'curl'
    curl.write_text('''#!/bin/sh
output=
url=
while [ "$#" -gt 0 ]; do
    case "$1" in
        -o) output=$2; shift 2 ;;
        http*) url=$1; shift ;;
        *) shift ;;
    esac
done
printf '%s\\n' "$url" >> "$HOME/downloads"
case "$url" in *primary.invalid*) exit 22 ;; esac
if [ "${CORRUPT:-0}" = 1 ]; then printf 'bad archive\\n' > "$output";
else printf 'test vendor archive\\n' > "$output"; fi
''')
    curl.chmod(0o755)
    shell_bin = Path(shutil.which('sh') or '/bin/sh').parent
    env = {**os.environ, 'BIONICX_ROOTFS': shell_path(root), 'HOME': shell_path(home),
           'PATH': shell_path(commands) + ':' + shell_path(shell_bin) + ':' + os.environ['PATH']}
    launch = ['sh', shell_path(guest / 'wps-office.sh'), 'writer', 'a b.docx', '--literal']
    def run(args=launch, **overrides):
        return subprocess.run(args, env={**env, **overrides}, capture_output=True, text=True)
    assert run(CORRUPT='1').returncode != 0
    assert not (home / 'arguments').exists(), 'corrupt download launched WPS'
    assert not (home / '.cache/arlinux-wps/vendor-1.deb').exists()
    result = run()
    assert result.returncode == 0, result.stderr or result.stdout
    assert (home / 'arguments').read_text() == 'a b.docx\n--literal\n'
    assert run().returncode == 0
    assert (home / 'downloads').read_text().splitlines() == [
        'https://primary.invalid/vendor.deb', 'https://fallback.invalid/vendor.deb',
        'https://primary.invalid/vendor.deb', 'https://fallback.invalid/vendor.deb',
    ]
    (home / '.cache/arlinux-wps/vendor-1.deb').write_text('corrupted cache')
    assert run().returncode == 0
    assert len((home / 'downloads').read_text().splitlines()) == 6
    assert run(['sh', shell_path(guest / 'wps-shortcuts.sh')]).returncode == 0
    result = run(['sh', shell_path(home / 'wps-writer'), 'from shortcut.docx'])
    assert result.returncode == 0, result.stderr or result.stdout
    assert (home / 'arguments').read_text() == 'from shortcut.docx\n'
    assert settings.read_text() == 'user settings\n'
    assert len(list((home / '.local/share/applications').glob('arlinux-wps-*.desktop'))) == 4
    assert run(['sh', shell_path(guest / 'wps-office.sh'), 'invalid']).returncode == 2
print('PASS: checksum failure, retry, cache validation, shortcut and file arguments')
