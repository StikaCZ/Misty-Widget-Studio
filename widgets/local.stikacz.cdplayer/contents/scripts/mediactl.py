#!/usr/bin/env python3
"""Read/control the active MPRIS player via playerctl; no network, no shell."""
import json
import shutil
import subprocess
import sys

def run(*args):
    try:
        result = subprocess.run(["playerctl", *args], capture_output=True,
                                text=True, timeout=3, check=False)
        return result.stdout.strip() if result.returncode == 0 else ""
    except (subprocess.TimeoutExpired, OSError):
        return ""

def clip(value):
    return " ".join(value.replace("\x00", "").split())[:180]

def status():
    if not shutil.which("playerctl"):
        return {"status":"Missing playerctl", "title":"Install playerctl", "artist":"sudo pacman -S playerctl", "player":""}
    state=run("status")
    if state not in ("Playing","Paused","Stopped"):
        return {"status":"No media player", "title":"No music playing", "artist":"Open a player", "player":""}
    title=run("metadata","--format","{{title}}")
    artist=run("metadata","--format","{{artist}}")
    pname=run("metadata","--format","{{playerName}}")
    raw_length=run("metadata","--format","{{mpris:length}}")
    raw_position=run("position")
    try: duration=max(0.0,float(raw_length)/1_000_000)
    except ValueError: duration=0.0
    try: position=max(0.0,float(raw_position))
    except ValueError: position=0.0
    return {"status":state,"title":clip(title) or "Untitled track",
            "artist":clip(artist) or clip(pname),"player":clip(pname),
            "position":position,"duration":duration}

def main():
    action=sys.argv[1] if len(sys.argv)>1 else "status"
    if action=="status":
        print(json.dumps(status(),ensure_ascii=False))
        return
    if action not in ("play-pause","previous","next"):
        raise SystemExit("Unsupported command")
    if not shutil.which("playerctl"):
        raise SystemExit("Install playerctl")
    subprocess.run(["playerctl",action],capture_output=True,timeout=3,check=False)
    print(json.dumps(status(),ensure_ascii=False))
if __name__ == "__main__":main()
