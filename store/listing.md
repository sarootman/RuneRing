# Connect IQ Store listing

Copy-paste source for apps.garmin.com. Keep this file in step with the app.

- **Name:** Rune Ring
- **Category:** Watch Faces
- **Version:** 1.0.0
- **Device:** Venu 4 45 mm (also covers D2 Air X15 — same device group)
- **Languages declared:** English (default), Russian
- **Tags:** runes, norse, viking, elder futhark, 24 hour, body battery, stress, minimal, amoled
- **Source:** https://github.com/sarootman/RuneRing

---

## Description — English

Twenty-four runes of the Elder Futhark ring the dial, one for every hour of the day. The rune
of the hour you are in glows in the accent colour, the hours behind you stay pale, the ones
ahead stay dark. A glance tells you not just the time, but where you stand in the day.

Nothing here is an icon in the ordinary sense. Every measurement is a rune, chosen for what it
means: ᚾ naudiz, "need", for stress. ᚨ ansuz, "the message", for unread notifications.
ᚱ raidho, "the road", for steps. ᚲ kaunan, "the torch", for calories. ᛊ sowilo, "the sun", for
Body Battery. Only heart rate keeps a heart, cut as if from stone.

Below the time stands the rune of the current ætt — the group of eight the hour belongs to:
Freyr's through the night, Hagal's through the day, Týr's through the evening.

ON THE DIAL
• Time set in Cinzel, centred on the digits themselves rather than their boxes
• Date, in your language
• Watch battery as a strip that fills outward from the centre and turns red at 20%
• Stress, and unread notifications whenever you have any
• Heart rate and Body Battery either side of the time
• Steps and calories below
• Tap any measurement to open the matching Garmin screen

THE RING
Two orientations. Solar, the default: noon at the top, midnight at the bottom, morning on the
left, evening on the right — where the sun itself stands for an observer facing south.
Classic: midnight at the top, like an ordinary 24-hour dial.

AT NIGHT
Inside the sleep window from your Garmin Connect profile the face turns red and quiet — the
time, your wake-up hour, the battery, and a moon when Do Not Disturb is on. Nothing bright
enough to spoil your night vision, and nothing you do not need at three in the morning.

ALWAYS-ON
The time in grey with the date and the rune of the ætt, drifting a few pixels every minute to
spare the AMOLED panel.

SETTINGS
Accent colour — red, ice blue, bronze, pine, or automatic, in which case it follows Body
Battery from blue through bronze to red as your reserves drain. Ring orientation. Night screen
on or off.

Fonts: Cinzel and Forum, both under the SIL Open Font License 1.1.

---

## Description — Russian

Двадцать четыре руны Старшего футарка идут по краю циферблата — по одной на каждый час суток.
Руна текущего часа горит акцентным цветом, прошедшие часы остаются светлыми, будущие — тёмными.
Одного взгляда хватает, чтобы понять не только время, но и где ты внутри дня.

Здесь нет иконок в привычном смысле. Каждый показатель — руна, выбранная по значению: ᚾ наудиз,
«нужда», — стресс. ᚨ ансуз, «весть», — непрочитанные уведомления. ᚱ райдо, «путь», — шаги.
ᚲ кауна, «факел», — калории. ᛊ соулу, «солнце», — Body Battery. Только у пульса осталось
сердце, гранёное, будто вырезанное из камня.

Под временем стоит руна текущего атта — той восьмёрки, в которую попадает час: атт Фрейра
ночью, атт Хагала днём, атт Тюра вечером.

НА ЦИФЕРБЛАТЕ
• Время шрифтом Cinzel, центрованное по самим цифрам, а не по их ячейкам
• Дата на твоём языке
• Заряд часов полоской, которая растёт от центра к краям и краснеет на двадцати процентах
• Стресс и, если есть непрочитанные, уведомления
• Пульс и Body Battery по бокам от времени
• Шаги и калории снизу
• Касание любого показателя открывает соответствующий экран Garmin

КОЛЬЦО
Две ориентации. Солнечная по умолчанию: полдень сверху, полночь снизу, утро слева, вечер
справа — там, где и стоит само светило для наблюдателя, смотрящего на юг. Классическая:
полночь сверху, как на обычном 24-часовом циферблате.

НОЧЬЮ
В окне сна из профиля Garmin Connect циферблат становится красным и немногословным: время,
час подъёма, заряд и луна, если включён режим «Не беспокоить». Ничего яркого, что собьёт
ночное зрение, и ничего лишнего, что не нужно в три часа ночи.

ЭКОНОМИЧНЫЙ РЕЖИМ
Время серым, дата и руна атта. Картинка смещается на несколько пикселей каждую минуту, чтобы
поберечь AMOLED.

НАСТРОЙКИ
Цвет акцента — красный, ледяной синий, бронза, хвоя или автоматический: тогда он идёт за Body
Battery от синего через бронзу к красному по мере того, как садятся силы. Ориентация кольца.
Ночной экран можно выключить.

Шрифты: Cinzel и Forum, оба под лицензией SIL Open Font License 1.1.

---

## Release notes 1.0.0

**English:** First release.

**Russian:** Первый выпуск.

---

## Why the app asks for each permission

Reviewers check that every declared permission is actually used. Short answers if asked:

- **SensorHistory** — reading Body Battery and stress when the complication has no value yet,
  for instance right after the watch is put back on.
- **UserProfile** — the sleep schedule, which decides when the night screen takes over.
- **ComplicationSubscriber** — reading Body Battery and stress the same way the native watch
  faces do, so the numbers match what the rest of the watch shows.

The face makes no network requests and stores nothing about the wearer.

---

## Before uploading

- Export the package: Monkey C: Export Project, or
  `java -jar monkeybrains.jar -e -o RuneRing.iq -f monkey.jungle -y ../developer_key -r -w`
- Publish as a **beta** first: the review bar is lower, and settings in Garmin Connect plus
  over-the-air updates start working immediately.
- The application id in manifest.xml must never change after the first upload.
