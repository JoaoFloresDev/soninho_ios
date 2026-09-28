# Sunrise Alarm Clock · iter-02 · fr-FR + de-DE (os 2 locales extras da regra dos 5; en-US/es-ES/pt-BR estão na iter-01, mesma versão 1.4.0)

## Locales

Instalações novas (1*) em 90 dias, de 30/06 a 27/09, total de 364. Fonte: `research/locales.json` (`top_locales.py`).

| Slot | Locale | Países | Installs 1* / 90d | Share | Onde está |
|---|---|---|---|---|---|
| base | pt-BR | BR 48 | 48 | 13,2% | iter-01 |
| base | en-US | US 36, PH 3 | 39 | 10,7% | iter-01 |
| base | es-ES | ES 33 | 33 | 9,1% | iter-01 |
| **top-2 #1** | **fr-FR** | FR 42 | **42** | **11,5%** | **esta iter** |
| **top-2 #2** | `sem tráfego suficiente` | melhor abaixo do piso: **de-DE** (DE 25, CH 3, AT 1) | **29** | 8,0% | esta iter, só como **controle** |

O de-DE fica **1 instalação abaixo do piso de 30**. Ele entra aqui sem troca de token (a proposta dele é só normalização opcional). A recomendação é **não aplicar nada no de-DE**: sem mudança de texto, o DE vira o controle natural dos prints novos da 1.4.0 (ver Riscos 2).

**Rating-first:** 0 ratings em fr e de, 1 no app inteiro (br). Por isso a iteração é conservadora: 2 apostas, nenhum token com ranking sai. **Todo volume aqui é astro-only.** Não existe report de search terms do ASC nem Apple Ads para estas lojas, então todo pop é `pop não confiável`.

---

## 📄 Resultado final

### fr-FR (loja fr, que também é índice secundário de BE, CH e LU)

| Campo | Antes (no ar) | Depois (aplicado) |
|---|---|---|
| title | Sunrise Alarm Clock : Réveil (28) | Sunrise Alarm Clock : Réveil (28) |
| subtitle | Lumière douce, sommeil lourd (28) | Lumière douce, sommeil lourd (28) |
| keywords | matin,se lever,tôt,alarme,mission,maths,fort,sonnerie,cycle,aube,gros dormeur,<span style="color:#dc3545">suivi</span>,réveiller (93) | <span style="color:#28a745">defis</span>,<span style="color:#28a745">leger</span>,se lever,tot,reveiller,alarme,aube,matin,gros dormeur,fort,maths,cycle,sonnerie,mission (99) |

**Por quê:**
- <span style="color:#28a745">`defis`</span>: `réveil avec défis` (pop 5) está OUT → alvo **#1-5** até D28. A SERP tem 9 apps e o top 3 tem 0-1 ratings (Réveil avec Missions et Défi 0, WakeBolt 0, RiseUp 1). `réveil à défis` está OUT → **#1-5** (6 apps, top 3 com 0-1 ratings), e `réveil défis` está OUT → **#3-10**. Risco: o volume pode ser próximo de zero (pop não confiável). Se o token passar 14 dias no ar sem rank, troca por `anti` (`réveil anti snooze` OUT → #3-10).
- <span style="color:#28a745">`leger`</span>: `réveil léger` (pop 5) está OUT → alvo **#1-5**. A SERP tem 5 apps, e o incumbente Wake Up Light tem 11 ratings. `réveil sommeil léger` está OUT → **#1-5** (5 apps). Risco: `sommeil léger` (PARTIAL, SERP de sons pra dormir) pode trazer impressão sem tap. Nenhum alvo depende dele.
- <span style="color:#dc3545">`suivi`</span>: não protege nenhuma posição. `suivi de sommeil` (pop 26) está OUT e é LOTTERY: o top 3 tem 4.097 a 38.082 ratings, sem alvo em 28 dias. `suivi cycle` leva pra SERP de ciclo menstrual (10/10). Custo de ranking: zero.
- `tot`/`reveiller` sem acento: `se réveiller tôt` está **#5**, `se lever tôt` **#7**, `lever tôt` #13, `réveil tôt` #15. Todas seguram. Risco: se alguma cair mais de 5 posições no D7, o acento volta em 1 PATCH.
- Protegidas (todos os tokens ficam): `réveil lumière douce` **#2**, `lumière réveil` **#3**, cluster `sommeil lourd` **#4** (5 composições), `réveil sunrise` **#4**, `se réveiller tôt` **#5**, `sunrise alarm clock` **#7** (pop 27), `alarme douce` **#7**, `se lever tôt` **#7**, `réveil aube` **#9**.

