import sys, json, time
sys.path.insert(0,'/Users/joaoflores/Documents/GambitStudio/Apps/intermediate/soninho_ios/soninho/aso-pipeline/scripts')
import astro_mcp as a
store=sys.argv[1]; seeds=sys.argv[2].split('|')
out='/Users/joaoflores/Documents/GambitStudio/Apps/intermediate/soninho_ios/soninho/aso-pipeline/iterations/2026-09-28_iter-02-text-fr-FR-keywords/research/longtail_raw/'
import os
fn=out+f'competitor_extract_{store}.json'
res=json.load(open(fn)) if os.path.exists(fn) else {}
for k in seeds:
    if res.get(k,{}).get('data'): continue
    t=time.time()
    try:
        d,e=a.call('extract_competitors_keywords',{'appId':'6758740138','keyword':k,'store':store,'platform':'iphone'})
    except Exception as ex:
        d,e=None,str(ex)
    res[k]={'data':d,'err':e}
    print(store,k,round(time.time()-t),(len(d) if isinstance(d,list) else str(d)[:150]),e,flush=True)
    json.dump(res,open(out+f'competitor_extract_{store}.json','w'),ensure_ascii=False,indent=1)
