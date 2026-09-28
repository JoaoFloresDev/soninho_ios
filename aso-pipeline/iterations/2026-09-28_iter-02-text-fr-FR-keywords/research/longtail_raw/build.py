import json, csv, unicodedata, re, os
from cands import FR, DE
out=os.path.dirname(os.path.abspath(__file__))+'/'; R=out+'../'
M='/Users/joaoflores/Documents/GambitStudio/Apps/intermediate/soninho_ios/soninho/aso-pipeline/current/metadata/'
def n(t): return ''.join(c for c in unicodedata.normalize('NFD',t.lower()) if unicodedata.category(c)!='Mn')
def words(t): return [w for w in re.split(r"[\s\-'’&,:]+", n(t)) if w]
STOP={'fr':set('de du des la le les a au aux pour avec et en un une mon ma d l qui'.split()),
      'de':set('fur mit und zum zur der die das im in den dem mein fuer'.split())}
EN_STOP=set('for with to the a an and at of my'.split())
def fields(loc): return ' '.join(open(M+f'{loc}/{f}.txt').read() for f in ('name','subtitle','keywords'))
F={'fr':set(words(fields('fr-FR'))),'de':set(words(fields('de-DE')))}
EN=set(words(fields('en-GB')))
def _pl(w,f,lang):
    ends=['s','x'] if lang=='fr' else ['n','en','e','s']
    return any(w==f+e or f==w+e for e in ends)
def _stem(w):
    for e in ('en','er','es','em','e','n','s'):
        if w.endswith(e) and len(w)-len(e)>=4: return w[:-len(e)]
    return w
def match(w,S,lang):
    """2 exact/plural, 1 inflection-only, 0 none"""
    best=0
    for f in S:
        if w==f or _pl(w,f,lang): return 2
        if _stem(w)==_stem(f) or (len(f)>=4 and w.startswith(f) and len(w)-len(f)<=2) or (len(w)>=4 and f.startswith(w) and len(f)-len(w)<=2):
            best=1
    return best
CORE={
'fr':[('sommeil lourd / gros dormeur',['sommeil lourd','sommeil profond','gros dormeur','dormeurs','heavy sleeper','anti-sommeil','anti sommeil','difficile']),
      ('mission/défi',['mission','defi','casse','jeu','puzzle']),('calcul/maths',['calcul','math','mathe']),
      ('snooze/répétition',['snooze','repetition']),
      ('lever du soleil/aube',['lever du soleil','lever de soleil','soleil','aube','aurore','sunrise','simulat']),
      ('lumière',['lumiere','lumineux','lampe','light']),('doux/progressif',['doux','douce','douceur','progressi','naturel','gentle','leger','sommeil leger']),
      ('fort/sonnerie',['fort','forte','fortes','puissant','sonnerie','loud']),
      ('cycle/suivi sommeil',['cycle','suivi','tracker','analyse','ronflement','phase','intelligent','smart']),
      ('matin/se lever/tôt',['matin','lever','leve','tot','debout']),
      ('réveiller (verbe)',['reveiller','reveille-toi','reveille toi','wake','waking']),
      ('réveil (head)',['reveil','reveille']),('alarme (head)',['alarme','alarmes','alarm','clock','sommeil'])],
'de':[('Tiefschläfer/Langschläfer',['tiefschlafer','langschlafer','schlafmutze','verschlafen','heavy sleeper']),
      ('Aufgaben/Mission',['aufgabe','mission','ratsel','spiel','barcode','qr ','nfc','foto','bewegung','puzzle']),
      ('Mathe/Rechnen',['mathe','math','rechen','kopfrechnen']),('Schlummern/Snooze',['schlummer','snooze']),
      ('Sonnenaufgang',['sonnenaufgang','sunrise','simulat']),('Licht',['licht','light','led']),
      ('sanft',['sanft','naturlich','gentle']),('laut',['laut','extrem','loud']),
      ('Schlafzyklus/Schlafphase',['schlafzyklus','schlafphase','schlaf','smart','intelligent']),
      ('Morgen/früh',['morgen','fruh','morning']),
      ('aufwachen/aufstehen',['aufwach','aufsteh','wecken','wach ','wake','waking']),
      ('Wecker (head)',['wecker']),('Alarm (head)',['alarm','clock'])]}
