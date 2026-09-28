# Composition rationale — iter-02 (fr-FR / de-DE) — 2026-09-28

Stage 5 (aso-field-composer). Inputs: `term_fit_{fr-FR,de-DE}.csv`, `serp_winnability_{fr,de}.csv`, `protection_map_{fr,de}.csv`, `app_feature_inventory.md`, live `current/metadata/<locale>/`.

- **fields_changed**: `keywords` only (fr-FR: tokens changed; de-DE: umlaut normalization only). `name.txt`/`subtitle.txt` in `proposed/` are byte-identical copies of live, written because the coordinator asked for the full set. Rule 7 did not fire: every volume is `astro-only` ("pop não confiável"), so under rule 10 nothing moves into name or subtitle.
- **Rating-first**: 0 ratings in fr/de. This iteration keeps the change conservative: at most 3 new bets per locale, and nothing leaves that has any ranking.
- **Validator**: `./scripts/validate_proposed.sh <iter>` returned 0 blockers and 7 warnings, all justified below.

---

## fr-FR

| Field | Live | Proposed | Chars |
|---|---|---|---|
| name | Sunrise Alarm Clock : Réveil | (unchanged) | 28 |
| subtitle | Lumière douce, sommeil lourd | (unchanged) | 28 |
| keywords | `matin,se lever,tôt,alarme,mission,maths,fort,sonnerie,cycle,aube,gros dormeur,suivi,réveiller` | `defis,leger,se lever,tot,reveiller,alarme,aube,matin,gros dormeur,fort,maths,cycle,sonnerie,mission` | 93 → 99 |

### SAIU
| Token | Reason |
|---|---|
| `suivi` | It has no ranked composition (protection map: "Field tokens with NO ranked composition: suivi"). `suivi sommeil` is OUT (pop 7, diff 56). In FR, `suivi cycle` reads as a period tracker (N12/N17; the SERP shows 10 of 10 period trackers), so the token pulls a mismatched intent. Rule 2 applies. |