### de-DE (loja de, que também é índice principal de CH e AT)

| Campo | Antes (no ar) | Depois (aplicado) |
|---|---|---|
| title | Sunrise Alarm Clock: Wecker (27) | Sunrise Alarm Clock: Wecker (27) |
| subtitle | Sanftes Licht, Tiefschläfer (27) | Sanftes Licht, Tiefschläfer (27) |
| keywords | aufwachen,aufstehen,schlummern,mathe,mission,laut,morgen,langschläfer,schlafzyklus,sonnenaufgang (96) | aufwachen,aufstehen,schlummern,mathe,mission,laut,morgen,langschlafer,schlafzyklus,sonnenaufgang (96) — **recomendação: não aplicar** |

**Por quê:**
- Nenhuma aposta nova. Os 10 tokens protegem posições e sobram 4 chars, sem token honesto de até 3 letras (`uhr` PARTIAL/LOTTERY, `hd` PARTIAL, `app` proibido).
- `langschlafer` sem trema: `langschläfer` está **#4** → segurar ≤ #4. `langschlafer` (#7) já rankeia pelo token com trema, então aplicar não ganha posição. Pular o PATCH não perde nada e deixa o DE sem mudança de texto, como controle.
- Protegidas: `langschläfer` **#4**, `sunrise alarm clock` **#5** (pop 27), `lichtwecker sonnenaufgang` **#5**, `wecker für langschläfer` **#5**, `licht aufwachen` **#6**, `morgenlicht` **#7**, `sonnenaufgang-wecker` **#7**, `aufwachlicht` **#9**, `sanfter alarm` **#9**, `sanft aufwachen` **#10**, cluster `tiefschläfer` #11 (4 composições).
- Aposta que ficou de fora: `wecker mit aufgaben` (pop 33, diff 23) está **#51** → alvo #25-35 com `aufgaben`. Isso exige tirar `mission` (8 chars), que protege `aufwachmissionen` #23. A decisão fica com o João (ver Decisão).

---

## 📐 Diff antes/depois por locale

### fr-FR

| Campo | Antes | Depois | Chars |
|---|---|---|---|
| name | `Sunrise Alarm Clock : Réveil` | igual | 28 → 28 |
| subtitle | `Lumière douce, sommeil lourd` | igual | 28 → 28 |
| keywords | matin,se lever,tôt,alarme,mission,maths,fort,sonnerie,cycle,aube,gros dormeur,<span style="color:#dc3545">suivi</span>,réveiller | <span style="color:#28a745">defis</span>,<span style="color:#28a745">leger</span>,se lever,tot,reveiller,alarme,aube,matin,gros dormeur,fort,maths,cycle,sonnerie,mission | 93 → 99 |

**Name/subtitle, token a token (nada muda):**

| Token | Campo | Fit solo | Melhor posição que segura |
|---|---|---|---|
| `réveil` | name | FIT (pop 51, OUT solo) | `réveil lumière douce` **#2**, 35 composições rankeadas |
| `sunrise` | name | MISMATCH solo (SERP de telecom suíça), mantido só por composição | `réveil sunrise` **#4**, `sunrise alarm clock` **#7** |
| `alarm` / `clock` | name | `clock` MISMATCH solo (widgets de relógio), mantido só por composição | `sunrise alarm clock` **#7** (pop 27) |
| `lumière` + `douce` | subtitle | `lumière douce` MISMATCH (luz noturna/selfie), mantido só por composição | `réveil lumière douce` **#2**, `alarme douce` **#7** |
| `sommeil` + `lourd` | subtitle | FIT | cluster `sommeil lourd` **#4** |

