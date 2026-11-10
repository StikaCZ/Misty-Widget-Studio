#!/usr/bin/env bash
# Read-only commands executed via SSH stdin. No installation on Debian required.
set -u
LC_ALL=C
unit="${1:-}"

clean() { tr '\r\n' '  ' | cut -c 1-120; }
statline() { printf '%s  %s\n' "$1" "$(printf '%s' "$2" | clean)"; }

statline STATUS ONLINE
statline HOST "$(hostname -s 2>/dev/null || printf '%s' 'unknown')"
statline UPTIME "$(uptime -p 2>/dev/null || uptime 2>/dev/null || printf '%s' '--')"
statline 'LOAD (1m)' "$(awk '{print $1}' /proc/loadavg 2>/dev/null || printf '%s' '--')"

# /proc/meminfo avoids locale-sensitive free output.
if [ -r /proc/meminfo ]; then
  memtotal=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
  memavail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  if [ -n "$memtotal" ] && [ "$memtotal" -gt 0 ] && [ -n "$memavail" ]; then
    ram=$(awk -v t="$memtotal" -v a="$memavail" 'BEGIN {printf "%.1f / %.1f GiB", (t-a)/1048576, t/1048576}')
  else ram='--'; fi
else ram='--'; fi
statline RAM "$ram"
statline DISK "$(df -hP / 2>/dev/null | awk 'NR==2 {printf "%s / %s (%s)", $3,$2,$5}' || printf '%s' '--')"

cpu='--'
fan='--'
ambient='--'
for d in /sys/class/hwmon/hwmon*; do
  [ -d "$d" ] || continue
  name=$(cat "$d/name" 2>/dev/null || true)
  case "$name" in
    coretemp|k10temp|zenpower|cpu_thermal)
      for f in "$d"/temp*_input; do
        [ -r "$f" ] || continue
        raw=$(cat "$f" 2>/dev/null || true)
        if [[ "$raw" =~ ^[0-9]+$ ]] && [ "$raw" -gt 0 ] && [ "$raw" -lt 110000 ]; then
          cpu=$(awk -v n="$raw" 'BEGIN {printf "%.1f C", n/1000}')
          break
        fi
      done
      ;;
  esac
  for f in "$d"/fan*_input; do
    [ -r "$f" ] || continue
    rpm=$(cat "$f" 2>/dev/null || true)
    if [[ "$rpm" =~ ^[0-9]+$ ]] && [ "$rpm" -gt 0 ]; then
      fan="$rpm RPM"
      break
    fi
  done
  for f in "$d"/temp*_label; do
    [ -r "$f" ] || continue
    label=$(cat "$f" 2>/dev/null || true)
    case "$label" in
      *Ambient*|*ambient*|*System*|*system*)
        temp=$(cat "${f%_label}_input" 2>/dev/null || true)
        if [[ "$temp" =~ ^[0-9]+$ ]] && [ "$temp" -gt 0 ] && [ "$temp" -lt 110000 ]; then
          ambient=$(awk -v n="$temp" 'BEGIN {printf "%.1f C", n/1000}')
        fi
        ;;
    esac
  done
done
statline 'CPU TEMP' "$cpu"
statline 'CPU FAN' "$fan"
statline AMBIENT "$ambient"

if [ -z "$unit" ]; then
  state='--'
elif command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet "$unit" 2>/dev/null || systemctl --user is-active --quiet "$unit" 2>/dev/null; then
    state='RUNNING'
  else
    state='STOPPED'
  fi
else
  state='--'
fi
statline TERRARIA "$state"
