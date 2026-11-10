#!/usr/bin/env python3
"""Optional read-only Terraria service status via the bundled Homelab SSH checker.

Configuration is local and never included in the public release.
"""
import json
from pathlib import Path
import subprocess
import sys
import re

SETTINGS=Path.home()/'.config/misty-widget-studio/terraria.json'
HOMELAB=Path(__file__).resolve().parents[3]/'local.samuel.homelab/contents/scripts/homelab_stats.py'

def output(reachable=False,service='unknown',error='', host_uptime='—'):
    print(json.dumps({'reachable':reachable,'service':service,'world':'—',
        'players':None,'serviceUptime':'—','hostUptime':host_uptime,'ramMiB':None,'error':error}))

def main():
    if not SETTINGS.is_file():
        output(error='Configure ~/.config/misty-widget-studio/terraria.json to enable SSH monitoring')
        return
    try:
        doc=json.loads(SETTINGS.read_text(encoding='utf-8'))
        if not isinstance(doc,dict):raise ValueError('Expected a JSON object')
        # The checker validates every supplied argument before invoking ssh.
        args=[sys.executable,str(HOMELAB),'--host',str(doc.get('host','')),
            '--user',str(doc.get('user','')),'--port',str(doc.get('port',22)),
            '--identity',str(doc.get('identity','')),
            '--unit',str(doc.get('unit','tmodloader.service'))]
        process=subprocess.run(args,text=True,capture_output=True,timeout=16,check=False)
        values={}
        for line in process.stdout.splitlines():
            match=re.match(r'^([A-Z][A-Z0-9 ()/-]*)  (.*)$',line)
            if match:values[match.group(1)]=match.group(2)
        if values.get('STATUS')!='ONLINE':
            output(error=values.get('DETAIL','SSH unavailable'));return
        state='active' if values.get('TERRARIA')=='RUNNING' else 'inactive'
        output(True,state,'',values.get('UPTIME','—'))
    except (OSError,ValueError,TypeError,subprocess.TimeoutExpired,json.JSONDecodeError) as exc:
        output(error='Server configuration or SSH check failed')

if __name__=='__main__':main()
