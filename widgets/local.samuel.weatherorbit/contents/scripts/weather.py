#!/usr/bin/env python3
"""Weather through public Open-Meteo endpoints. Sends *city name* only when the widget refreshes.

No API key. Uses HTTPS, fixed allowlisted hosts, simple local 10-minute cache.
"""
import argparse, json, os, re, time
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urlencode
from urllib.error import URLError

CACHE=Path(os.getenv('XDG_CACHE_HOME', str(Path.home()/'.cache')))/'misty-widget-studio'

def fetch(host, route, params):
    url='https://'+host+route+'?'+urlencode(params)
    with urlopen(Request(url,headers={'User-Agent':'Misty-Widget-Studio/4.6.1'}),timeout=6) as r:
        if r.geturl().split('/')[2]!=host:raise ValueError('Unexpected weather redirect')
        return json.load(r)

def condition(code):
    if code in (0,1):return ('Clear','clear')
    if code in (2,3):return ('Cloudy','cloud')
    if code in (45,48):return ('Fog','cloud')
    if 51<=code<=67 or code in (80,81,82):return ('Rain','rain')
    if 71<=code<=77 or code in (85,86):return ('Snow','snow')
    if code in (95,96,99):return ('Storm','storm')
    return ('Weather','cloud')

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--city',default='London')
    args=parser.parse_args()
    city=args.city.strip()[:80]
    if not city or any(ord(c)<32 for c in city):
        print(json.dumps({'cityQuery':city,'error':'Choose a city'}));return
    import hashlib
    key=hashlib.sha256(city.casefold().encode()).hexdigest()[:20]
    cached=CACHE/(f'{key}.json')
    try:
        if cached.is_file() and time.time()-cached.stat().st_mtime<600:
            print(cached.read_text());return
        geo=fetch('geocoding-api.open-meteo.com','/v1/search',{'name':city,'count':1,'language':'en','format':'json'})
        if not geo.get('results'):
            print(json.dumps({'cityQuery':city,'error':'City not found'}));return
        loc=geo['results'][0]
        opts={'latitude':loc['latitude'],'longitude':loc['longitude'],
              'current':'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation_probability,is_day,weather_code,wind_speed_10m',
              'daily':'temperature_2m_max,temperature_2m_min,weather_code',
              'timezone':'auto','forecast_days':3}
        weather=fetch('api.open-meteo.com','/v1/forecast',opts)
        c=weather.get('current',{})
        label,icon=condition(int(c.get('weather_code',2)))
        days=weather.get('daily',{})
        daily=[]
        for i, d in enumerate(days.get('time',[])[:3]):
            from datetime import date
            try: name=date.fromisoformat(d).strftime('%a').upper()
            except ValueError:name='DAY'
            daily.append({'label':name,'hi':days['temperature_2m_max'][i],
                          'lo':days['temperature_2m_min'][i]})
        result={'cityQuery':city,'city':loc['name'],'temp':c.get('temperature_2m'),
                'feels':c.get('apparent_temperature'),'wind':c.get('wind_speed_10m'),
                'humidity':c.get('relative_humidity_2m'),'rain':c.get('precipitation_probability'),
                'isDay':bool(c.get('is_day',1)),'condition':label,'icon':icon,
                'daily':daily,'stale':False}
        CACHE.mkdir(parents=True,exist_ok=True)
        cached.write_text(json.dumps(result))
        print(json.dumps(result))
    except (URLError,TimeoutError,OSError,KeyError,TypeError,ValueError,IndexError) as exc:
        if cached.is_file():
            try:
                result=json.loads(cached.read_text());result['stale']=True
                print(json.dumps(result));return
            except (OSError,json.JSONDecodeError):pass
        print(json.dumps({'cityQuery':city,'error':'Weather unavailable (check your internet)'}))

if __name__=='__main__':main()
