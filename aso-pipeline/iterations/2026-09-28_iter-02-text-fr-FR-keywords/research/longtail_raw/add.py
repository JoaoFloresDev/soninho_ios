import sys, json, time, os
sys.path.insert(0,'/Users/joaoflores/Documents/GambitStudio/Apps/intermediate/soninho_ios/soninho/aso-pipeline/scripts')
import astro_mcp as a
from cands import FR, DE
out=os.path.dirname(os.path.abspath(__file__))+'/'
store=sys.argv[1]; L={'fr':FR,'de':DE}[store]
tracked={k['keyword'] for k in json.load(open(out+f'tracked_before_{store}.json'))['keywords']}
fn=out+f'add_results_{store}.json'
res=json.load(open(fn)) if os.path.exists(fn) else {}
kws=[t for t in dict.fromkeys(t for t,_ in L) if t not in tracked and not res.get(t,{}).get('ok')]
print(store,'to add',len(kws),flush=True)
for i in range(0,len(kws),10):
    b=kws[i:i+10]; t0=time.time()
    try:
        d,e=a.call('add_keywords',{'appId':'6758740138','keywords':b,'store':store,'platform':'iphone'})
    except Exception as ex:
        d,e=None,str(ex)
    ok = e is None and isinstance(d,dict)
    for k in b: res[k]={'ok':ok,'err':str(e)[:200] if e else None}
    if ok:
        for r in d.get('results',[]):
            kk=r.get('keyword') or r.get('text')
            if kk in res: res[kk]['r']=r
    print(i//10+1,round(time.time()-t0),ok,(str(d)[:160] if not ok else d.get('added')),flush=True)
    json.dump(res,open(fn,'w'),ensure_ascii=False,indent=1)
    if not ok: break