### ENTROU (2 bets; the 13 freed chars fit two, a third does not fit)
| Token | Score | Thesis (compositions it completes) | Target D28 | volume_source | cpp |
|---|---|---|---|---|---|
| `defis` | DOMINATE | 3 FIT compositions on small SERPs: `réveil avec défis` (#1-5, SERP of 9 apps), `réveil à défis` (#1-5, 6 apps), `réveil défis` (#3-10). `reveil` is already in the name, so the token alone completes all three. Honest: F1, the wake-up missions (math is free). | OUT → #1-10 | astro-only (pop não confiável) | default page |
| `leger` | DOMINATE | 2 FIT compositions: `réveil léger` (#1-5, 5 apps; gradual wake, F4/F3) and `réveil sommeil léger` (#1-5, 5 apps; the smart window rings in light sleep, F5, and `sommeil` is already in the subtitle). It also feeds the PARTIAL `sommeil léger` (composition feeder only, never a solo bet) and, later, `réveil phase sommeil léger` if `phase` enters. | OUT → #1-5 | astro-only (pop não confiável) | CPP-FR "Réveil lumière" |

Next in line, not included because it does not fit the budget (documented for iter-03):
- `anti` (4): 4 compositions, `réveil anti snooze` #3-10, `anti-snooze` #10-20, `réveil anti-sommeil` CLIMB #8-20, `anti snooze` CLIMB. Three of the four depend on `snooze`, which is in en-GB (the secondary index). It lost to `defis` and `leger` because it has fewer #1-5 targets.
- `soleil` (6): `réveil lever de/du soleil` #1-5, `réveil soleil` CLIMB. It also exposes the listing to `lever de soleil`, a MISMATCH (sunrise-time apps, N8).
- `difficile` (9): 1 composition only, too expensive per char. `mathematique` (12): 2 compositions, too expensive.

### MANTÉM (all on the protection map, so rule 1 keeps them)
| Token | Why it stays (best ranked composition) |
|---|---|
| `se lever` | Phrase kept intact. It covers `se` (6 compositions ≤30: `se réveiller tôt` #5, `se lever tôt` #7, `se lever le matin` #12…) and `lever` (`lever tôt` #13, `se lever` #19). As a solo comma token, `se` would also trip the validator's stopword blocker. |
| `tot` | `se réveiller tôt` #5, `se lever tôt` #7, `lever tôt` #13, `réveil tôt` #15 |
| `reveiller` | `se réveiller tôt` #5, `se réveiller le matin` #13, `se réveiller` #18 |
| `alarme` | `alarme sommeil lourd` #4, `alarme douce` #7, `réveil alarme forte` #36 |
| `aube` | `réveil aube` #9 |
| `matin` | `se lever le matin` #12, `se réveiller le matin` #13 |
| `gros dormeur` | Phrase kept. `réveil gros dormeurs` #32, `réveil gros dormeur` #37, `gros dormeur` #42 |
| `fort` | `réveil alarme forte` #36, `réveil fort` #51 |
| `maths` | `réveil maths` #39, `réveil alarme maths` #41 |
| `cycle` | `réveil cycle de sommeil` #43, `réveil cycle sommeil` #50 |
| `sonnerie` | `sonnerie de réveil` #47, `sonnerie réveil` #48 |
| `mission` | `réveil mission` #58, `réveil missions` #64, `alarme mission` #75 (SOFT, but it ranks, so it stays) |

Accent normalization (rule 5, same char count, same index): `tôt` → `tot`, `réveiller` → `reveiller`. The protection map already records these tokens unaccented, and the SERP shows accented and unaccented queries ranking off the same token.

### Front-loading order
| # | Token | Class |
|---|---|---|
| 1 | defis | DOMINATE new bet (3 compositions) |
| 2 | leger | DOMINATE new bet (2 compositions + feeder) |
| 3-14 | se lever, tot, reveiller, alarme, aube, matin, gros dormeur, fort, maths, cycle, sonnerie, mission | protect (ordered by best current rank; position does not affect their rank) |

### Per-locale dup check (rule 4)
Name tokens: sunrise, alarm, clock, réveil. Subtitle tokens: lumière, douce, sommeil, lourd. None is repeated in keywords. `reveiller` ≠ `réveil` (different word, with its own ranked compositions). `alarme` ≠ `alarm` (different spelling, not an accent variant). `leger` is not a dup of `lourd` or `douce`.

### Protection map status: ALL COVERED
A script cross-check against `protection_map_fr.csv` found 69 keyword-field token references across 80 ranked compositions, with **0 missing** in the proposed field. The name/subtitle tokens (reveil, sunrise, alarm, clock, lumiere, douce, sommeil, lourd) are unchanged.

### Semantic coherence (rule 8)
"Sunrise Alarm Clock: Réveil — lumière douce, sommeil lourd" + keywords reads as one sentence: a sunrise alarm that wakes heavy sleepers early in the morning (se lever tôt, gros dormeur, fort) with missions and challenges (mission, maths, défis) and a gentle light wake (léger, aube, cycle). Every token completes "an app that ___".

### CPP (rule 11)
Analyst candidate: CPP-FR "Réveil lumière". Linked keyword-field tokens: `aube`, `leger`. All other tokens stay on the default page. Each token belongs to one page only.

---

## de-DE

| Field | Live | Proposed | Chars |
|---|---|---|---|
| name | Sunrise Alarm Clock: Wecker | (unchanged) | 27 |
| subtitle | Sanftes Licht, Tiefschläfer | (unchanged) | 27 |
| keywords | `aufwachen,aufstehen,schlummern,mathe,mission,laut,morgen,langschläfer,schlafzyklus,sonnenaufgang` | `aufwachen,aufstehen,schlummern,mathe,mission,laut,morgen,langschlafer,schlafzyklus,sonnenaufgang` | 96 → 96 |

### SAIU
None. Every field token is MUST-STAY (the protection map lists "Field tokens with NO ranked composition: (none)").

### ENTROU
None. There are 4 free chars, so a new token can be at most 3 letters. The research files hold no honest FIT token of 3 letters or fewer. `uhr` is PARTIAL (clock display not delivered) and LOTTERY. `hd` is PARTIAL and navigational. `for` is a stopword and a validator blocker. `app` is forbidden. The best bet in the store, `aufgaben` (`wecker mit aufgaben`, pop 33, diff 23, #51 → #25-35), needs 9 chars, and those can only come from removing a protected token. **de-DE keywords are left unchanged by design.**

### MANTÉM
| Token | Why it stays (best ranked composition) |
|---|---|
| `langschlafer` | `langschläfer` #4, `wecker für langschläfer` #5, `langschlafer` #7 |
| `sonnenaufgang` | `lichtwecker sonnenaufgang` #5, `sonnenaufgang-wecker` #7, `wecker mit sonnenaufgang` #7 |
| `aufwachen` | `licht aufwachen` #6, `aufwachlicht` #9, `sanft aufwachen` #10 |
| `morgen` | `morgenlicht` #7, `morgens aufwachen` #28 |
| `schlafzyklus` | `schlafzyklus wecker` #18, `wecker schlafzyklus` #21 |
| `laut` | `lauter wecker für tiefschläfer` #20, `laute alarme für tiefschläfer` #26 |
| `mission` | `aufwachmissionen` #23, `wecker mission` #39 |
| `mathe` | `mathe alarm` #27, `wecker mathe` #42 |
| `schlummern` | `schlummern` #27 |
| `aufstehen` | `morgens aufstehen` #29, `aufstehen` #57 |

The only diff from live is `langschläfer` → `langschlafer` (rule 5, same length). Live data shows the normalization working: `langschlafer` ranks #7 off the umlaut token. **Deploying de-DE is optional. Skipping the de-DE PATCH loses nothing.**

### Front-loading order
Live order kept. There is no new bet, and position does not change the rank of protected tokens.

### Per-locale dup check (rule 4)
Name: sunrise, alarm, clock, wecker. Subtitle: sanftes, licht, tiefschläfer. None is repeated in keywords (`langschlafer` ≠ `tiefschlafer`).

### Protection map status: ALL COVERED
Cross-check against `protection_map_de.csv`: 51 keyword-field token references across 105 ranked compositions, **0 missing**.

### CPP (rule 11)
Analyst candidate: CPP-DE "Lichtwecker". Linked keyword-field token: `sonnenaufgang` (the analyst marked it as the linkable token, and all its compositions are in the light cluster). Everything else stays on the default page.

---

## en-GB (the secondary index for FR and DE; not touched in this iteration)
en-GB tokens that currently feed ranked compositions:
- **fr**: wake/up/light (`wake up light` #16), lamp (`sunrise lamp` #4; `lamp` is N1 and not delivered, see the inventory discrepancy), puzzle (#48), math (#60), heavy/sleepers (#75), loud (#100), gentle (#139), snooze (#153/#186), smart (#211).
- **de**: wake/up/light (#16-30), puzzle (#43), math (#50), loud (#55), snooze (#85), heavy/sleepers (#87), gentle (#88), sleep/cycle (#98), smart (#117).
- en-GB `snooze` is what makes `anti` worth adding in FR (`réveil anti snooze`, `anti-snooze`) and `ohne`/`kein` in DE (`ohne snooze`, `kein snooze`). An en-GB iteration could carry `anti` for UK, FR and DE at once.

## Trade-offs flagged for João (NOT applied; rule 1 wins)
1. **Cross-locale duplicates with en-GB.** fr-FR `mission` and `cycle`, and de-DE `mission`, are also in en-GB keywords, which the FR/DE stores index as their secondary locale. The protection map shows cross-locale composition working (e.g. `puzzle alarm` #43 in DE comes from en-GB `puzzle` + de `alarm`). If that holds for these tokens too, the duplicates waste chars: 8 in de-DE and 14 in fr-FR. In de-DE, removing `mission` (8) would fund `aufgaben` (the best bet in the store, pop 33, #51 → #25-35), landing at 97 chars. I kept them because the protection map attributes the rankings to the de-DE/fr-FR token (MUST-STAY), and compound matches like `aufwachmissionen` #23 may depend on the same locale. Test this as a dedicated single-variable iteration if wanted.
2. **Budget.** fr-FR is at 99/100 and de-DE at 96/100. The leftover 1 and 4 chars stay empty: there is no honest token that small (rule 5, no filler).

## Validator warnings (0 blockers)
- name/subtitle "N/30 used" (fr 28/28, de 27/27): unchanged live fields, and rule 7 did not fire.
- keywords "99/100" (fr) and "96/100" (de): see trade-off 2.
- fr `tot` "short token possibly truncated": it is the real word *tôt* normalized, and it protects 4 compositions ≤15.
