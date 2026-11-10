#!/usr/bin/env python3
"""Safe read-only CachyOS/Arch pending-update counter for Misty Plant.
Prefer a fresh pacman-contrib/checkupdates result; fall back to cached pacman -Qu.
Print JSON even on errors so the UI can show useful diagnostics.
"""
import json
import shutil
import subprocess


def execute(argv, timeout):
    try:
        return subprocess.run(argv, text=True, capture_output=True, timeout=timeout, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return None


def count_lines(data):
    return len([line for line in data.splitlines() if line.strip()])


def main():
    reason = ''
    if shutil.which('checkupdates'):
        result = execute(['checkupdates'], 20)
        if result is not None and result.returncode in (0, 2):
            print(json.dumps({'ok': True, 'count': count_lines(result.stdout), 'source': 'fresh', 'note': 'Repository snapshot from checkupdates'}))
            return
        reason = 'Fresh repository check timed out or failed'
    else:
        reason = 'Install pacman-contrib for fresh repository checks'

    if shutil.which('pacman'):
        result = execute(['pacman', '-Qu'], 8)
        # pacman may return 1 when no updates; only accept an empty output if
        # it also has no error text. Never silently report 0 on database errors.
        if result is not None and (result.returncode == 0 or
                                   (result.returncode == 1 and not result.stderr.strip())):
            print(json.dumps({'ok': True, 'count': count_lines(result.stdout), 'source': 'cached',
                              'note': reason + '; using locally cached package databases'}))
            return
        reason += '; cached pacman query also failed'
    else:
        reason += '; pacman not found'
    print(json.dumps({'ok': False, 'count': None, 'source': 'error', 'note': reason}))


if __name__ == '__main__':
    main()
