#!/usr/bin/env python3
"""Plasma 6 Network Radar helper: local Linux counters only, no network calls."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

def iface_name():
    route=Path('/proc/net/route')
    if route.exists():
        for row in route.read_text(errors='replace').splitlines()[1:]:
            a=row.split()
            if len(a)>3 and a[1]=='00000000' and int(a[3],16)&1:
                return a[0]
    d=Path('/sys/class/net')
    if d.exists():
        for p in d.iterdir():
            if p.name!='lo' and (p/'operstate').read_text().strip()=='up':
                return p.name
    return None

def safe_counter(dev,name):
    try:
        return int((Path('/sys/class/net')/dev/'statistics'/name).read_text())
    except (ValueError,OSError):
        return 0

def active_ssid(dev):
    if not (Path('/sys/class/net')/dev/'wireless').exists():
        return 'Ethernet' if not dev.startswith('wl') else 'Wi-Fi'
    try:
        result=subprocess.run(['nmcli','-g','GENERAL.CONNECTION','device','show',dev],text=True,capture_output=True,timeout=2,check=False)
        if result.returncode==0:
            return result.stdout.strip().splitlines()[0][:80] or 'Wi-Fi'
    except (OSError,subprocess.TimeoutExpired,IndexError):
        pass
    return 'Wi-Fi'

def main():
    dev=iface_name()
    result={'online':bool(dev),'iface':dev or '--','ssid':active_ssid(dev) if dev else 'Not connected',
            'downMbps':0.0,'upMbps':0.0,'pingMs':None,'signalDbm':None,'signalPercent':None}
    if not dev:
        print(json.dumps(result));return
    now=time.monotonic()
    rx=safe_counter(dev,'rx_bytes');tx=safe_counter(dev,'tx_bytes')
    state_base=Path(os.environ.get('XDG_RUNTIME_DIR') or str(Path.home()/'.cache'))/'stikacz-networkradar'
    state_base.mkdir(mode=0o700,parents=True,exist_ok=True)
    snapshot=state_base/f'{dev}.json'
    try:
        prev=json.loads(snapshot.read_text())
        elapsed=now-float(prev.get('t',now))
        if 0.2 < elapsed < 120:
            result['downMbps']=round(max(0,rx-int(prev.get('rx',rx)))*8/elapsed/1_000_000,2)
            result['upMbps']=round(max(0,tx-int(prev.get('tx',tx)))*8/elapsed/1_000_000,2)
    except (OSError,ValueError,TypeError,json.JSONDecodeError):
        pass
    fd,tmp=tempfile.mkstemp(prefix='state-',dir=str(state_base))
    try:
        with os.fdopen(fd,'w') as f: json.dump({'t':now,'rx':rx,'tx':tx},f)
        os.replace(tmp,snapshot)
    finally:
        if os.path.exists(tmp): os.unlink(tmp)
    # Local kernel Wi-Fi quality (if exposed by the driver)
    try:
        lines=Path('/proc/net/wireless').read_text().splitlines()[2:]
        for line in lines:
            if not line.lstrip().startswith(dev+':'):continue
            fields=line.split(':',1)[1].split()
            quality=float(fields[1].rstrip('.'))
            level=float(fields[2].rstrip('.'))
            result['signalPercent']=int(max(0,min(100,quality/70*100)))
            result['signalDbm']=level
            break
    except (OSError,IndexError,ValueError):
        pass
    print(json.dumps(result,ensure_ascii=False))
if __name__=='__main__':
    try: main()
    except Exception: print(json.dumps({'online':False,'iface':'--','ssid':'Unavailable','downMbps':0,'upMbps':0,'pingMs':None,'signalDbm':None,'signalPercent':None}))
