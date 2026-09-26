# Rune Ring

A Norse watch face for the **Garmin Venu 4 (45 mm)**. Twenty-four Elder Futhark runes form a
24-hour ring around the dial, the time is set in Cinzel, and every metric is drawn as a rune
instead of an icon.

Nothing is bitmap art: the runes are line segments computed at startup, so the whole face
fits in about 32 KB of the 128 KB watch-face memory budget.

```
           ᛇ  ᛈ  ᛉ  ᛊ  …          ring of 24 runes, one per hour

         ПТ  26  СЕНТ             date
     ────────◆────────            watch battery
           ᚾ 34  ᚨ 3              stress · unread messages

            10:47                 time

   ♥ 62              ᛊ 74         heart rate · Body Battery

      ᚱ 8214    ᚲ 1976            steps · calories
             ᚠ                    rune of the current ætt
```

Screenshots will follow with the first store beta. To capture one from the simulator:
**File → Save Screenshot**.

## The ring

Each rune is one hour of the day: rune *i* lights up during hour *i*. Past hours are pale,
the current hour takes the accent colour, hours still to come stay dark.

Two orientations, switchable in the settings:

- **Solar** (default) — noon ᛇ at the top, midnight ᚠ at the bottom, morning on the left,
  evening on the right. This is where the sun itself stands for an observer facing south.
- **Classic** — midnight at the top, like an ordinary 24-hour dial. This matches the
  direction a sundial's shadow points.

Both run clockwise; only the origin differs.

The rune below the time is the head of the current **ætt**, the eight-rune group the hour
falls into: ᚠ for 00–07, ᚺ for 08–15, ᛏ for 16–23. Tying the three ættir to night, day and
evening is this project's idea, not a historical tradition.

## What is on the dial

| Element | Source | Notes |
|---|---|---|
| Date | `Gregorian.info` | Localised, Russian or English |
| Phone dot | `phoneConnected` | Only visible when the phone is disconnected |
| Battery strip | `getSystemStats` | Fills outward from the diamond, turns red at 20% |
| Stress ᚾ | Complications → `SensorHistory` | The rune is coloured by level, the number stays white |
| Notifications ᚨ | `notificationCount` | Only shown when something is unread |
| Time | `getClockTime` | Cinzel, centred on its visible pixels |
| Heart rate ♥ | `Activity.getActivityInfo` | Always red |
| Body Battery ᛊ | Complications → `SensorHistory` | Rune coloured by level |
| Steps ᚱ, calories ᚲ | `ActivityMonitor` | |

Tapping a metric opens the matching native Garmin screen through `Complications.exitTo`.
Taps are ignored on the night and always-on screens, where there is nothing to tap.

Runes are chosen for meaning, not decoration: ᚾ *naudiz* (need, constraint) for stress,
ᚨ *ansuz* (mouth, message) for notifications, ᚱ *raidho* (the road) for steps, ᚲ *kaunan*
(torch, fire) for calories, ᛊ *sowilo* (sun, energy) for Body Battery.

## Night and always-on

**Night screen** takes over inside the sleep window from your Garmin Connect profile. It is
red only, so it will not wreck your night vision: a moon when Do Not Disturb is on, the time,
your wake-up time if an alarm is set, and the battery percentage. Two brightness levels —
brighter when you actually raise your wrist, dimmer in always-on.

**Always-on** shows the time in grey with the date, and shifts the whole picture by a few
pixels every minute to protect the AMOLED panel from burn-in.

## Settings

| Setting | Values | Default |
|---|---|---|
| Accent colour | Red, ice blue, bronze, pine, or auto | Auto |
| Rune ring | Solar or classic | Solar |
| Night screen | On or off | On |

With **auto**, the accent follows Body Battery: blue above 80, bronze around 50, red at 20
and below. The accent tints the colon, the diamond on the battery strip, the current hour's
rune, the ætt rune and the notification rune.

> Sideloaded apps have no settings screen in Garmin Connect. To change a default locally,
> edit `resources/settings/properties.xml` and rebuild. Settings become editable once the app
> is published to the Connect IQ Store.

## Requirements

- Connect IQ SDK 9.2.0 or newer
- A Connect IQ developer key at `../developer_key` (outside the repository)
- Device `venu445mm` — Venu 4 45 mm, 454×454, `minApiLevel` 4.2.0

