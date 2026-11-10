#!/usr/bin/env bash
# Compatibility launcher for the original Misty update-plant helper.
exec python3 "$(dirname "${BASH_SOURCE[0]}")/check-updates.py" "$@"
