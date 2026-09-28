#!/usr/bin/env python3
"""Installs-only split (Product Type 1*/F1 = new install, 7*/F7 = update) from the
pull_analytics sales CSV. Usage: installs_split.py <sales.csv> [end YYYY-MM-DD]"""
import csv, sys, collections, datetime as dt
rows=[r for r in csv.DictReader(open(sys.argv[1])) if r['SKU'].strip()=='soninho' and not r['Parent Identifier'].strip()]
end=dt.date.fromisoformat(sys.argv[2]) if len(sys.argv)>2 else max(dt.date.fromisoformat(r['_report_date']) for r in rows)
def kind(t):
    t=t.strip()
    if t in ('1','1F','1T','F1'): return 'install'
    if t in ('7','7F','7T','F7'): return 'update'
    return 'other:'+t
print(f"Source: {sys.argv[1].split('/')[-1]} (ASC daily Sales Reports, SKU=soninho, parent empty), window ending {end}")
for w in (30,45,60):
    start=end-dt.timedelta(days=w-1)
    sel=[r for r in rows if start<=dt.date.fromisoformat(r['_report_date'])<=end]
    bt=collections.Counter(); byc=collections.Counter(); upc=collections.Counter()
    for r in sel:
        u=int(r['Units'] or 0); k=kind(r['Product Type Identifier']); bt[r['Product Type Identifier'].strip()]+=u
        if k=='install': byc[r['Country Code']]+=u
        elif k=='update': upc[r['Country Code']]+=u
    inst=sum(byc.values()); upd=sum(upc.values())
    print(f"{w}d ({start}..{end}): installs(1*)={inst} ({inst/w:.2f}/day) updates(7*)={upd} by_type={dict(bt)}")
    print(f"   installs FR={byc['FR']} DE={byc['DE']} | updates FR={upc['FR']} DE={upc['DE']} | installs us/br/es/mx={byc['US']}/{byc['BR']}/{byc['ES']}/{byc['MX']}")
    print(f"   top installs: {byc.most_common(10)}")
# weekly FR/DE installs, last 8 weeks
print("weekly installs FR / DE (7-day buckets ending on window end):")
for i in range(8,0,-1):
    e=end-dt.timedelta(days=7*(i-1)); s=e-dt.timedelta(days=6)
    c=collections.Counter()
    for r in rows:
        d=dt.date.fromisoformat(r['_report_date'])
        if s<=d<=e and kind(r['Product Type Identifier'])=='install': c[r['Country Code']]+=int(r['Units'] or 0)
    print(f"   {s}..{e}: FR={c['FR']} DE={c['DE']} all={sum(c.values())}")
