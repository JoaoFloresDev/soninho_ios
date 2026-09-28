import json, csv, unicodedata, re, sys
from cands import US,BR,ES,MX_EXTRA
R='/Users/joaoflores/Documents/GambitStudio/Apps/intermediate/soninho_ios/soninho/aso-pipeline/iterations/2026-09-27_iter-01-text-en-US-keywords/research/'
def n(t): return ''.join(c for c in unicodedata.normalize('NFD',t.lower()) if unicodedata.category(c)!='Mn')
STOP=set('for with to the a an and at of my me i that you de do da dos das com con para el la los las del y e que al o em no'.split())
STOP.discard('no')
FIELDS={
 'us':"sunrise alarm clock wake up gentle light heavy sleepers mission math puzzle snooze loud sounds dawn sun lamp morning routine sleep cycle tracker smart",
 'br':"sunrise alarm clock alarme despertador com luz e missoes acordar cedo sono pesado soneca matematica relogio forte alto manha dorminhoco ciclo amanhecer",
 'es':"sunrise alarm clock alarma despertador con luz y mision despertar temprano sueno pesado matematicas reloj fuerte manana dormilon ciclo amanecer suave",
}
FIELDS['mx']=FIELDS['es']
SECOND={'br':FIELDS['us'],'mx':FIELDS['us']}  # BR and MX storefronts also index en-US
def toks(s): return set(n(s).split())
def stem(w): return w[:-2] if w.endswith('es') and len(w)>4 else (w[:-1] if w.endswith('s') and len(w)>3 else w)
def covered(w,F): return w in F or stem(w) in {stem(x) for x in F}
CORE={
 'us':[('heavy sleeper',['heavy sleep','deep sleep']),('mission',['mission']),('math',['math']),('puzzle',['puzzle']),('snooze',['snooz']),('shake',['shake']),('challenge',['challenge']),('loud',['loud','annoying','max volume','siren']),('sunrise',['sunrise','my sunrise']),('morning',['morning']),('wake',['wake','waking','awake']),
       ('gentle',['gentle']),('light',['light','lamp','glow']),('dawn/sun',['dawn','sun']),('sounds',['sound','music']),('routine',['routine']),('sleep/cycle/tracker',['sleep','cycle','tracker','snore']),('smart',['smart']),('clock',['clock']),('alarm',['alarm'])],
 'br':[('sono pesado',['sono pesado']),('soneca',['soneca','adiar']),('missao/desafio',['missao','missoes','desafio','tarefa','jogo']),('matematica',['matematic','conta']),('forte/alto',['forte','alto','altos','barulhento','sons','som ','toque']),('amanhecer',['amanhecer','nascer do sol','sunrise','sol']),('luz',['luz']),('acordar',['acordar','acorde','despertar']),('dorminhoco',['dorminhoco']),('ciclo/sono',['ciclo','sono','rem']),('relogio',['relogio']),('rotina/manha',['rotina','manha','cedo']),('alarme',['alarme']),('despertador',['despertador']),('EN: alarm/clock',['alarm','clock','wake'])],
}
CORE['es']=[('sueño pesado',['sueno pesado']),('posponer/snooze',['posponer','snooze']),('mision/reto',['mision','reto','juego','puzle','puzzle','tarea','levantate']),('matematicas',['matemat']),('fuerte',['fuerte','ruidos','sonido','tonos']),('amanecer',['amanecer','salida del sol','sunrise',' sol']),('luz',['luz']),('despertar',['despertar']),('dormilon',['dormilon']),('ciclo/sueño',['ciclo','sueno']),('reloj',['reloj']),('temprano/mañana',['temprano','manana']),('suave/gradual',['suave','gradual','progresivo']),('alarma',['alarma']),('despertador',['despertador']),('EN: alarm/clock',['alarm','clock','wake'])]
CORE['mx']=CORE['es']
def core_of(s,t):
    tt=' '+n(t)+' '
    for c,pats in CORE[s]:
        for p in pats:
            if p in tt: return c
    return None
LOC={'us':'en-US','br':'pt-BR','es':'es-ES','mx':'es-MX'}
MINED={'us':dict(US),'br':dict(BR),'es':dict(ES),'mx':dict(ES+MX_EXTRA)}
EXTRA_SUG={'us':{'alarm math','sleepers','light alarm','sunrise','sunrise alarm','alarm clock for heavy sleepers','math alarm clock','despertador','sunrise alarm clock','gentle alarm','gentle alarm clock','loudest alarm clock','wake'},
 'br':{'sunrise alarm','relogio despertador','alarme despertador','sunrise alarm clock'},
 'es':{'sunrise alarm','despertador matematicas','despertador amanecer','sunrise alarm clock','amanecer','sunrise'},'mx':set()}
summary={}
for s in ['us','br','es','mx']:
    d=json.load(open(R+f'longtail_raw/tracked_after_{s}.json'))['keywords']
    prior={}
    for f in [f'current_pool_{LOC[s]}.csv',f'candidates_{LOC[s]}.csv']:
        try:
            for r in csv.DictReader(open(R+f)): prior.setdefault(r['Keyword'],r.get('Note') or '')
        except FileNotFoundError: pass
    F=toks(FIELDS[s]); F2=toks(SECOND.get(s,''))
    rows=[]
    for k in d:
        t=k['keyword']; words=n(t).split()
        mined=t in MINED[s]
        if len(words)<2 and not mined: continue
        c=core_of(s,t)
        if not c: continue
        if mined: src='stage2 '+MINED[s][t]
        else:
            src='stage1/prior tracked'+(': '+prior[t] if prior.get(t) else '')
            if n(t) in {n(x) for x in EXTRA_SUG[s]}: src+=' | also SUG '+s+' suggestion 2026-09-27'
        miss=[w for w in words if w not in STOP and not covered(w,F)]
        if not miss: comp='FREE (all tokens in '+LOC[s]+' fields)'
        else:
            miss2=[w for w in miss if not covered(w,F2)] if F2 else miss
            comp='NEEDS: '+','.join(miss)
            if F2 and not miss2: comp+=' (covered by en-US secondary index)'
        rk=k.get('currentRanking'); rk='OUT' if rk in (None,0,1001,'OUT') or (isinstance(rk,int) and rk>=1000) else rk
        rows.append([c,t,src,k.get('popularity'),k.get('difficulty'),rk,k.get('appsCount'),comp])
    order=[c for c,_ in CORE[s]]
    rows.sort(key=lambda r:(order.index(r[0]),-(r[3] or 0),r[1]))
    fn=R+f'longtails_{s}_2026-09-27.csv'
    with open(fn,'w',newline='') as f:
        w=csv.writer(f); w.writerow(['Core Word','Long Tail','Source','Popularity','Difficulty','Our Ranking','Apps in Ranking','Composition'])
        w.writerows(rows)
    summary[s]=rows
    print(s,len(rows),fn)
json.dump(summary,open('/private/tmp/claude-501/-Users-joaoflores-Documents-GambitStudio/b1960c1e-83b3-4369-b155-0deabc234676/scratchpad/summary.json','w'),ensure_ascii=False)
