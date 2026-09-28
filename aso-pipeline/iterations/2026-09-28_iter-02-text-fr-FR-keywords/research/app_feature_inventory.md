# App feature inventory — Sunrise Alarm Clock (6758740138) — 2026-09-27

Sources (primary, in order): app source at HEAD (`soninho/soninho/`, includes 1.4.0), live 1.3.0 listing (`current/metadata/en-US/description.txt`), competitor SERPs (Astro `search_app_store`, today).
Targets in the Xcode project: `soninho`, `soninhoTests`, `soninhoUITests`. No widget extension, no watchOS target.

## Core jobs (F-ids referenced by term_fit_<locale>.csv)

| ID | Feature | Evidence in source |
|---|---|---|
| F1 | **Wake-up missions** to dismiss: `none`, `math` (FREE), `shake`, `typing`, `memory` (sequence) = Sunrise Premium; difficulty easy/medium/hard (math rounds 1-3) | `Data/Models/WakeMissionModel.swift` (`isPremium`), `Presentation/SmartAlarm/Components/*MissionView.swift` |
| F1p | Premium gating: shake/typing/memory locked behind weekly/yearly sub (3-day trial on yearly); everything else is free | `WakeUpSettingsSection.swift:62-67`, `PaywallView.swift`, `Products.storekit` |
| F2 | **Anti-snooze**: snooze settings (on/off, length), mission required to stop, anti-relapse step check after dismissal (CoreMotion pedometer counts steps to confirm you got up) | `SnoozeSettingsSection.swift`, `WakeConfirmationView.swift`, `WakeMotionService.swift:61` |
| F3 | **Loud alarm**: 10 generated tones (sunrise, birds, ocean, gentle, piano, forest, chimes, harp, rain, marimba) driven to full scale (`drive 2.6`, tanh) + system volume pushed to max via MPVolumeView; vibration toggle | `Core/Utils/AlarmSoundGenerator.swift:505-516`, `Core/Utils/SystemVolume.swift`, `AlarmModel.swift` |
| F4 | **Gradual / sunrise wake**: volume AND on-screen light fade in "sunrise style", 1-5 min | `wake_gradual_*` strings, `SunriseBackground.swift`, `AlarmRingingView.swift` |
| F5 | **Smart wake window** 15/30/45/60 min: rings early in light sleep; motion (accelerometer actigraphy) + SoundAnalysis classifier (snoring vetoes a wake) | `SmartWakeDecider.swift`, `SleepStagingEngine.swift`, `MotionSleepMonitor.swift`, `SleepSoundMonitor.swift`, `alarm_window_15..60` |
| F6 | **Sleep tracking** per night: phases deep/light/REM/awake, cycles, efficiency, quality score /100 | `SleepNightRecorder.swift`, `SleepQualityScorer.swift`, `SleepTrackerView.swift` |
| F7 | **Sleep statistics**: week/month/year trends, avg bedtime, per-night records (delete) | `StatisticsView.swift`, `stats_*` strings |
| F8 | **Bedtime reminder** + auto-start night (App Intent / Shortcuts `StartSleepNightIntent`) | `NotificationService+Bedtime.swift`, `Core/Intents/*` |
| F9 | **Sleep tips** (daily tip + catalogue: routine, environment, nutrition, relaxation) | `SleepTipsService.swift`, `SleepTipsView.swift` |
| F10 | **Alarm clock basics**: multiple alarms, repeat per weekday, volume, vibration, label; AlarmKit system alarms on iOS 26 (rings through Focus/silent) | `AlarmEditSheet.swift`, `SystemAlarmScheduler.swift`, `NSAlarmKitUsageDescription` |
| F11 | **Free base app**: alarm, math mission, smart wake, gradual wake, tracking, stats, tips are free; offline, no account | `WakeMissionModel.isPremium` is the only gate found |
| F12 | Positioning: heavy sleepers / chronic snoozers (F1+F2+F3 combined); dark UI; sloth mascot | description.txt, `settings_premium_subtitle` |

## NOT delivered (N-ids)

| ID | Not in the app | Note |
|---|---|---|
| N1 | Physical lamp / smart-bulb / wake-up-light device control | Light = phone screen only (F4) |
| N2 | Widget | No extension target |
| N3 | Apple Watch app | No watchOS target |
| N4 | Custom music / Spotify / own ringtone / big sound library | Only the 10 built-in generated tones |
| N5 | Photo, barcode, QR, step-count *missions* | Steps only as post-dismiss check (F2), not a dismiss mission |
| N6 | White noise / sleep sounds / sleep music / meditation playback | Tip text mentions white noise; app plays none |
| N7 | Nap / power-nap / sleep timer | — |
| N8 | World clock, stopwatch, timer, sunrise/sunset times, weather, alarm at actual solar sunrise | — |
| N9 | Snore recording / playback / sleep-talk recorder | Snoring detection is internal (staging veto), never surfaced |
| N10 | Apple Health sync | No HealthKit in source/entitlements; `paywall_feature_4_*` strings are stale/unused |
| N11 | Habit / challenge / morning-routine tracker | Only wake-up; tips are read-only |
| N12 | Menstrual / cycle tracking | "cycle" = sleep cycle only |
| N13 | Flashlight / night light / bedside clock display / digital clock face | — |
| N14 | Games beyond the memory-sequence mission; math/brain-training as standalone | — |

## Listing vs source discrepancies (for composer/reporter)
- Live description says smart window "up to 30 min"; source offers 15-60 min.
- Live description says "take a few steps to turn the alarm off" — steps are a post-dismiss confirmation, not the dismiss mission.
- Live keyword field contains `lamp` — no lamp feature (N1); `sunrise lamp` SERP is half smart-lamp controllers.
- Live 1.3.0 listing does not mention Premium; 1.4.0 gates shake/typing/memory.

## Addendum 2026-09-28 (iter-02, fr-FR / de-DE)

Reused from iter-01 (2026-09-27); source re-checked only for what changed or what fr/de SERPs raised.

| ID | Item | Evidence |
|---|---|---|
| F1p+ | 1.4.0: Premium owned state (Settings) + `PremiumTag` on the alarm tab. This is UI only and does not change search fit | `Presentation/Common/Components/PremiumTag.swift`, `SettingsView.swift`, `SmartAlarmView.swift` |
| F13 | No ads: no ad SDK in source or project (supports "ohne Werbung" type queries) | grep GoogleMobileAds/AdMob/GAD* = 0 hits |
| F14 | UI localized in fr and de (Localizable.xcstrings has `fr`, `de`) | `Core/Localization/Localizable.xcstrings` |
| N5+ | Missions: no NFC, QR, barcode, photo or scan missions | grep CoreNFC/VNDetectBarcodes = 0 hits |
| N15 | No talking, voice or AI alarm. No TTS, voice scenes or recorded voice | grep AVSpeechSynthesizer = 0 hits |
| N16 | No radio alarm, no music/Spotify alarm (restates N4 for fr/de "radio"/"musique"/"Musik"/"Spotify" queries) | 10 generated tones only |
| N17 | Not a menstrual cycle tracker: in FR, "suivi cycle" reads as period tracking (restates N12) | SERP fr "suivi cycle" = 10/10 period trackers |
