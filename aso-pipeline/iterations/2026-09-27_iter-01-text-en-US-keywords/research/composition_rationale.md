# Composition rationale — iter-01 (2026-09-27)

Stage 5 (aso-field-composer). Inputs: `serp_winnability_{us,br,es,mx}.csv` (score + PROTECT column = protection map), `term_fit_en-US.csv`, `current/metadata/`.
**fields_changed: keywords only, all 4 locales.** Name and subtitle stay as they are in every locale. Rule 7 did not fire because no current subtitle wastes chars on an exact dup. `name.txt`/`subtitle.txt` in `proposed/` are unchanged copies so the validator can check them.

Conservative on purpose (1 rating, rating-first): nothing protected leaves, and new bets go only into freed or slack chars.

---

## en-US (store us)

| field | before | after |
|---|---|---|
| name | Sunrise Alarm Clock: Wake Up (28) | = |
| subtitle | Gentle Light, Heavy Sleepers (28) | = |
| keywords | `mission,math,puzzle,snooze,loud,sounds,dawn,sun,lamp,morning,routine,sleep,cycle,tracker,smart` (94) | `gently,sunlight,fast,mission,math,puzzle,snooze,loud,sounds,dawn,sun,lamp,morning,sleep,cycle,smart` (99) |

**SAIU (removed)**
| token | reason |
|---|---|
| routine | Feeds no ranked composition. "morning routine" is PARTIAL and a LOTTERY term (OUT, owned by habit trackers). |
| tracker | Feeds no ranked composition. Its compositions "sleep tracker" and "sleep cycle tracker" are UNWINNABLE or OUT LOTTERY. Dropping it also removes a sleep-tracker claim from the listing (rule 8). |

**ENTROU (added, 3 bets, 16 chars + commas)**
| token | thesis (winnability CSV) |
|---|---|
| gently | "wake up gently": FIT, pop 5 / diff 17, we are **#13**, DOMINATE, target #1-3. The CSV flags this term as "needs gently". `gentle` in the subtitle does not cover the adverb. |
| sunlight | "sunlight alarm": FIT, pop 5 / diff 11, **#38** with only `alarm` in place, DOMINATE, target #5-10. |
| fast | "wake up fast": FIT (smart wake + missions), pop 5 / diff 13, **#172**, DOMINATE, target #5-10. It is the weakest of the three bets and uses the last 5 chars. |

**MANTÉM (kept)**: every token that protects a ranked composition
| token | ranked compositions it protects |
|---|---|
| sleep | sunrise sleep #21, sleep cycle alarm #116, sleep alarm #133 |
| lamp | sunrise lamp #36 (PARTIAL, feeder) |
| dawn | dawn alarm #38, dawn alarm clock #97 |
| sounds | sunrise alarm clock sounds #42. Kept under rule 1 even though "sleep sounds" is MISMATCH (see trade-offs) |
| loud | super loud alarm clock #45, alarm clock loud #68, extra loud alarm #165 |
| snooze | alarm clock no snooze #57, anti snooze alarm #139, snooze alarm #182 |
| sun | sun alarm #71 |
| math | alarm clock with math #76, alarm math #82, math alarm clock #92 |
| smart | smart wake #98, smart alarm clock #142 |
| cycle | sleep cycle alarm #116 |
| mission | wake up missions #128, wake up mission #131, mission alarm clock #149 (headline feature of 1.4.0) |
| puzzle | puzzle alarm clock #167, puzzle alarm #178 (weak, but ranked counts under rule 1) |
| morning | morning alarm #180 (weak, but ranked counts under rule 1) |

