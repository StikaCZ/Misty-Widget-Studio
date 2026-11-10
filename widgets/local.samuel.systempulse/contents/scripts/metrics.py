#!/usr/bin/env python3
"""Local CPU/GPU identity and telemetry for System Pulse (no network calls)."""
from pathlib import Path
import os
import re
import shutil
import subprocess
import time


def text_file(p, default=""):
    try:
        return Path(p).read_text(encoding="utf-8", errors="replace").strip()
    except OSError:
        return default


def stat_cpu():
    parts = [int(x) for x in Path("/proc/stat").read_text().splitlines()[0].split()[1:]]
    return sum(parts), parts[3] + (parts[4] if len(parts) > 4 else 0)


def cpu_load():
    try:
        a, idle_a = stat_cpu()
        time.sleep(0.13)
        b, idle_b = stat_cpu()
        return max(0, min(100, 100 * (1 - (idle_b - idle_a) / max(1, b - a))))
    except (OSError, ValueError, IndexError, ZeroDivisionError):
        return None


def cpu_identity(info_text=None):
    if info_text is None:
        info_text = text_file("/proc/cpuinfo")
    sections = [s for s in info_text.split("\n\n") if s.strip()]
    first = {}
    logical = 0
    physical = set()
    for section in sections:
        fields = {}
        for line in section.splitlines():
            k, sep, value = line.partition(":")
            if sep:
                fields[k.strip().lower()] = value.strip()
        if not first and fields:
            first = fields
        if "processor" in fields:
            logical += 1
        if "physical id" in fields and "core id" in fields:
            physical.add((fields["physical id"], fields["core id"]))
    name = first.get("model name") or first.get("hardware") or first.get("processor") or "Unknown processor"
    name = re.sub(r"\s+", " ", name).strip()
    vendor_field = (first.get("vendor_id") or first.get("cpu implementer") or "").lower()
    low = name.lower()
    if "authenticamd" in vendor_field or "amd" in low or "ryzen" in low:
        vendor = "amd"
    elif "genuineintel" in vendor_field or "intel" in low:
        vendor = "intel"
    elif "arm" in vendor_field or "aarch" in low:
        vendor = "arm"
    else:
        vendor = "generic"
    try:
        cores = len(physical) if physical else int(first.get("cpu cores", "0"))
    except ValueError:
        cores = 0
    threads = logical or os.cpu_count() or 0
    if cores < 1:
        cores = max(1, threads)
    # QML line-oriented protocol: never emit newlines / '=' from device names.
    return vendor, name.replace("=", " "), cores, threads


def cpu_temp():
    for root in Path('/sys/class/hwmon').glob('hwmon*'):
        name = text_file(root / 'name').lower()
        if name not in ('k10temp', 'coretemp', 'zenpower', 'cpu_thermal', 'acpitz'):
            continue
        for inp in sorted(root.glob('temp*_input')):
            try:
                val = float(inp.read_text()) / 1000
                if 0 < val < 130:
                    return val
            except (OSError, ValueError):
                pass
    return None


def cpu_clock():
    try:
        return float(text_file('/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq')) / 1_000_000
    except ValueError:
        pass
    for line in text_file('/proc/cpuinfo').splitlines():
        if line.startswith('cpu MHz'):
            try:
                return float(line.split(':', 1)[1].strip()) / 1000
            except ValueError:
                pass
    return None


def mem():
    values = {}
    for line in text_file('/proc/meminfo').splitlines():
        key, sep, value = line.partition(':')
        if sep and key in ('MemTotal', 'MemAvailable'):
            try:
                values[key] = int(value.strip().split()[0])
            except (ValueError, IndexError):
                pass
    total = values.get('MemTotal', 0) / 1048576
    avail = values.get('MemAvailable', 0) / 1048576
    return total, max(0, total - avail)


