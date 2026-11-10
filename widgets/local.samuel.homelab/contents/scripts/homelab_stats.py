#!/usr/bin/env python3
"""Read-only SSH monitor for Misty Homelab.

No shell on the local PC, no credentials stored, no remote installer, no daemon.
SSH host key checking stays enabled. See CONFIGURE-DEBIAN.md.
"""
from __future__ import annotations

import argparse
import getpass
import ipaddress
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.parse import unquote

HERE = Path(__file__).resolve().parent
REMOTE = HERE / "remote-stats.sh"


def result(**fields: str) -> None:
    for key, value in fields.items():
        k = str(key).replace("\n", " ").upper()
        v = str(value).replace("\r", " ").replace("\n", " ").strip()
        print(f"{k}  {v or '--'}")


def valid_host(raw: str) -> str:
    s = unquote(raw).strip()
    if s.startswith("[") and s.endswith("]"):
        s = s[1:-1]
    try:
        ipaddress.ip_address(s)
        return s
    except ValueError:
        pass
    if len(s) > 253 or not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?", s):
        raise ValueError("Enter a server hostname or IP address (for example debian or 192.168.1.50).")
    return s


def valid_user(raw: str) -> str:
    user = unquote(raw).strip() or getpass.getuser()
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.-]{0,63}", user):
        raise ValueError("Enter a valid SSH username (letters, numbers, . _ or -).")
    return user


def valid_port(raw: str) -> int:
    try: value = int(unquote(raw))
    except ValueError as exc: raise ValueError("SSH port must be a number between 1 and 65535.") from exc
    if not 1 <= value <= 65535:
        raise ValueError("SSH port must be between 1 and 65535.")
    return value


def valid_identity(raw: str) -> str:
    s = unquote(raw).strip()
    if not s:
        return ""
    path = Path(os.path.expanduser(s))
    if not path.is_absolute():
        raise ValueError("The optional SSH key path must be absolute or start with ~/.")
    if not path.is_file():
        raise ValueError("SSH key file not found. Leave the key field blank to use your normal SSH key or agent.")
    return str(path)


def valid_unit(raw: str) -> str:
    s = unquote(raw).strip()
    if not s:
        return ""
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.@-]{0,127}", s):
        raise ValueError("Service name must be a simple systemd unit (for example tmodloader.service).")
    return s


def diagnose(message: str) -> str:
    m = message.lower()
    if "host key verification failed" in m or "no host key is known" in m:
        return "Unknown or changed host key. Connect once in Konsole and verify the server fingerprint."
    if "permission denied" in m or "publickey" in m:
        return "SSH key not authorised. Run ssh-copy-id using the command shown in Configure."
    if "could not resolve hostname" in m or "name or service not known" in m:
        return "Server hostname not found. Try the server's LAN IP address instead."
    if "connection refused" in m:
        return "SSH refused the connection. Start openssh-server on Debian and check the port."
    if "connection timed out" in m or "operation timed out" in m:
        return "Timed out. Check the server is powered on and both devices are on the same network."
    if "no route to host" in m or "network is unreachable" in m:
        return "No route to Debian. Check its IP address and local network connection."
    if "identity file" in m or "bad permissions" in m:
        return "SSH key file cannot be used. Check the key path and file permissions."
    return "SSH connection failed. Try the displayed ssh command in Konsole to see details."


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Read-only SSH monitor for Misty Homelab")
    parser.add_argument("--host", default="debian")
    parser.add_argument("--user", default="")
    parser.add_argument("--port", default="22")
    parser.add_argument("--identity", default="")
    parser.add_argument("--unit", default="tmodloader.service")
    parser.add_argument("--test", action="store_true")
    ns = parser.parse_args(argv)
    try:
        host = valid_host(ns.host)
        user = valid_user(ns.user)
        port = valid_port(ns.port)
        identity = valid_identity(ns.identity)
        unit = valid_unit(ns.unit)
    except ValueError as exc:
        result(STATUS="OFFLINE", DETAIL=str(exc))
        return 0

    if shutil.which("ssh") is None:
        result(STATUS="OFFLINE", DETAIL="OpenSSH client is missing. Install the openssh package on this PC.")
        return 0

    command = ["ssh", "-T", "-o", "BatchMode=yes", "-o", "PasswordAuthentication=no",
               "-o", "StrictHostKeyChecking=yes", "-o", "ConnectTimeout=6",
               "-o", "ConnectionAttempts=1", "-o", "LogLevel=ERROR",
               "-p", str(port)]
    if identity:
        command.extend(["-i", identity, "-o", "IdentitiesOnly=yes"])
    command.append(f"{user}@{host}")
    if ns.test:
        command.append("true")
        data = None
    else:
        if not REMOTE.is_file():
            result(STATUS="OFFLINE", DETAIL="Bundled remote monitor script is missing. Reinstall the Homelab widget.")
            return 0
        command.append("bash -s -- " + unit if unit else "bash -s --")
        data = REMOTE.read_text(encoding="utf-8")
    try:
        finished = subprocess.run(command, input=data, text=True, capture_output=True, timeout=12, check=False)
    except subprocess.TimeoutExpired:
        result(STATUS="OFFLINE", DETAIL="SSH check timed out. Check the network or hostname.")
        return 0
    except OSError:
        result(STATUS="OFFLINE", DETAIL="Cannot run SSH. Check that openssh is installed.")
        return 0
    if finished.returncode != 0:
        result(STATUS="OFFLINE", DETAIL=diagnose(finished.stderr or finished.stdout))
        return 0
    if ns.test:
        result(STATUS="ONLINE", DETAIL="SSH works with your key. Click Apply to save these settings.", HOST=host)
    else:
        raw = finished.stdout.strip()
        if not raw or not re.search(r"^STATUS\s{2,}ONLINE$", raw, re.MULTILINE):
            result(STATUS="OFFLINE", DETAIL="Connected, but the remote stats script returned no valid data. Ensure bash is installed on Debian.")
        else:
            print(raw)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