**Keywords, decisão:**

🔴 SAIU

| Termo | Pop | Diff | Rank | Por quê |
|---|---|---|---|---|
| `suivi` | 26 (`suivi de sommeil`) | 53 | OUT | Nenhuma composição rankeada. LOTTERY: o top 3 tem 4k-38k ratings |

🟢 ENTROU

| Termo | Pop | Diff | Rank | Por quê |
|---|---|---|---|---|
| `defis` | 5 · astro-only | 5 | OUT | DOMINATE: `réveil avec défis` → #1-5 (9 apps), `réveil à défis` → #1-5 (6 apps), `réveil défis` → #3-10. Fit F1 (missões) |
| `leger` | 5 · astro-only | 5 | OUT | DOMINATE: `réveil léger` → #1-5 (5 apps, F4 rampa), `réveil sommeil léger` → #1-5 (5 apps, F5 janela inteligente) |

🔄 MANTÉM (todos no mapa de proteção)

| Termo | Pop | Diff | Rank | Por quê |
|---|---|---|---|---|
| `se lever` | 5 | 30 | **#19** | `se lever tôt` **#7**, `se lever le matin` #12, `se lever` #19 |
| `tot` | 5 | 7 | **#5** | `se réveiller tôt` **#5**, `se lever tôt` **#7**, `lever tôt` #13 |
| `reveiller` | 5 | 7 | **#5** | `se réveiller tôt` **#5**, `se réveiller le matin` #13 |
| `alarme` | 5 | 5 | **#4** | `alarme sommeil lourd` **#4**, `alarme douce` **#7**. Solo tem pop 60 e está OUT |
| `aube` | 5 | 7 | **#9** | `réveil aube` **#9**. Solo MISMATCH, mantido só por composição |
| `matin` | 5 | 13 | #12 | `se lever le matin` #12, `se réveiller le matin` #13. Solo MISMATCH (jornais) |
| `gros dormeur` | 5 | 13 | #32 | `réveil gros dormeurs` #32 → alvo #22-28 |
| `fort` | 5 | 11 | #36 | `réveil alarme forte` #36 → alvo #25-32 |
| `maths` | 5 | 19 | #39 | `réveil maths` #39 → alvo #27-35 |
| `cycle` | 5 | 50 | #43 | `réveil cycle de sommeil` #43. Duplicado com o en-GB (Decisão) |
| `sonnerie` | 5 | 54 | #47 | `sonnerie de réveil` #47. Solo MISMATCH (apps de toque), mantido só por composição |
| `mission` | 5 | 11 | #58 | `réveil mission` #58 → alvo #34-46. Duplicado com o en-GB (Decisão) |

### de-DE

| Campo | Antes | Depois | Chars |
|---|---|---|---|
| name | `Sunrise Alarm Clock: Wecker` | igual | 27 → 27 |
| subtitle | `Sanftes Licht, Tiefschläfer` | igual | 27 → 27 |
| keywords | …,langschläfer,… | …,langschlafer,… (opcional, recomendado não aplicar) | 96 → 96 |

**Name/subtitle, token a token (nada muda):**

| Token | Campo | Fit solo | Melhor posição que segura |
|---|---|---|---|
| `wecker` | name | FIT (pop 66, OUT solo, UNWINNABLE) | 53 composições rankeadas, 18 ≤ #30 |
| `sunrise` / `clock` | name | MISMATCH solo, mantidos só por composição | `sunrise alarm clock` **#5** (pop 27) |
| `licht` | subtitle | FIT | `lichtwecker sonnenaufgang` **#5**, `licht aufwachen` **#6** |
| `sanftes` | subtitle | FIT | `sanfter alarm` **#9**, `sanft aufwachen` **#10** |
| `tiefschläfer` | subtitle | FIT | `tiefschläfer` #11 (4 composições) |