def number(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def detect_pci_gpu():
    """Prefer discrete cards; lspci only improves the optional model label."""
    found = []
    for card in sorted(Path('/sys/class/drm').glob('card[0-9]*')):
        device = card / 'device'
        vendor_id = text_file(device / 'vendor').lower()
        if vendor_id not in ('0x10de', '0x1002', '0x8086'):
            continue
        vendor = {'0x10de': 'nvidia', '0x1002': 'amd', '0x8086': 'intel'}[vendor_id]
        fallback = {'nvidia': 'NVIDIA Graphics', 'amd': 'AMD Radeon Graphics', 'intel': 'Intel Graphics'}[vendor]
        name = fallback
        slot = text_file(device / 'uevent')
        match = re.search(r'^PCI_SLOT_NAME=([^\s]+)', slot, re.M)
        if match and shutil.which('lspci'):
            try:
                res = subprocess.run(['lspci', '-s', match.group(1)], capture_output=True,
                                     text=True, timeout=1, check=False)
                desc = res.stdout.partition(': ')[2].strip()
                if desc:
                    name = desc.split(' (rev ')[0]
            except (OSError, subprocess.TimeoutExpired):
                pass
        # boot_vga=1 usually designates the primary GPU (not necessarily discrete).
        integrated = ('integrated' in name.lower() or 'uhd' in name.lower() or 'iris' in name.lower())
        rank = (3 if vendor == 'nvidia' else 2 if vendor == 'amd' else 1) - (1 if integrated else 0)
        found.append((rank, vendor, name, device))
    if not found:
        return 'generic', 'Graphics card not detected', None
    _, vendor, name, device = max(found, key=lambda v: v[0])
    return vendor, re.sub(r'\s+', ' ', name).replace('=', ' '), device


def gpu_metrics():
    """Return vendor, model, and optional usage/temp/clock/fan/VRAM figures."""
    if shutil.which('nvidia-smi'):
        fields = 'name,utilization.gpu,temperature.gpu,clocks.gr,fan.speed,memory.used,memory.total'
        try:
            res = subprocess.run(['nvidia-smi', '--query-gpu=' + fields,
                                 '--format=csv,noheader,nounits', '-i', '0'],
                                 text=True, capture_output=True, timeout=3, check=False)
            if res.returncode == 0 and res.stdout.strip():
                columns = [s.strip() for s in res.stdout.splitlines()[0].split(',')]
                if len(columns) >= 7:
                    name = re.sub(r'\s+', ' ', columns[0]).replace('=', ' ')
                    return ('nvidia', name, *[number(x) for x in columns[1:7]])
        except (OSError, subprocess.TimeoutExpired, IndexError):
            pass
    vendor, model, device = detect_pci_gpu()
    metrics = [None] * 6
    if device is not None:
        metrics[0] = number(text_file(device / 'gpu_busy_percent'))
        for sensor in (device / 'hwmon').glob('hwmon*/temp1_input'):
            value = number(text_file(sensor))
            if value is not None:
                metrics[1] = value / 1000
                break
        # AMD VRAM sysfs is in bytes. Intel iGPUs may not expose dedicated VRAM.
        used = number(text_file(device / 'mem_info_vram_used'))
        total = number(text_file(device / 'mem_info_vram_total'))
        metrics[4] = used / 1048576 if used is not None else None
        metrics[5] = total / 1048576 if total is not None else None
    return (vendor, model, *metrics)


def fmt(value, digits=1):
    return '--' if value is None else f'{value:.{digits}f}'


def collect():
    cpu_vendor, cpu_model, cores, threads = cpu_identity()
    gpu_vendor, gpu_model, gpu_usage, gpu_temp, gpu_clock, gpu_fan, vram_used, vram_total = gpu_metrics()
    ram_total, ram_used = mem()
    rows = {
        'CPU_VENDOR': cpu_vendor, 'CPU_MODEL': cpu_model, 'CPU_CORES': cores, 'CPU_THREADS': threads,
        'GPU_VENDOR': gpu_vendor, 'GPU_MODEL': gpu_model,
        'CPU_USAGE': fmt(cpu_load()), 'CPU_TEMP': fmt(cpu_temp()), 'CPU_CLOCK': fmt(cpu_clock(), 2),
        'GPU_USAGE': fmt(gpu_usage), 'GPU_TEMP': fmt(gpu_temp),
        'GPU_CLOCK': fmt(gpu_clock / 1000 if gpu_vendor == 'nvidia' and gpu_clock is not None else gpu_clock, 2),
        'GPU_FAN': fmt(gpu_fan), 'RAM_USED': fmt(ram_used), 'RAM_TOTAL': fmt(ram_total),
        'VRAM_USED': fmt(vram_used / 1024 if vram_used is not None else None),
        'VRAM_TOTAL': fmt(vram_total / 1024 if vram_total is not None else None)
    }
    return rows


if __name__ == '__main__':
    for key, value in collect().items():
        print(f'{key}={str(value).replace(chr(10), " ")}')
