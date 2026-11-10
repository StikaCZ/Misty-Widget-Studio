#!/usr/bin/env python3
"""Local root-filesystem usage; read-only, no network."""
import json
import shutil
try:
    total, used, free = shutil.disk_usage('/')
    gib = 1024 ** 3
    print(json.dumps({"ok": True, "percent": round(used / total * 100, 1) if total else 0,
                      "usedGiB": round(used / gib, 1), "totalGiB": round(total / gib, 1),
                      "availableGiB": round(free / gib, 1)}))
except OSError:
    print(json.dumps({"ok": False, "percent": 0, "usedGiB": 0, "totalGiB": 0, "availableGiB": 0}))
