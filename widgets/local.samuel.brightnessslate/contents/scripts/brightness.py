#!/usr/bin/env python3
"""Misty Display / Light: use KDE Plasma 6 PowerDevil brightness service.
This supports monitor brightness (including external monitors when KDE exposes
DDC/CI or software brightness controls). Fallback to laptop sysfs backlight.
No privileges, shell commands, network requests or direct DDC writes.
"""
import json
import re
import shutil
import shlex
import subprocess
import sys
from pathlib import Path

SERVICE = 'org.kde.ScreenBrightness'
BASE = '/org/kde/ScreenBrightness'
API = 'org.kde.ScreenBrightness'
DISPLAY_API = 'org.kde.ScreenBrightness.Display'
ID = re.compile(r'^display[0-9]+$')
BACKLIGHT = re.compile(r'^[A-Za-z0-9_.-]{1,80}$')


def run(argv, timeout=4):
    try:
        return subprocess.run(argv, capture_output=True, text=True, timeout=timeout, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return None


def prop(path, interface, property_name):
    result = run(['busctl','--user','get-property', SERVICE, path, interface, property_name])
    if result is None or result.returncode != 0:
        return None
    try:
        parts = shlex.split(result.stdout.strip())
        if len(parts) >= 2:
            return parts[1]
    except ValueError:
        pass
    return None


def kde_displays():
    if not shutil.which('busctl'):
        return []
    result = run(['busctl','--user','get-property', SERVICE, BASE, API, 'DisplaysDBusNames'])
    if result is None or result.returncode != 0:
        return []
    try:
        tokens = shlex.split(result.stdout.strip())
    except ValueError:
        return []
    if len(tokens) < 2 or tokens[0] != 'as':
        return []
    names = [x for x in tokens[2:] if ID.fullmatch(x)]
    displays = []
    for name in names[:12]:
        path = BASE + '/' + name
        current = prop(path, DISPLAY_API, 'Brightness')
        maximum = prop(path, DISPLAY_API, 'MaxBrightness')
        try:
            now, cap = int(current), int(maximum)
        except (TypeError, ValueError):
            continue
        if cap <= 0:
            continue
        label = prop(path, DISPLAY_API, 'Label') or name
        displays.append({'id': 'kde:' + name, 'label': label[:96],
                         'percent': round(max(0, min(100, now / cap * 100))),
                         'backend': 'KDE PowerDevil'})
    return displays


def backlights():
    items=[]
    for path in sorted(Path('/sys/class/backlight').glob('*')):
        if not BACKLIGHT.fullmatch(path.name):
            continue
        try:
            maximum = int((path/'max_brightness').read_text().strip())
            current = int((path/'brightness').read_text().strip())
            if maximum > 0:
                items.append({'id':'backlight:' + path.name, 'label':path.name,
                              'percent':round(max(0,min(100,current / maximum * 100))),
                              'backend':'Linux backlight'})
        except (OSError, ValueError):
            pass
    return items


def list_displays():
    kde = kde_displays()
    if kde:
        return {'displays': kde, 'notice': 'Per-display controls provided by KDE PowerDevil'}
    internal = backlights()
    if internal:
        return {'displays': internal, 'notice': 'Using the Linux built-in backlight'}
    return {'displays': [], 'notice': 'KDE reports no brightness-capable displays. Check Brightness & Colour and DDC/CI in your monitor settings.'}


def set_percent(device, percent):
    try:
        value = int(percent)
    except (TypeError, ValueError):
        return {'success':False,'error':'Invalid brightness value'}
    if not (5 <= value <= 100):
        return {'success':False,'error':'Select 5–100%'}
    available = list_displays()['displays']
    matched = next((d for d in available if d['id'] == device), None)
    if not matched:
        return {'success':False,'error':'Display unavailable; refresh the list'}
    if device.startswith('kde:'):
        name = device.split(':', 1)[1]
        if not ID.fullmatch(name):
            return {'success':False,'error':'Invalid display'}
        path = BASE + '/' + name
        maxvalue = prop(path, DISPLAY_API, 'MaxBrightness')
        try:
            target = round(int(maxvalue) * value / 100)
        except (TypeError, ValueError):
            return {'success':False,'error':'Cannot read maximum brightness'}
        result = run(['busctl','--user','call',SERVICE,path,DISPLAY_API,'SetBrightness','iu',str(target),'0'], 7)
        if result is not None and result.returncode == 0:
            return {'success':True}
        return {'success':False,'error':'PowerDevil rejected brightness change; check DDC/CI or monitor permissions'}
    if device.startswith('backlight:'):
        name = device.split(':', 1)[1]
        if not BACKLIGHT.fullmatch(name) or not shutil.which('brightnessctl'):
            return {'success':False,'error':'Install brightnessctl for built-in backlight control'}
        result = run(['brightnessctl','-d',name,'set',f'{value}%'],7)
        return {'success':bool(result and result.returncode == 0),
                'error': '' if result and result.returncode == 0 else 'Backlight permission denied or device unavailable'}
    return {'success':False,'error':'Unknown display'}


def main():
    if len(sys.argv) == 2 and sys.argv[1] == 'list':
        print(json.dumps(list_displays()))
    elif len(sys.argv) == 4 and sys.argv[1] == 'set':
        print(json.dumps(set_percent(sys.argv[2],sys.argv[3])))
    else:
        print(json.dumps({'success':False,'error':'Usage: brightness.py list | set DISPLAY 5..100'}))

if __name__ == '__main__':
    main()