def core_of(s,t):
    tt=' '+n(t)+' '
    for c,pats in CORE[s]:
        for p in pats:
            if n(p) in tt: return c
    return None
LOC={'fr':'fr-FR','de':'de-DE'}
MINED={'fr':dict(FR),'de':dict(DE)}
SUG={}
for s in ('fr','de'):
    SUG[s]={x['text'] for x in json.load(open(out+f'suggestions_{s}_all.json'))['data']}
EXTC={}
for s in ('fr','de'):
    ex=json.load(open(out+f'competitor_extract_{s}.json')); m={}
    for seed,v in ex.items():
        if isinstance(v.get('data'),dict):
            for x in v['data']['keywords']:
                if ' ' in x['text']: m.setdefault(x['text'],[]).append(seed)
    EXTC[s]=m
summary={}
for s in ('fr','de'):
    d=json.load(open(out+f'tracked_after_{s}.json'))['keywords']
    prior={}
    for f in [f'current_pool_{LOC[s]}.csv',f'candidates_{LOC[s]}.csv']:
        for r in csv.DictReader(open(R+f)): prior.setdefault(r['Keyword'],r.get('Note') or '')
    rows=[]
    for k in d:
        t=k['keyword']; ws=words(t); mined=t in MINED[s]
        if len(ws)<2 and not mined and t not in SUG[s]: continue
        c=core_of(s,t)
        if not c: continue
        if mined: src='stage2 '+MINED[s][t]
        else:
            src='stage1/prior tracked'+(': '+prior[t] if prior.get(t) else '')
            if t in SUG[s]: src+=f' | also SUG {s} suggestion 2026-09-28'
            if t in EXTC[s]: src+=f" | also EXT {s} combo (seeds: {', '.join(EXTC[s][t][:3])})"
        src+=' | vol: astro-only (pop não confiável)'
        toks=[w for w in ws if w not in STOP[s] and w not in EN_STOP]
        miss=[];infl=[];viaen=[]
        for w in toks:
            m=match(w,F[s],s)
            if m==2: continue
            if match(w,EN,'en')==2: viaen.append(w); continue
            if m==1: infl.append(w); continue
            miss.append(w)
        if miss:
            comp='NEEDS: '+','.join(miss)
            extra=[]
            if viaen: extra.append(','.join(viaen)+' in en-GB')
            if infl: extra.append(','.join(infl)+' only as inflection of a field token')
            if extra: comp+=' ('+'; '.join(extra)+')'
        elif infl:
            comp='FREE~ inflection: '+','.join(infl)+' (inflected form of a field token)'+(f'; {",".join(viaen)} via en-GB' if viaen else '')
        elif viaen:
            comp=f'FREE via en-GB ({",".join(viaen)} in en-GB fields, secondary index {s})'
        else:
            comp=f'FREE (all tokens in {LOC[s]} fields)'
        rk=k.get('currentRanking'); rk='OUT' if (rk in (None,0) or (isinstance(rk,int) and rk>=1000)) else rk
        rows.append([c,t,src,k.get('popularity'),k.get('difficulty'),rk,k.get('appsCount'),comp])
    order=[c for c,_ in CORE[s]]
    rows.sort(key=lambda r:(order.index(r[0]),-(r[3] or 0),r[1]))
    fn=R+f'longtails_{s}_2026-09-28.csv'
    with open(fn,'w',newline='') as f:
        w=csv.writer(f); w.writerow(['Core Word','Long Tail','Source','Popularity','Difficulty','Our Ranking','Apps in Ranking','Composition'])
        w.writerows(rows)
    summary[s]=rows; print(s,len(rows),fn)
json.dump(summary,open(out+'summary.json','w'),ensure_ascii=False)