**Front-loading order**
| pos | token | why here |
|---|---|---|
| 1-3 | gently, sunlight, fast | new DOMINATE pushes, ordered by expected value (#13 → #38 → #172) |
| 4 | mission | DOMINATE compositions (wake up mission/s) and the 1.4.0 headline |
| 5-16 | math, puzzle, snooze, loud, sounds, dawn, sun, lamp, morning, sleep, cycle, smart | protect/feeders, kept in their current order. Their rank does not depend on position. |

**Protection map (us)**: all covered. Name `sunrise alarm clock wake up` covers 47/25/15/18/18 compositions (alarm/clock/sunrise/wake/up). Subtitle `gentle light heavy sleepers` covers 5/8/8/10. Every keyword token above is present. Missing tokens with a ranked composition: **none**.

---

## pt-BR (store br)

| field | before | after |
|---|---|---|
| name | Sunrise Alarm Clock Alarme (26) | = |
| subtitle | Despertador com Luz e Missões (29) | = |
| keywords | `acordar,cedo,sono,pesado,soneca,matematica,relogio,forte,alto,manha,dorminhoco,ciclo,amanhecer` (94) | `anti,acordar,cedo,sono,pesado,soneca,matematica,relogio,forte,alto,manha,dorminhoco,ciclo,amanhecer` (99) |

**SAIU**: none. All 13 tokens protect a ranked composition.

**ENTROU (1 bet, 5 of the 6 slack chars)**
| token | thesis |
|---|---|
| anti | "anti soneca": FIT, pop 5 / diff 5, DOMINATE, target #5-10. `soneca` is already present, so a 4-letter token completes the composition. It matches the missions headline (the thing that stops snoozing). Alternative considered: `sol` (despertador luz do sol, DOMINATE diff 5). Picked `anti` because it is on-message for 1.4.0. The two cannot both fit (8 > 6). |

**MANTÉM**
| token | ranked compositions |
|---|---|
| acordar | acordar com luz #2, alarme/despertador para acordar cedo #35, acordar de manha #76 |
| amanhecer | alarme amanhecer #4, despertador amanhecer #6, luz do amanhecer #9 |
| matematica | alarme com matematica #11, despertador com matematica #16, alarme matematica #63 |
| relogio | relogio despertador forte #14, relogio despertador #28, relogio despertador alto #28, relogio alarme #70 |
| forte | relogio despertador forte #14, despertador forte #146, alarme forte #163 |
| dorminhoco | despertador dorminhoco #20 |
| ciclo | despertador ciclo #24, despertador ciclo do sono #28, alarme ciclo do sono #34 |
| sono | 7 compositions from #28 (despertador ciclo do sono, despertador sono pesado…) |
| alto | relogio despertador alto #28, alarmes altos #104, despertador alto #175 |
| pesado | despertador sono pesado #30, alarme para sono pesado #32, +3 |
| cedo | alarme/despertador para acordar cedo #35, acorde cedo #43 |
| manha | despertador de manha #71, acordar de manha #76 (weak) |
| soneca | alarme soneca #129 (weak). Also the partner of the new `anti` |

**Front-loading**: `anti` (new DOMINATE push) first. The 13 protected tokens follow in their current order, since position does not change their rank.

**Protection map (br)**: all covered. Name keeps `alarme` (14 compositions), `sunrise`, `alarm`, `clock`. Subtitle keeps `despertador` (21), `luz` (5), `missoes` (3). All 13 keyword tokens stay. The en-US-labelled br rows (math/smart/heavy/sleepers at #118-#149) come from the en-US locale, which the br store also indexes, and en-US keeps all of those tokens. Missing: **none**.
The br CLIMB bets named by stage 4 ("alarme despertador", "alarme para sono pesado") need no new token: every token is already in place.

---

## es-ES (store es)

| field | before | after |
|---|---|---|
| name | Sunrise Alarm Clock: Alarma (27) | = |
| subtitle | Despertador con Luz y Misión (28) | = |
| keywords | `despertar,temprano,sueno,pesado,matematicas,reloj,fuerte,manana,dormilon,ciclo,amanecer,suave` (93) | `reto,despertar,temprano,sueno,pesado,matematicas,reloj,fuerte,manana,dormilon,ciclo,amanecer,suave` (98) |

**SAIU**: none. All 12 tokens protect a ranked composition.

**ENTROU (1 bet)**
| token | thesis |
|---|---|
| reto | "alarma con reto" and "despertador con reto": FIT, pop 5 / diff 5, DOMINATE, target #5-10. A 4-letter token feeds 2 compositions whose other tokens (alarma in the name, despertador in the subtitle) are already present. It is the Spanish synonym of the mission feature. Chosen over `retos` (diff 5-15, 1 char more), `tareas` (7 chars, exactly the 7 left but diff 11) and `sol` (1 composition). |

**MANTÉM**
| token | ranked compositions |
|---|---|
| despertar | alarma para despertar temprano #2, despertar con luz #3, despertar temprano #6, despertar suave #8 |
| temprano | alarma para despertar temprano #2, alarma temprano #3, despertador temprano #6 |
| sueno | 8 compositions from #5 (alarma para sueño pesado…) |
| pesado | 6 compositions from #5 |
| reloj | reloj despertador con luz #5, reloj despertador fuerte #17, alarma fuerte y reloj #49, reloj despertador gratis #106 |
| matematicas | alarma con matemáticas #6, despertador con matematicas #9, +4 |
| suave | despertar suave #8, despertador suave #70, alarma suave #122 |
| amanecer | alarma amanecer #17, luz de amanecer #17, despertador amanecer #52, amanecer #90 |
| fuerte | reloj despertador fuerte #17, alarma fuerte y reloj #49, despertador fuerte #62 |
| dormilon | despertador dormilon #19 |
| ciclo | alarma ciclo de sueño #20, despertador ciclo de sueño #21 |
| manana | alarma de la mañana #25, alarma mañana #25 |

**Front-loading**: `reto` first, then the protected tokens in their current order.

**Protection map (es)**: all covered. Name keeps alarma (19), sunrise, alarm, clock. Subtitle keeps despertador (22), luz (7), mision (3). All 12 keyword tokens stay. The en-GB rows (loud/math/wake/up/heavy/sleepers, #43-#102) belong to the en-GB locale, which this iteration does not touch. Missing: **none**.

---

## es-MX (store mx)

Its own dup check was run against the es-MX name/subtitle. Today they are identical to es-ES, so the result is the same.

| field | before | after |
|---|---|---|
| name | Sunrise Alarm Clock: Alarma (27) | = |
| subtitle | Despertador con Luz y Misión (28) | = |
| keywords | same 12 tokens as es-ES (93) | `reto,despertar,temprano,sueno,pesado,matematicas,reloj,fuerte,manana,dormilon,ciclo,amanecer,suave` (98) |

**SAIU**: none. **ENTROU**: `reto`: "alarma con reto" and "despertador con reto" are DOMINATE, pop 5 / diff 5, OUT today (the same thesis as es-ES, measured in the mx CSV).

**MANTÉM**
| token | ranked compositions |
|---|---|
| despertar | despertar con luz #2, despertar suave #8, despertar temprano #11, alarma para despertar temprano #12 |
| reloj | reloj despertador con luz #7, reloj despertador fuerte #24, reloj despertador gratis #89, alarma fuerte y reloj #96 |
| matematicas | alarma con matemáticas #8, despertador con matematicas #13, +2 |
| suave | despertar suave #8, despertador suave #172 |
| sueno / pesado | 8 / 6 compositions from #11 |
| temprano | despertador temprano #11, despertar temprano #11, +2 |
| amanecer | despertador amanecer #12, luz de amanecer #14, alarma amanecer #18, amanecer #93 |
| ciclo | despertador ciclo de sueño #18, alarma ciclo de sueño #23 |
| fuerte | reloj despertador fuerte #24, alarma fuerte y reloj #96, alarma fuerte #143 |
| dormilon | despertador dormilon #26 |
| manana | alarma mañana #53, alarma de la mañana #61 (weakest, still ranked) |

**Front-loading**: `reto` first, the rest unchanged.
**Protection map (mx)**: all covered. The en-US row math alarm clock #145 is covered because en-US keeps `math`. Missing: **none**.

---

## Trade-offs declared

1. **en-US `sounds` stays despite a MISMATCH neighbour.** "sleep sounds" is MISMATCH (the app plays no white noise). The same token also protects "sunrise alarm clock sounds" #42 (PARTIAL, alarm tones). Rule 1 wins: a ranked composition is an asset. Semantically "alarm sounds" is true of the app (rule 8 passes).
2. **en-US `fast` sits beside `gently` / "Gentle Light".** Both fit the product: gentle light and smart wake, then missions that get a heavy sleeper up fast. This is the lowest-EV bet (#172). Remove it first if João wants a 2-bet iteration; that leaves 94 honest chars.
3. **pt-BR `anti` over `sol`**: they cost about the same and only one fits. Chosen for coherence with the 1.4.0 missions story.
4. Name/subtitle budgets have 1-4 chars left in every locale. No rewrite, because rule 7 requires exact-dup waste and none exists.

## Validator
`./scripts/validate_proposed.sh <iter>`: **0 blockers**, 13 warnings. The warnings are unused name/subtitle chars (unchanged by design), keywords at 98-99/100 (no token fits the remaining 1-2 chars), and `sun` flagged as short (a real word that protects sun alarm #71).
