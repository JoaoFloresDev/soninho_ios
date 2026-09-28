import sys, json, time
sys.path.insert(0,'/Users/joaoflores/Documents/GambitStudio/Apps/intermediate/soninho_ios/soninho/aso-pipeline/scripts')
import astro_mcp as a
from cands import US,BR,ES,MX_EXTRA
out='/Users/joaoflores/Documents/GambitStudio/Apps/intermediate/soninho_ios/soninho/aso-pipeline/iterations/2026-09-27_iter-01-text-en-US-keywords/research/longtail_raw/'
sets={'us':US,'br':BR,'es':ES,'mx':ES+MX_EXTRA}
res={}
for s,L in sets.items():
    kws=list(dict.fromkeys(t for t,_ in L))
    for attempt in range(2):
        try:
            d,e=a.call('add_keywords',{'appId':'6758740138','keywords':kws,'store':s})
            break
        except Exception as ex:
            d,e=None,str(ex); time.sleep(10)
    res[s]={'data':d,'err':e}
    print(s,len(kws),e,(d.get('added') if isinstance(d,dict) else str(d)[:200]),flush=True)
    json.dump(res,open(out+'add_results.json','w'),ensure_ascii=False,indent=1)