**Keywords, decisão:**

🔴 SAIU: nenhum. 🟢 ENTROU: nenhum.

🔄 MANTÉM

| Termo | Pop | Diff | Rank | Por quê |
|---|---|---|---|---|
| `langschläfer` | 5 | 5 | **#4** | `wecker für langschläfer` **#5**, `langschlafer` **#7** |
| `sonnenaufgang` | 5 | 13 | **#5** | `lichtwecker sonnenaufgang` **#5**, `sonnenaufgang-wecker` **#7**. Solo MISMATCH (horário do sol), mantido só por composição |
| `aufwachen` | 5 | 11 | **#6** | `licht aufwachen` **#6**, `aufwachlicht` **#9**, `sanft aufwachen` **#10** |
| `morgen` | 5 | 13 | **#7** | `morgenlicht` **#7**, `morgens aufwachen` #28 |
| `schlafzyklus` | 5 | 38 | #18 | `schlafzyklus wecker` #18, `wecker schlafzyklus` #21 |
| `laut` | 5 | 11 | #20 | `lauter wecker für tiefschläfer` #20 |
| `mission` | 5 | 5 | #23 | `aufwachmissionen` #23, `wecker mission` #39. Duplicado com o en-GB (Decisão) |
| `mathe` | 5 | 23 | #27 | `mathe alarm` #27, `mathe wecker` (pop 32) #49 |
| `schlummern` | 5 | 17 | #27 | `schlummern` #27 (PARTIAL) |
| `aufstehen` | 5 | 17 | #29 | `morgens aufstehen` #29 |

---

## 🛡 Mapa de proteção

Cada token de campo leva a sua melhor posição e as composições que protege. O cruzamento por script deu **0 composições órfãs** nos dois locales: fr com 80 composições rankeadas, de com 105.

### fr-FR

| Token (campo) | Melhor | Composições que protege |
|---|---|---|
| `reveil` (name) | **#2** | réveil lumière douce #2, réveil sommeil lourd #4, réveil pour sommeil lourd #4, réveil sunrise #4, réveil aube #9, réveil lumière #12 (35 no total) |
| `lumiere` (subtitle) | **#2** | réveil lumière douce #2, lumière réveil #3, réveil lumière #12, reveil lumiere #15 |
| `douce` (subtitle) | **#2** | réveil lumière douce #2, alarme douce #7 |
| `sommeil` + `lourd` (subtitle) | **#4** | alarme/réveil/reveil sommeil lourd #4, réveil pour sommeil lourd #4, sommeil lourd #4 |
| `alarme` (kw) | **#4** | alarme sommeil lourd #4, alarme douce #7, réveil alarme forte #36, réveil alarme maths #41, alarme gros dormeur #43 |
| `sunrise` (name) | **#4** | réveil sunrise #4, sunrise réveil #4, sunrise lamp #4, sunrise alarm clock #7, sunrise simulator #14, sunrise alarm #26 |
| `se` + `lever` (kw) | **#5** | se réveiller tôt #5, se lever tôt #7, se lever le matin #12, lever tôt #13, se réveiller #18, se lever #19 |
| `reveiller` (kw) | **#5** | se réveiller tôt #5, se réveiller le matin #13, se réveiller #18, réveiller #67 |
| `tot` (kw) | **#5** | se réveiller tôt #5, se lever tôt #7, lever tôt #13, réveil tôt #15 |
| `alarm` + `clock` (name) | **#7** | sunrise alarm clock #7, sunrise alarm #26, puzzle alarm #48 |
| `aube` (kw) | **#9** | réveil aube #9 |
| `matin` (kw) | #12 | se lever le matin #12, se réveiller le matin #13 |
| `gros` + `dormeur` (kw) | #32 | réveil gros dormeurs #32, réveil gros dormeur #37, gros dormeurs #40, gros dormeur #42, alarme gros dormeur #43 |
| `fort` (kw) | #36 | réveil alarme forte #36, réveil fort #51 |
| `maths` (kw) | #39 | réveil maths #39, réveil alarme maths #41, alarme maths #52 |
| `cycle` (kw) | #43 | réveil cycle de sommeil #43, réveil cycle sommeil #50, réveil cycle #54 |
| `sonnerie` (kw) | #47 | sonnerie de réveil #47, sonnerie réveil #48 |
| `mission` (kw) | #58 | réveil mission #58, réveil missions #64, alarme mission(s) #75 |
| `suivi` (kw) | — | nenhuma, por isso sai |
| en-GB (índice secundário) | #4-#16 | sunrise lamp #4 (`lamp`), wake up light #16 (`wake`/`up`/`light`), puzzle alarm #48, réveil math #60 |

