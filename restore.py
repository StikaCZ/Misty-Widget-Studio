#!/usr/bin/env python3
"""Restore the previous state of all 17 widgets from this release's backup."""
from pathlib import Path
import shutil,sys
HERE=Path(__file__).resolve().parent
IDS=sorted(p.name for p in (HERE/'widgets').iterdir() if p.is_dir() and (p.name.startswith('local.samuel.') or p.name == 'local.stikacz.cdplayer'))
if len(IDS)!=17:sys.exit('Widget list incomplete; refusing restore.')
TARGET=Path.home()/'.local/share/plasma/plasmoids'
STATE=Path.home()/'.local/state/stikacz-misty-collection'
LATEST=STATE/'latest-backup'
if not LATEST.exists():sys.exit('No backup found for this collection.')
backup=Path(LATEST.read_text().strip()).resolve()
if not backup.is_relative_to((STATE/'backups').resolve()) or not backup.is_dir():sys.exit('Invalid backup path.')
for name in IDS:
    if (TARGET/name).is_symlink():sys.exit('Refusing symlinked destination: '+name)
for name in IDS:
    dst=TARGET/name
    if dst.exists():shutil.rmtree(dst)
    if (backup/name).exists():shutil.copytree(backup/name,dst,symlinks=True)
print('Restored previous widgets from:',backup)
print('Reload desktop: systemctl --user restart plasma-plasmashell.service')
