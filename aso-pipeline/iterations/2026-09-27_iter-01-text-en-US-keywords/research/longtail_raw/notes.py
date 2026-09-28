import sys, json
sys.path.insert(0,'/Users/joaoflores/Documents/GambitStudio/Apps/intermediate/soninho_ios/soninho/aso-pipeline/scripts')
import astro_mcp as a
from cands import US,BR,ES,MX_EXTRA
out='/Users/joaoflores/Documents/GambitStudio/Apps/intermediate/soninho_ios/soninho/aso-pipeline/iterations/2026-09-27_iter-01-text-en-US-keywords/research/longtail_raw/'
r=json.load(open(out+'add_results.json'))
sets={'us':US,'br':BR,'es':ES,'mx':ES+MX_EXTRA}
ok=fail=0
for s,L in sets.items():
    src=dict(L)
    for x in r[s]['data']['results']:
        if x.get('skipped'): continue
        d,e=a.call('set_keyword_note',{'appId':'6758740138','keyword':x['keyword'],'store':s,'note':'longtail-miner 2026-09-27: '+src[x['keyword']]})
        if e: fail+=1
        else: ok+=1
print(ok,fail)