### de-DE

| Token (campo) | Melhor | Composições que protege |
|---|---|---|
| `langschlafer` (kw) | **#4** | langschläfer #4, wecker für langschläfer #5, langschlafer #7, wecker langschläfer #7 |
| `wecker` (name) | **#5** | lichtwecker sonnenaufgang #5, wecker für langschläfer #5, sonnenaufgang-wecker #7, wecker mit sonnenaufgang #7 (53 no total) |
| `licht` (subtitle) | **#5** | lichtwecker sonnenaufgang #5, licht aufwachen #6, morgenlicht #7, aufwachlicht #9, sanftes licht #12 |
| `sonnenaufgang` (kw) | **#5** | lichtwecker sonnenaufgang #5, sonnenaufgang-wecker #7, wecker mit sonnenaufgang #7, sonnenaufgang licht #18, wecker sonnenaufgang #20 |
| `sunrise` + `alarm` + `clock` (name) | **#5** | sunrise alarm clock #5, sanfter alarm #9, sunrise simulator #13, sunrise alarm #14 |
| `aufwachen` (kw) | **#6** | licht aufwachen #6, aufwachlicht #9, sanft aufwachen #10, aufwachmissionen #23, morgens aufwachen #28 |
| `morgen` (kw) | **#7** | morgenlicht #7, morgens aufwachen #28, morgens aufstehen #29 |
| `sanftes` (subtitle) | **#9** | sanfter alarm #9, sanft aufwachen #10, sanft wecken #11, sanftes licht #12 |
| `tiefschläfer` (subtitle) | #11 | tiefschläfer #11, tiefschläfer wecker #11, wecker tiefschläfer #11, lauter wecker für tiefschläfer #20 |
| `schlafzyklus` (kw) | #18 | schlafzyklus wecker #18, wecker schlafzyklus #21 |
| `laut` (kw) | #20 | lauter wecker für tiefschläfer #20, laute alarme für tiefschläfer #26 |
| `mission` (kw) | #23 | aufwachmissionen #23, wecker mission #39, mission wecker #40 |
| `mathe` (kw) | #27 | mathe alarm #27, wecker mathe #42, mathe wecker #49 |
| `schlummern` (kw) | #27 | schlummern #27 |
| `aufstehen` (kw) | #29 | morgens aufstehen #29, aufstehen #57 |
| en-GB (índice secundário) | #16-#50 | wake #16, wake up light #24, puzzle alarm #43, math alarm clock #50 |

---

## CPP

Os dois candidatos ficam registrados **abaixo do piso de medição**: a busca FR tem ~5,2 impressões/dia e a DE ~5,6. Não abrir agora.