## Building

In VS Code with the Monkey C extension: press **F5** for the simulator, or
**Monkey C: Build for Device** for a `.prg`.

From the command line:

```bash
SDK=~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-…

# simulator
java -jar "$SDK/bin/monkeybrains.jar" -o bin/RuneRing.prg -f monkey.jungle \
     -y ../developer_key -d venu445mm_sim -w

# release build for the watch
java -jar "$SDK/bin/monkeybrains.jar" -o bin/RuneRing.prg -f monkey.jungle \
     -y ../developer_key -d venu445mm -r -w
```

The source is clean at the strictest type-check level; please keep it that way:

```bash
java -jar "$SDK/bin/monkeybrains.jar" -o /tmp/strict.prg -f monkey.jungle \
     -y ../developer_key -d venu445mm_sim -l 3 -w
```

## Installing on the watch (sideload)

1. Build a release `.prg`.
2. Connect the watch by cable. On macOS you need [OpenMTP](https://openmtp.ganeshrvel.com/) —
   the watch is an MTP device and will not appear in Finder. Quit Garmin Express first, it
   holds the connection.
3. Copy `RuneRing.prg` into `GARMIN/APPS`, replacing the old file of the same name.
4. Unplug. If the old version is still showing, switch to another watch face and back.

## Fonts

The face uses bitmap fonts generated from TTFs, containing only the characters actually drawn,
to keep memory down. `tools/genfont.py` builds them:

```bash
pip3 install pillow
python3 tools/genfont.py
```

Two things to remember:

- **Any new character on screen must be added to `genfont.py` first**, otherwise it renders as
  nothing on the watch.
- **Copy the printed `time` metrics into the `CT_*` constants afterwards, every time** — even
  when the character set has not changed. A different Pillow version rasterises slightly
  differently, and those constants are what centre the clock on its visible pixels. The script
  also prints the `VCENTER` correction that belongs in `CD_VDY`.

Digits and Latin letters come from **Cinzel**, Cyrillic from **Forum** (Cinzel has no
Cyrillic), with Forum's size tuned so its capitals match the digit height.

## Localisation

Day names, month names and the word order of the date live in string resources, not in code.
**English is the default** and the fallback for every locale without a folder of its own;
`resources-rus/` overrides it with Russian. `DateFormat` places the parts — `$1$` weekday,
`$2$` day, `$3$` month — so English reads `FRI SEP 26` and Russian reads `ПТ 26 СЕНТ`.

Adding a language means a new `resources-<code>/strings/strings.xml` (the codes are listed in
the SDK's `default.jungle`) plus that language's letters in `genfont.py`. Every string id must
be declared in each locale; there is no inheritance from the default.

## Project layout

```
manifest.xml                 watch face, minApiLevel 4.2.0, product venu445mm
source/
  RuneRingApp.mc             app entry, reloads settings when they change
  RuneRingView.mc            all drawing and data — the main file
  RuneRingDelegate.mc        taps → Complications.exitTo
resources/
  fonts/                     generated BMFont files — do not edit by hand
  settings/                  properties and the Garmin Connect settings screen
  strings/                   English, and the fallback for other locales
resources-rus/               Russian
tools/
  genfont.py                 bitmap font generator
  fonts/                     Cinzel and Forum sources, SIL OFL
```

## Roadmap

- 24-hour layout: at that width the clock leaves only 1.5 px next to the side metrics
- Sunrise and sunset as marks on the ring
- Step goal lighting up runes as you approach it
- Venu 4 41 mm support (needs its own fonts at 390×390)
- A Connect IQ Store beta, for settings and over-the-air updates

## Licences

Code is MIT, see [LICENSE](LICENSE).

The bundled fonts are **not** covered by it: Cinzel and Forum are both under the SIL Open Font
License 1.1, and so are the bitmap fonts derived from them. See
[tools/fonts/OFL.txt](tools/fonts/OFL.txt) for the notices and the full licence text.

No third-party trademarks or franchise assets are used anywhere in the design.

## Notes for contributors

Developer documentation — design decisions, layout maths, the gotchas that cost hours — lives
in [CLAUDE.md](CLAUDE.md). It and the code comments are written in Russian.
