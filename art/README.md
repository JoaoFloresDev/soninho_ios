# Art sources — Sunrise Alarm Clock

Sloth mascot set generated with Gemini (`nano-banana-pro-preview`), black + orange palette.

## icon/
- `icon_shipped_orange.png` — SHIPPED app icon: sloth hugging an alarm clock on a flat
  #F4511E ground, reframed at 1.24x so the mascot reads bigger and the top gap drops from
  17.8% to 8.3%. Derived from `icon_orange.png` by scale-and-crop rather than a new
  generation, so the approved artwork is preserved exactly — the ground is perfectly flat,
  which is what makes the crop invisible. Reframe: scale 1.24x, keep the subject centred,
  crop a 1024 window with the subject's top edge at 85px.
- `icon_alt_black.png` — the same reframe on the near-black ground, kept as the alternate.
- `icon_orange.png` / `icon_black.png` — the raw generations, original framing.
- `icon_a.png` — sloth face variant, rejected (less brand pop than the clock pose).

The icon set (`Assets.xcassets/AppIcon.appiconset`, 12 sizes) and the launch
screen tile (`LaunchIcon.imageset`, rounded 22.37% corners) are both derived
from the shipped source. App Store icons are written as opaque RGB — no alpha.

## mascot/
In-app illustrations, mapped to the imagesets:

| source | imageset | used in |
|---|---|---|
| `sloth_wake.png` | onbHero1 | Onboarding 1 |
| `sloth_sleep.png` | onbHero2 | Onboarding 2 |
| `hero3_chart.png` | onbHero3 | Onboarding 3 |
| `sloth_night.png` | heroNight | Sleep tab, idle header |
| `sloth_bed.png` | heroBed | Stats empty state + Sleep tab while tracking |
| `sloth_alarm_v2.png` | heroAlarm | Alarm tab, Next Alarm card |

Gemini returns JPEG on a white/solid ground. Each art is keyed to transparency
with a luminance-based alpha so the baked halo blends into the dark UI instead
of leaving a dark ring: opaque inside r<=0.48, outer alpha = max(r,g,b)*1.45,
crossfade 0.48-0.62, zero at r>=1.02, radius normalised to the inscribed circle.