| Candidato | Cluster | Gap de intenção vs página padrão | 3 prints necessários | Efeito esperado |
|---|---|---|---|---|
| CPP-FR "Réveil lumière" | réveil lumière douce #2, lumière réveil #3, réveil aube #9, réveil léger (alvo #1-5). Tokens ligados: `aube`, `leger` | quem busca luz quer ver o simulador de aurora; a página padrão divide o topo com missões e sono pesado | rampa de luz na tela · janela de despertar no sono leve · tela de alarme ao amanhecer | CVR do cluster luz FR. Só mensurável com mais de ~30 impressões/dia no cluster |
| CPP-DE "Lichtwecker" | lichtwecker sonnenaufgang #5, licht aufwachen #6, morgenlicht #7, aufwachlicht #9. Token ligado: `sonnenaufgang` | mesma lacuna: busca de "Lichtwecker" pede o wake-up light | idem, com texto em alemão | CVR do cluster licht DE. Mesmo piso |

---

## Decisão pro João

1. **Duplicados com o en-GB (índice secundário de FR e DE).** `mission` e `cycle` no fr-FR e `mission` no de-DE também estão no en-GB. Se o cruzamento entre locales vale pra esses tokens (vale pra `puzzle alarm` #43 em DE), são 14 chars desperdiçados no fr e 8 no de. **Teste isolado possível depois do D28:** no de-DE, trocar `mission` por `aufgaben`. O alvo é `wecker mit aufgaben` (pop 33) #51 → #25-35, e o risco é `aufwachmissionen` #23 cair. Não entra agora porque o mapa atribui a posição ao token de-DE (MUST-STAY).
2. **en-GB fora do escopo.** Mexer no en-GB alimentaria o índice secundário de FR e DE (e UK) ao mesmo tempo. O candidato natural lá é `anti`, que completa `réveil anti snooze`, `anti-snooze` e `ohne/kein snooze` com o `snooze` que já está no en-GB. Fica pra uma iteração en-GB própria.

---

## Entrega

- Os campos podem viajar na **1.4.0** (`PREPARE_FOR_SUBMISSION`) antes de o João submeter. Não há PATCH nesta etapa.
- A 1.4.0 já carrega **prints novos em 39 locales**. O efeito em downloads será conjunto (texto + prints). **O sinal atribuível ao texto é o rank por termo**, e o DE sem mudança de texto serve de controle pros prints.
- D0 = dia em que a 1.4.0 ficar `READY_FOR_SALE`, não o dia do PATCH.

---

## 📄 Resultado final

```
fr-FR
NAME:      Sunrise Alarm Clock : Réveil                                                   (28/30)  igual
SUBTITLE:  Lumière douce, sommeil lourd                                                   (28/30)  igual
KEYWORDS:  defis,leger,se lever,tot,reveiller,alarme,aube,matin,gros dormeur,fort,maths,
           cycle,sonnerie,mission                                                         (99/100) era 93

de-DE
NAME:      Sunrise Alarm Clock: Wecker                                                    (27/30)  igual
SUBTITLE:  Sanftes Licht, Tiefschläfer                                                    (27/30)  igual
KEYWORDS:  aufwachen,aufstehen,schlummern,mathe,mission,laut,morgen,langschläfer,
           schlafzyklus,sonnenaufgang                                                     (96/100) igual — normalização langschlafer opcional, recomendado NÃO aplicar
```

---

## 🎯 Hipótese formal

> **If** o keywords do fr-FR trocar `suivi` por `defis` + `leger` (93 → 99 chars), com name/subtitle intocados e o de-DE sem mudança,
> **then** até D28: pelo menos 3 das 5 composições-alvo (`réveil avec défis`, `réveil à défis`, `réveil défis`, `réveil léger`, `réveil sommeil léger`) no top 10; impressões de busca FR de 5,2 para ≥ 5,7/dia (+10%); nenhuma posição protegida do top 10 FR sai do top 10; instalações FR ≥ 1,17/dia,
> **because** (a) as 5 composições são FIT (F1 missões, F4 rampa, F5 janela inteligente) e as SERPs têm 5-9 apps com top 3 de 0-11 ratings, onde um app com 0 ratings compete; (b) `suivi` não protege nenhuma posição e o único alvo dele (`suivi de sommeil`, pop 26) é LOTTERY contra apps com 4k-38k ratings; (c) todas as 80 composições FR rankeadas mantêm os tokens; (d) playbook §7: token novo no campo 1× move rank em dias, antes de mover downloads. Como o volume é astro-only, o ganho em impressões é incerto.

---

## ⚠️ Riscos

1. **Pop não confiável.** As 5 composições-alvo têm pop 5 (piso do Astro) e não há search terms nem Apple Ads pra confirmar volume. Mitigação: o critério primário é rank. O veredito de impressões fica pro D28, e sem impressão nova as duas apostas viram `anti`/`soleil` na próxima iteração.
2. **Efeito conjunto com os prints da 1.4.0.** Downloads FR não isolam o texto. Mitigação: o DE, sem mudança de texto, é o controle. O `pull_analytics.py final` compara o RR de FR contra DE e contra a mediana dos apps quietos.
3. **Tendência FR já em queda.** O semanal FR foi 5 → **16** → 8 → 5 (pico em 07-13/09); o DE subiu 1 → 4 → 8 → 9. Uma janela de 30 dias com o pico dentro pode mostrar queda que não vem do texto. Mitigação: ler o FR sempre contra o DE e contra os outros países, nunca sozinho.
4. **`tot`/`reveiller` sem acento.** `se réveiller tôt` #5, `se lever tôt` #7 e `réveil tôt` #15 dependem desses tokens. O mapa já os registra sem acento e o `langschlafer` #7 prova a normalização. Mitigação: se qualquer um cair mais de 5 posições no D7, o acento volta em 1 PATCH.
5. **Busca FR é minoria das instalações FR.** Foram 198 impressões de busca em 38 dias contra 87 taps de browse e 45 page views de referrer. O texto só mexe na fatia de busca. Mitigação: targets de download modestos, e o sucesso é medido primeiro em rank e impressões.
6. **de-DE abaixo do piso (29/30).** Composição de texto aqui mediria nada. Mitigação: não aplicar a normalização, e o DE vira controle.
7. **Mesma versão que a iter-01.** Texto de en-US/pt-BR/es-ES/es-MX e de fr-FR entram no mesmo D0. Mitigação: os países-alvo não se sobrepõem (FR aqui; US/BR/ES/MX lá). BE e CH leem fr-FR como secundário e ficam fora do alvo.

---

## 📈 Projeção

Baseline FR: 5,2 impressões de busca/dia (198 entre 21/08 e 27/09) e 1,17 instalação/dia (35 em 30 dias).

| Cenário | Prob. | Composições-alvo no top 10 (D28) | Impressões busca FR/dia | Installs FR/dia |
|---|---|---|---|---|
| pessimista | 30% | 0-2 de 5 | 5,2 (0%) | 0,9 (queda do pico de setembro continua) |
| realista | 50% | 3-4 de 5 | 6,5 (+25%) | 1,2 (+3%, dentro do ruído) |
| otimista | 20% | 5 de 5, ≥ 3 no top 5 | 8,0 (+55%) | 1,5 (+28%) |

**Probabilidades:** chance de bater o conservador ≈ **50%**; de bater o bold ≈ **20%**.

**D0-D28 (realista):**
```
rank réveil avec défis   OUT ▁  D3 #12 ▃  D7 #6 ▅  D14 #4 ▆  D21 #3 ▇  D28 #3 ▇
impressões busca FR/dia  5,2 ▃  D7 5,4 ▃  D14 5,9 ▄  D21 6,2 ▅  D28 6,5 ▆
installs FR/dia          1,17 ▅ D7 1,1 ▅  D14 1,1 ▅  D21 1,2 ▅  D28 1,2 ▅   (ruído: n ≈ 8/semana)
```

| Checkpoint | Sucesso | Falha → ação |
|---|---|---|
| D7 | `defis` e `leger` indexados, com ≥ 2 alvos rankeados e ≥ 1 no top 10; protegidas top 10 intactas (±3) | protegida com acento caiu mais de 5 → volta `tôt`/`réveiller`; token novo sem rank → esperar D14 |
| D14 | ≥ 3 alvos no top 10; impressões FR ≥ 5,5/dia | token novo sem rank em 14 dias → trocar por `anti` (ou `soleil` se o sem-rank for `leger`) |
| D21 | `réveil avec défis`/`réveil à défis` ≤ #5; FR RR ≥ DE RR | FR abaixo do DE por mais de 30% por 14 dias → revisar se é texto ou prints antes de mexer |
| D28 | conservador (3/5 top 10, impressões ≥ 5,7, installs ≥ 1,17) ou bold | abaixo do conservador → a alavanca FR passa a ser ratings + conversão, não texto |

---

## 🎲 Confidence breakdown

| Premissa crítica | Confiança | Impacto se falhar |
|---|---|---|
| A Apple casa `defis`/`leger` sem acento com as buscas "défis"/"léger" | 90% | 0 de 5 alvos. Evidência a favor: `langschlafer` #7 pelo token com trema |
| SERPs de 5-9 apps com top 3 de 0-11 ratings aceitam um app com 0 ratings no top 5 | 65% | alvos param em #6-10 (continua valendo pro conservador) |
| As composições pop 5 têm volume real | 40% | rank sobe e impressões não; o texto certo, sem demanda |
| Tirar `suivi` não custa posição | 95% | nenhuma composição rankeada depende dele |
| Posições protegidas seguram com os tokens reordenados e sem acento | 90% | réveil tôt / se lever tôt caem; rollback em 1 PATCH |
| Download FR atribuível ao texto no D28 | 20% | efeito conjunto com prints e n ≈ 35/30 dias. Por isso o veredito de texto é rank |

---

## 🌎 Resumo cross-locale

| Locale | Name | Subtitle | Keywords | Muda? |
|---|---|---|---|---|
| fr-FR | `Sunrise Alarm Clock : Réveil` (28) | `Lumière douce, sommeil lourd` (28) | `defis,leger,…,mission` (99) | sim: −`suivi`, +`defis`, +`leger`, `tôt`/`réveiller` sem acento |
| de-DE | `Sunrise Alarm Clock: Wecker` (27) | `Sanftes Licht, Tiefschläfer` (27) | igual (96) | não (normalização opcional, recomendado não aplicar) |

| Locale | Installs 1*/30d | /dia | Installs 1*/90d | Impressões busca 21/08-27/09 | Ratings |
|---|---|---|---|---|---|
| fr-FR (FR) | 35 | 1,17 | 42 | 198 | 0 |
| de-DE (DE, sem CH/AT) | 22 | 0,73 | 25 (29 com CH/AT) | 212 | 0 |

| Padrão | fr-FR | de-DE |
|---|---|---|
| Âncora de luz (subtitle) | réveil lumière douce **#2** | lichtwecker sonnenaufgang **#5**, licht aufwachen **#6** |
| Sono pesado / quem dorme demais | sommeil lourd **#4** | langschläfer **#4**, tiefschläfer #11 |
| Head em inglês | sunrise alarm clock **#7** (pop 27) | sunrise alarm clock **#5** (pop 27) |
| Missões | réveil mission #58 → aposta `defis` (#1-5) | aufwachmissionen #23; `aufgaben` fora (Decisão) |
| Índice secundário en-GB | sunrise lamp #4, wake up light #16 | wake #16, wake up light #24 |

As duas lojas já seguram o top 10 no cluster de luz e no de sono pesado, só com o texto localizado. O que falta nas duas é o cluster de missões/desafios, e o FR é onde dá pra comprar isso sem tirar ninguém do lugar.

**Próximos passos:** (1) João decide se os campos fr-FR entram na 1.4.0 antes de submeter; o de-DE não recebe PATCH. (2) D0 = `READY_FOR_SALE` da 1.4.0, com `pull_analytics.py d0 --write-meta`. (3) Checkpoints D7/14/21/28 pelo `aso-checkpoint`, com o rank dos 5 alvos FR mais as protegidas.
