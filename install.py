#!/usr/bin/env python3
"""Install all included KDE Plasma widgets for the invoking user; safe backup and rollback."""
from pathlib import Path
from datetime import datetime
from copy import deepcopy
import shutil, sys, xml.etree.ElementTree as ET
HERE=Path(__file__).resolve().parent
SOURCE=HERE/'widgets'
TARGET=Path.home()/'.local/share/plasma/plasmoids'
STATE=Path.home()/'.local/state/stikacz-misty-collection'
NS='http://www.kde.org/standards/kcfg/1.0'
ET.register_namespace('',NS)
ids=sorted(p.name for p in SOURCE.iterdir() if p.is_dir() and (p.name.startswith('local.samuel.') or p.name == 'local.stikacz.cdplayer'))
if len(ids)!=17:sys.exit('Expected 17 widget sources; refusing partial install.')
for name in ids:
    if not (SOURCE/name/'metadata.json').is_file():sys.exit('Missing widget metadata: '+name)
    if (TARGET/name).is_symlink():sys.exit('Refusing to modify symlinked widget: '+name)

def merge_config(src,dst):
    if not dst.exists():shutil.copy2(src,dst); return
    original=ET.parse(dst); changed=ET.parse(src)
    old=original.getroot(); new=changed.getroot()
    groups={g.get('name'):g for g in old.findall(f'{{{NS}}}group')}
    for group in new.findall(f'{{{NS}}}group'):
        key=group.get('name')
        if key not in groups:old.append(deepcopy(group)); continue
        present={i.get('name') for i in groups[key].findall(f'{{{NS}}}entry')}
        for item in group.findall(f'{{{NS}}}entry'):
            if item.get('name') not in present:groups[key].append(deepcopy(item))
    original.write(dst,encoding='utf-8',xml_declaration=True)

def overlay(src,dst):
    if not dst.exists():shutil.copytree(src,dst);return
    for item in src.rglob('*'):
        if item.is_symlink():raise RuntimeError('Source contains symlink: '+str(item))
        if item.is_dir():continue
        rel=item.relative_to(src); other=dst/rel
        if other.is_symlink():raise RuntimeError('Destination is symlink: '+str(other))
        other.parent.mkdir(parents=True,exist_ok=True)
        if rel.as_posix()=='contents/config/main.xml':merge_config(item,other)
        else:shutil.copyfile(item,other)
TARGET.mkdir(parents=True,exist_ok=True)
backup=STATE/'backups'/datetime.now().strftime('%Y%m%d-%H%M%S-%f')
backup.mkdir(parents=True,exist_ok=False)
for name in ids:
    if (TARGET/name).exists():shutil.copytree(TARGET/name,backup/name,symlinks=True)
try:
    for name in ids: overlay(SOURCE/name,TARGET/name)
    obsolete_eye=TARGET/'local.samuel.pets.unified/contents/images/eyeball'
    if obsolete_eye.is_symlink():raise RuntimeError('Refusing symlinked obsolete pet assets')
    if obsolete_eye.is_dir():shutil.rmtree(obsolete_eye)
except Exception:
    for name in ids:
        t=TARGET/name
        if t.exists():shutil.rmtree(t)
        if (backup/name).exists():shutil.copytree(backup/name,t,symlinks=True)
    raise
(STATE/'latest-backup').write_text(str(backup)+'\n')
print('Installed / updated',len(ids),'widgets by stika CZ. Backup:',backup)
print('Reload desktop: systemctl --user restart plasma-plasmashell.service')
