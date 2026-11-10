#!/usr/bin/env bash
# Local allowlisted application launcher; never executes arbitrary input.
set -euo pipefail
case "${1:-}" in
  search)
    if command -v krunner >/dev/null 2>&1; then krunner >/dev/null 2>&1 &
    elif command -v kstart6 >/dev/null 2>&1; then kstart6 krunner >/dev/null 2>&1 &
    else exit 1; fi ;;
  browser) xdg-open 'https://www.google.com' >/dev/null 2>&1 & ;;
  files) xdg-open "$HOME" >/dev/null 2>&1 & ;;
  steam) command -v steam >/dev/null 2>&1 && { steam >/dev/null 2>&1 & } || exit 1 ;;
  blender) command -v blender >/dev/null 2>&1 && { blender >/dev/null 2>&1 & } || exit 1 ;;
  terminal)
    if command -v konsole >/dev/null 2>&1; then konsole >/dev/null 2>&1 &
    elif command -v xterm >/dev/null 2>&1; then xterm >/dev/null 2>&1 &
    else exit 1; fi ;;
  *) echo 'Not a supported launcher action' >&2; exit 2 ;;
esac
