import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;
import Toybox.WatchUi;

// ---------- Palette ----------
const COLOR_BG    = 0x000000;
const COLOR_TEXT  = 0xEEEEEE;
const COLOR_MUTED = 0xA3A3A3;
const COLOR_ICON  = 0x8A8A8A;
const COLOR_RUNE  = 0x505050;        // hours still to come
const COLOR_RUNE_PAST = 0xA8A8A8;    // hours already past
const COLOR_LINE  = 0x8A8A8A;
const COLOR_RING  = 0x1C1C1C;
const COLOR_AOD     = 0x7A7A7A;
const COLOR_AOD_DIM = 0x5A5A5A;   // date in always-on
// At night, red only: it does not dazzle and does not spoil night vision.
// Two levels: brighter when the screen is awake (anything dimmer is unreadable),
// muted in always-on.
const COLOR_NIGHT          = 0xB0453A;   // time, screen awake
const COLOR_NIGHT_DIM      = 0x8A382E;   // secondary, screen awake
const COLOR_NIGHT_AOD      = 0x6B2A24;   // time in always-on
const COLOR_NIGHT_DIM_AOD  = 0x4A1D19;   // secondary in always-on

// Red, ice blue, bronze, pine
const ACCENTS = [0xC8372D, 0x4FA8E0, 0xB8925A, 0x8FB5A0];

// The Elder Futhark drawn as line segments.
// Every 4 numbers are one segment x1,y1,x2,y2. x: -3..3 from the rune axis, y: 0 (top) .. 10 (bottom).
const RUNES = [
    [-1,0,-1,10, -1,3,2,0, -1,6,2,3],                          // ᚠ fehu
    [-2,10,-2,0, -2,0,2,4, 2,4,2,10],                          // ᚢ uruz
    [-1,0,-1,10, -1,3,2,5, 2,5,-1,7],                          // ᚦ thurisaz
    [-1,0,-1,10, -1,0,2,3, -1,3,2,6],                          // ᚨ ansuz
    [-2,0,-2,10, -2,0,2,2, 2,2,-2,5, -2,5,2,10],               // ᚱ raidho
    [1,2,-1,5, -1,5,1,8],                                      // ᚲ kaunan
    [-2,1,2,9, 2,1,-2,9],                                      // ᚷ gebo
    [-1,0,-1,10, -1,0,2,2, 2,2,-1,5],                          // ᚹ wunjo
    [-2,0,-2,10, 2,0,2,10, -2,3,2,7],                          // ᚺ hagalaz
    [0,0,0,10, -2,3,2,6],                                      // ᚾ naudiz
    [0,0,0,10],                                                // ᛁ isa
    [-1,1,-3,4, -3,4,-1,7, 1,3,3,6, 3,6,1,9],                  // ᛃ jera
    [0,0,0,10, 0,0,2,2, 0,10,-2,8],                            // ᛇ eihwaz
    [-2,0,-2,10, -2,0,1,3, 1,3,2,1, -2,10,1,7, 1,7,2,9],       // ᛈ perthro
    [0,0,0,10, 0,4,-2,1, 0,4,2,1],                             // ᛉ algiz
    [1,0,-1,3, -1,3,1,7, 1,7,-1,10],                           // ᛊ sowilo
    [0,0,0,10, 0,0,-2,3, 0,0,2,3],                             // ᛏ tiwaz
    [-2,0,-2,10, -2,0,1,2, 1,2,-2,5, -2,5,1,8, 1,8,-2,10],     // ᛒ berkano
    [-2,0,-2,10, 2,0,2,10, -2,0,0,3, 0,3,2,0],                 // ᛖ ehwaz
    [-2,0,-2,10, 2,0,2,10, -2,0,2,4, 2,0,-2,4],                // ᛗ mannaz
    [-1,0,-1,10, -1,0,2,3],                                    // ᛚ laguz
    [0,2,2,5, 2,5,0,8, 0,8,-2,5, -2,5,0,2],                    // ᛜ ingwaz
    [-2,0,-2,10, 2,0,2,10, -2,0,2,10, 2,0,-2,10],              // ᛞ dagaz
    [0,0,2,3, 0,0,-2,3, 2,3,-2,8, -2,3,2,8]                    // ᛟ othala
];
const RUNE_DAGAZ = 22;   // "dawn" — the rune of the night screen

// Metrics of the generated Cinzel fonts, in pixels: the blank margin to the left
// and right of a visible digit, and the top and bottom of the visible digits.
//                 0  1  2  3  4  5  6  7  8  9
const CT_L    = [6, 5, 6, 5, 3, 4, 6, 3, 5, 6];
const CT_R    = [5, 5, 3, 7, 5, 7, 5, 3, 6, 6];
const CT_TOP  = 2;
const CT_BOT  = 85;
// The date font is drawn with VCENTER, which centres the line box rather than the ink.
// Cinzel's Latin added a descender to that box ("J"), pushing the visible digits 3 px up.
// tools/genfont.py prints this value on every regeneration.
const CD_VDY  = 3;
// The night and always-on screens carry nothing but the time, so it is set larger there:
// CinzelAod, 100 px digits against 83 on the main dial. Metrics come from genfont.py.
const CN_L    = [7, 7, 7, 7, 4, 5, 8, 3, 7, 7];
const CN_R    = [7, 6, 4, 8, 5, 9, 7, 4, 7, 8];
const CN_TOP  = 2;
const CN_BOT  = 102;
const CN_GAP  = 11;       // colon gap, scaled to the larger digits

// Burn-in drift for the always-on screen: eight points on a small circle. Consecutive
// minutes move about 3 px and the cycle closes, so nothing jumps. The first version
// stepped along a diagonal and snapped 12 px back at the end of the cycle, which read
// as the whole face twitching to the bottom right and back.
const DRIFT = [4,0, 3,3, 0,4, -3,3, -4,0, -3,-3, 0,-4, 3,-3];

// Indices of the runes used as icons
const RUNE_ANSUZ  = 3;    // ᚨ mouth, message — notifications
const RUNE_RAIDHO = 4;    // ᚱ the road — steps
const RUNE_KAUNAN = 5;    // ᚲ torch, fire — calories
const RUNE_NAUDIZ = 9;    // ᚾ need, constraint — stress
const RUNE_SOWILO = 15;   // ᛊ sun, energy — Body Battery
const COLOR_TRACK = 0x262626;   // the empty part of the battery strip

// Layout, in pixels of the 454×454 design
// The centre of the visible time digits sits exactly at the screen centre (454 / 2).
// It used to be 214.5, the midpoint between the strip at 131 and the icons at 298,
// which left the time 12.5 px high. Heart rate and Body Battery follow this value.
const TIME_CY  = 227.0;
const SIDE_X   = 157;     // nominal column for heart rate and Body Battery; layoutTime() refines it
const RING_INNER = 191;   // innermost rune pixel sits at radius 193, keep 2 px clear of it
const BOTTOM_X = 62;      // steps and calories, the two bottom columns
// The bottom block keeps the same distance from the time as the row above it: the time ink
// ends at 268.5, the topmost ink below is the calories rune at BOTTOM_ICON_Y - 12, so both
// gaps come out at 15 px. Values stay 30 px under the icons, as before.
const BOTTOM_ICON_Y = 295.5;
const BOTTOM_VAL_Y  = 325.5;
// The ætt rune is the signature mark of the face, so it is drawn larger than the metric
// runes and centred in what is left between the values (ink ends at 338) and the ring
// (its innermost pixel at the bottom is y 420).
const AETT_Y    = 368;
const AETT_UNIT = 2.2;
// The stress-and-notifications row sits between the battery strip (131) and the time
// digits (185.5): with an 18 px rune and 25 px digits, 18 px of air is left above and below.
const TOP_ROW_Y = 158;

// What decides that it is night
const NIGHT_PROFILE = 0;   // sleepTime/wakeTime from the Garmin Connect profile
const NIGHT_MANUAL  = 1;   // the times in the settings
const NIGHT_DND     = 2;   // Do Not Disturb, which Sleep Mode switches on

// Colours for the automatic accent: plenty of energy → blue, middling → bronze, low → red
const BB_HIGH = 0x4FA8E0;
const BB_MID  = 0xB8925A;
const BB_LOW  = 0xC8372D;

class RuneRingView extends WatchUi.WatchFace {

    private var _w as Number = 454;
    private var _cx as Float = 227.0;
    private var _cy as Float = 227.0;
    private var _s as Float = 1.0;          // scale relative to the 454 px design
    private var _accent as Number = 0xC8372D;
    private var _ring as Array<Array<Float>> = [];   // rune segments, pre-rotated around the dial
    private var _sleeping as Boolean = false;
    private var _dateFont as FontResource? = null;   // Cinzel + Forum (Cyrillic)
    private var _statsFont as FontResource? = null;
    private var _timeFont as FontResource? = null;
    private var _aodFont as FontResource? = null;
    private var _nightEnabled as Boolean = true;
    private var _accentAuto as Boolean = true;
    private var _ringClassic as Boolean = false;   // midnight at the top instead of noon
    private var _nightSource as Number = NIGHT_MANUAL;
    private var _nightStartText as String = "22:00";
    private var _wakeWeekdayText as String = "07:00";
    private var _wakeWeekendText as String = "08:00";
    private var _layoutReady as Boolean = false;

    // Localisation: day names, month names and the word order of the date come from resources
    private var _days as Array<String> = [];
    private var _months as Array<String> = [];
    private var _dateFmt as String = "$1$  $2$  $3$";

    // Layout in screen pixels — computed once in onLayout
    private var _timeCy as Float = 0.0;
    private var _sideX as Float = 0.0;
    private var _bottomX as Float = 0.0;
    private var _colonGap as Float = 13.0;         // gap each side of the colon
    private var _timeLaidOut as Boolean = false;
    private var _layoutIs24h as Boolean = false;
    private var _ringR as Float = 0.0;

    // Data that only needs refreshing once a minute
    private var _lastMin as Number = -1;
    private var _dateText as String? = null;
    private var _batt as Number = 0;
    private var _lastBB as Number? = null;   // last known Body Battery reading
    private var _stress as Number? = null;   // last known stress level
    private var _sleepSec as Number? = null;    // start of the night window
    private var _wakeWeekday as Number? = null; // end of it, Monday to Friday
    private var _wakeWeekend as Number? = null; // end of it, Saturday and Sunday
    private var _wakeNow as Number? = null;     // the one that applies to the night we are in
    private var _dow as Number = 1;             // 1 = Sunday … 7 = Saturday

    // Snapshot of DeviceSettings for the current frame
    private var _is24h as Boolean = false;
    private var _phoneOff as Boolean = false;
    private var _dnd as Boolean = false;
    private var _hasAlarm as Boolean = false;
    private var _notif as Number = 0;

    // Centres of the top-row groups — computed while drawing, used for hit testing
    private var _rowStressX as Float = 0.0;
    private var _rowNotifX as Float? = null;

    // Whether the normal screen is drawn: the night and always-on screens have nothing to tap
    private var _mainScreen as Boolean = false;

    function initialize() {
        WatchFace.initialize();
        loadSettings();
    }

    function loadSettings() as Void {
        var idx = 4;
        var v = Application.Properties.getValue("AccentColor");
        if (v instanceof Number && v >= 0 && v <= 4) {
            idx = v;
        }
        _accentAuto = (idx == 4);
        if (!_accentAuto) {
            _accent = ACCENTS[idx] as Number;
        }

        var n = Application.Properties.getValue("NightMode");
        _nightEnabled = (n instanceof Boolean) ? n : true;

        // The sleep schedule in the profile is one pair of times for the whole week, which is
        // all Connect IQ exposes. These let the window be set by hand instead, with a later
        // wake-up at weekends.
        var src = Application.Properties.getValue("NightSource");
        _nightSource = (src instanceof Number && src >= 0 && src <= 2) ? src : NIGHT_MANUAL;
        _nightStartText   = textProperty("NightStart", "22:00");
        _wakeWeekdayText  = textProperty("WakeWeekday", "07:00");
        _wakeWeekendText  = textProperty("WakeWeekend", "08:00");

        // The ring is rebuilt only when the style changes, and only once the screen size is known
        var r = Application.Properties.getValue("RingStyle");
        var classic = (r instanceof Number) && (r == 1);
        if (classic != _ringClassic) {
            _ringClassic = classic;
            if (_layoutReady) {
                buildRing();
            }
        }
    }

    private function textProperty(key as String, fallback as String) as String {
        var v = Application.Properties.getValue(key);
        return (v instanceof String && v.length() > 0) ? v : fallback;
    }

    // "7:30", "07:30" or "7" into seconds from midnight; null if it makes no sense
    private function parseTimeOfDay(text as String) as Number? {
        var h = 0;
        var m = 0;
        var i = text.find(":");
        if (i == null) {
            var n = text.toNumber();
            if (n == null) {
                return null;
            }
            h = n;
        } else {
            var hs = text.substring(0, i);
            var ms = text.substring(i + 1, text.length());
            if (hs == null || ms == null) {
                return null;
            }
            var hn = hs.toNumber();
            var mn = ms.toNumber();
            if (hn == null || mn == null) {
                return null;
            }
            h = hn;
            m = mn;
        }
        if (h < 0 || h > 23 || m < 0 || m > 59) {
            return null;
        }
        return h * 3600 + m * 60;
    }

    function onLayout(dc as Dc) as Void {
        _w = dc.getWidth();
        _cx = dc.getWidth() / 2.0;
        _cy = dc.getHeight() / 2.0;
        _s = _w / 454.0;
        _timeCy  = TIME_CY * _s;
        _sideX   = SIDE_X * _s;
        _bottomX = BOTTOM_X * _s;
        _ringR   = 224 * _s;
        buildRing();
        // loadResource is typed as "any resource", so cast explicitly
        _timeFont  = WatchUi.loadResource(Rez.Fonts.CinzelTime) as FontResource;
        _aodFont   = WatchUi.loadResource(Rez.Fonts.CinzelAod) as FontResource;
        _statsFont = WatchUi.loadResource(Rez.Fonts.CinzelStats) as FontResource;
        _dateFont  = WatchUi.loadResource(Rez.Fonts.CinzelDate) as FontResource;

        // The system picks the language: resources/ is English, resources-rus/ is Russian
        _days   = splitCommas(WatchUi.loadResource(Rez.Strings.Days) as String);
        _months = splitCommas(WatchUi.loadResource(Rez.Strings.Months) as String);
        _dateFmt = WatchUi.loadResource(Rez.Strings.DateFormat) as String;
        _layoutReady = true;
    }

    // Monkey C has no split, and one resource string per list is easier to translate
    private function splitCommas(text as String) as Array<String> {
        var out = [] as Array<String>;
        var rest = text;
        var i = rest.find(",");
        while (i != null) {
            var head = rest.substring(0, i);
            out.add(head != null ? head : "");
            var tail = rest.substring(i + 1, rest.length());
            rest = (tail != null) ? tail : "";
            i = rest.find(",");
        }
        out.add(rest);
        return out;
    }

    // Rotate the 24 runes around the centre once, instead of every minute
    private function buildRing() as Void {
        _ring = [];
        var unit = 1.8 * _s;               // a rune is about 18 px tall
        var top = 16.0 * _s;               // inset from the screen edge
        for (var i = 0; i < 24; i++) {
            // Rune i is hour i. Solar ring: noon (ᛇ) at the top, midnight (ᚠ) at the bottom —
            // where the sun itself stands. Classic: midnight at the top, like an ordinary
            // 24-hour dial. Both run clockwise; only the origin differs.
            var a = Math.toRadians(i * 15.0 + (_ringClassic ? 0.0 : 180.0));
            var c = Math.cos(a);
            var sn = Math.sin(a);
            var seg = RUNES[i] as Array<Number>;
            var out = new Array<Float>[seg.size()];
            for (var k = 0; k < seg.size(); k += 2) {
                var dx = seg[k] * unit;
                var dy = -(_cy - top) + seg[k + 1] * unit;
                out[k] = (_cx + dx * c - dy * sn).toFloat();
                out[k + 1] = (_cy + dx * sn + dy * c).toFloat();
            }
            _ring.add(out);
        }
    }

    function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        var clock = System.getClockTime();
        var h24 = hour24(clock);

        // Fetch DeviceSettings once per frame: the object used to be built three times
        var ds = System.getDeviceSettings();
        _is24h    = ds.is24Hour;
        _phoneOff = !ds.phoneConnected;
        _dnd      = ds.doNotDisturb;
        var ac    = ds.alarmCount;
        _hasAlarm = (ac != null && ac > 0);
        var nc    = ds.notificationCount;
        _notif    = (nc != null) ? nc : 0;

        // The widest possible time depends on the clock format, and the side metrics
        // are placed against it. Recomputed only when the format changes.
        if (!_timeLaidOut || _is24h != _layoutIs24h) {
            _layoutIs24h = _is24h;
            _timeLaidOut = true;
            layoutTime(dc);
        }

        // While the screen is awake onUpdate runs once a second, but the date, battery,
        // Body Battery and sleep schedule do not change anywhere near that often
        if (clock.min != _lastMin) {
            _lastMin = clock.min;
            refreshSlowData();
        }

        var hour = h24;
        var hh;
        if (_is24h) {
            hh = hour.format("%02d");
        } else {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
            hh = hour.format("%d");
        }
        var mm = clock.min.format("%02d");

        _wakeNow = wakeForTonight(h24, clock.min);

        _mainScreen = false;
        if (_nightEnabled && isNightTime(h24, clock.min)) {
            drawNight(dc, hh, mm, clock.min);
            return;
        }

        if (_sleeping) {
            drawAod(dc, hh, mm, clock.min, h24);
            return;
        }
        _mainScreen = true;

        var bbCol = bbColor(_lastBB);
        if (_accentAuto) {
            _accent = bbCol;
        }

        drawRing(dc, h24);
        drawDate(dc);
        drawDivider(dc, 131 * _s, _batt);
        drawTopRow(dc);
        drawTime(dc, hh, mm);
        drawStats(dc, _lastBB, bbCol);

        dc.setPenWidth(3);
        dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
        // Head rune of the current ætt: 00–07 ᚠ (Freyr), 08–15 ᚺ (Hagal/Heimdall), 16–23 ᛏ (Týr).
        // Rune i is hour i, so the head of the ætt is the rune at (hour / 8) * 8.
        drawRuneAt(dc, (h24 / 8) * 8, _cx, AETT_Y * _s, AETT_UNIT * _s);
    }

    // ---------- Elements ----------

    private function drawRing(dc as Dc, hour as Number) as Void {
        dc.setPenWidth(1);
        dc.setColor(COLOR_RING, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(_cx, _cy, _ringR);

        // Past hours pale, the current one accented, future ones dark.
        // Drawn in three passes: setColor costs more than an extra walk of the array,
        // and it used to be called 24 times per frame instead of three.
        dc.setPenWidth(_s > 0.9 ? 2 : 1);
        dc.setColor(COLOR_RUNE_PAST, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < hour; i++) {
            strokeRune(dc, i);
        }
        dc.setColor(COLOR_RUNE, Graphics.COLOR_TRANSPARENT);
        for (var i = hour + 1; i < _ring.size(); i++) {
            strokeRune(dc, i);
        }
        dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
        strokeRune(dc, hour);
    }

    private function strokeRune(dc as Dc, i as Number) as Void {
        var p = _ring[i];
        for (var k = 0; k < p.size(); k += 4) {
            dc.drawLine(p[k], p[k + 1], p[k + 2], p[k + 3]);
        }
    }

    private function drawRuneAt(dc as Dc, idx as Number, x as Numeric, top as Numeric, unit as Numeric) as Void {
        var seg = RUNES[idx] as Array<Number>;
        for (var k = 0; k < seg.size(); k += 4) {
            dc.drawLine(x + seg[k] * unit, top + seg[k + 1] * unit,
                        x + seg[k + 2] * unit, top + seg[k + 3] * unit);
        }
    }

    private function dateText(info as Gregorian.Info) as String {
        if (_days.size() < 7 || _months.size() < 12) {
            return "";
        }
        var dow = info.day_of_week as Number;
        var mon = info.month as Number;
        // $1$ weekday, $2$ day, $3$ month — the DateFormat resource decides the order
        return Lang.format(_dateFmt, [_days[dow - 1], info.day.format("%d"), _months[mon - 1]]);
    }

    private function drawDate(dc as Dc) as Void {
        var text = _dateText;
        var font = _dateFont;
        if (text == null || font == null) {
            return;
        }
        var y = 106 * _s;
        dc.setColor(COLOR_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, y + CD_VDY * _s, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // the dot to the right of the date means the phone is disconnected
        if (_phoneOff) {
            var w = dc.getTextWidthInPixels(text, font);
            dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_cx + w / 2.0 + 12 * _s, y, 4 * _s);
        }
    }

    // The strip between the date and the time is the watch battery.
    // The filled part grows outward from the diamond: 100% fills the whole strip,
    // 50% fills half of each side. At 20% and below it turns red.
    private function drawDivider(dc as Dc, y as Numeric, batt as Number) as Void {
        var gap = 12 * _s;
        var len = 88 * _s;
        var fill = len * (batt < 0 ? 0 : (batt > 100 ? 100 : batt)) / 100.0;

        dc.setPenWidth(2);
        dc.setColor(COLOR_TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(_cx - gap - len, y, _cx - gap, y);
        dc.drawLine(_cx + gap, y, _cx + gap + len, y);

        if (fill > 0) {
            dc.setColor(batt <= 20 ? BB_LOW : COLOR_LINE, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(_cx - gap - fill, y, _cx - gap, y);
            dc.drawLine(_cx + gap, y, _cx + gap + fill, y);
        }

        var r = 5 * _s;
        dc.setPenWidth(2);
        dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(_cx, y - r, _cx + r, y);
        dc.drawLine(_cx + r, y, _cx, y + r);
        dc.drawLine(_cx, y + r, _cx - r, y);
        dc.drawLine(_cx - r, y, _cx, y - r);
    }

    // Where the side metrics stand depends on how wide the time can get. In 24-hour
    // format the time is 26 px wider than in 12-hour, and with three-digit values
    // (heart rate over 100, Body Battery at 100) only 1.5 px was left between them.
    // The column is placed in the middle of the corridor between the widest possible
    // time and the rune ring, so nothing moves as the digits change. Widths come from
    // the font itself, so regenerating it cannot put the layout out of step.
    private function layoutTime(dc as Dc) as Void {
        var font = _timeFont;
        if (font == null) {
            return;
        }
        // a tighter colon buys back 4 px of half-width where it is needed most
        _colonGap = (_is24h ? 9 : 13) * _s;

        var adv = new Array<Number>[10];
        for (var d = 0; d < 10; d++) {
            adv[d] = dc.getTextWidthInPixels(d.format("%d"), font);
        }

        var maxHour = 0;
        if (_is24h) {
            for (var h = 0; h < 24; h++) {
                var w = inkWidth(adv, h.format("%02d"));
                if (w > maxHour) { maxHour = w; }
            }
        } else {
            for (var h = 1; h <= 12; h++) {
                var w = inkWidth(adv, h.format("%d"));
                if (w > maxHour) { maxHour = w; }
            }
        }
        var maxMin = 0;
        for (var m = 0; m < 60; m++) {
            var w = inkWidth(adv, m.format("%02d"));
            if (w > maxMin) { maxMin = w; }
        }

        var half = (maxHour + 2 * _colonGap + maxMin) / 2.0;
        _sideX = ((half + RING_INNER * _s) / 2.0).toFloat();
    }

    // Visible width of a digit string: advances minus the blank margins at both ends
    private function inkWidth(adv as Array<Number>, text as String) as Number {
        var w = 0;
        for (var i = 0; i < text.length(); i++) {
            w += adv[digitAt(text, i)];
        }
        return w - CT_L[digitAt(text, 0)] - CT_R[digitAt(text, text.length() - 1)];
    }

    // Draws "hh : mm" so that the visible digits are exactly centred on (cx, cy).
    // The colon is two accent-coloured marks.
    private function drawDigits(dc as Dc, font as WatchUi.FontResource,
                                bl as Array<Number>, br as Array<Number>, inkTop as Number, inkBot as Number,
                                cx as Numeric, cy as Numeric, hh as String, mm as String,
                                gap as Numeric, dotR as Numeric, dotDy as Numeric,
                                color as Number, dotColor as Number) as Void {
        var wh = dc.getTextWidthInPixels(hh, font);
        var wm = dc.getTextWidthInPixels(mm, font);
        var h0 = digitAt(hh, 0);
        var h1 = digitAt(hh, hh.length() - 1);
        var m0 = digitAt(mm, 0);
        var m1 = digitAt(mm, mm.length() - 1);

        // visible width: from the left edge of the first digit to the right edge of the last
        var hhInk = wh - bl[h0] - br[h1];
        var mmInk = wm - bl[m0] - br[m1];
        var inkLeft = cx - (hhInk + 2 * gap + mmInk) / 2.0;
        var colonX = inkLeft + hhInk + gap;
        var yTop = cy - (inkTop + inkBot) / 2.0;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(inkLeft - bl[h0], yTop, font, hh, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(colonX + gap - bl[m0], yTop, font, mm, Graphics.TEXT_JUSTIFY_LEFT);

        // a colon of two diamonds, like marks cut in stone
        dc.setColor(dotColor, Graphics.COLOR_TRANSPARENT);
        fillDiamond(dc, colonX, cy - dotDy, dotR);
        fillDiamond(dc, colonX, cy + dotDy, dotR);
    }

    // substring and toNumber are declared nullable in the API, so unpack them explicitly
    private function digitAt(text as String, i as Number) as Number {
        var c = text.substring(i, i + 1);
        if (c == null) {
            return 0;
        }
        var n = c.toNumber();
        return (n == null) ? 0 : n;
    }

    // The row above the time: ᚾ stress and, if anything is unread, ᚨ notifications.
    // The groups are centred as one block, so with no notifications the stress
    // group ends up in the middle by itself.
    private function drawTopRow(dc as Dc) as Void {
        var f = _statsFont;
        if (f == null) {
            return;
        }
        var y = TOP_ROW_Y * _s;
        var unit = 1.8 * _s;            // the same rune height as in the ring
        var runeW = 4 * unit;
        var gap = 7 * _s;               // between a rune and its number
        var sep = 30 * _s;              // between the two groups

        var sText = (_stress != null) ? (_stress as Number).format("%d") : "--";
        var sW = runeW + gap + dc.getTextWidthInPixels(sText, f);

        var nText = null;
        var nW = 0.0;
        if (_notif > 0) {
            nText = _notif.format("%d");
            nW = runeW + gap + dc.getTextWidthInPixels(nText, f);
        }

        var total = (nText != null) ? sW + sep + nW : sW;
        var x = _cx - total / 2.0;
        var j = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        // Stress: the rune carries the colour, the number stays white, as with Body Battery
        _rowStressX = x + sW / 2.0;
        dc.setPenWidth(2);
        dc.setColor(stressColor(_stress), Graphics.COLOR_TRANSPARENT);
        drawRuneAt(dc, RUNE_NAUDIZ, x + runeW / 2.0, y - 5 * unit, unit);
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + runeW + gap, y, f, sText, j);

        if (nText == null) {
            _rowNotifX = null;
            return;
        }

        // Notifications: accented rune, like the dot for a disconnected phone
        x += sW + sep;
        _rowNotifX = x + nW / 2.0;
        dc.setPenWidth(2);
        dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
        drawRuneAt(dc, RUNE_ANSUZ, x + runeW / 2.0 - 0.5 * unit, y - 5 * unit, unit);
        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + runeW + gap, y, f, nText, j);
    }

    // Stress runs opposite to Body Battery: calm is blue, strain is red.
    // Garmin's bands: up to 25 rest, 26–50 low, 51–75 medium, above that high.
    private function stressColor(v as Number?) as Number {
        if (v == null) { return COLOR_ICON; }
        if (v <= 25) { return BB_HIGH; }
        if (v >= 75) { return BB_LOW; }
        if (v <= 50) { return mix(BB_HIGH, BB_MID, (v - 25) / 25.0); }
        return mix(BB_MID, BB_LOW, (v - 50) / 25.0);
    }

    private function fillDiamond(dc as Dc, x as Numeric, y as Numeric, r as Numeric) as Void {
        dc.fillPolygon([[x, y - r], [x + r, y], [x, y + r], [x - r, y]]);
    }

    private function drawTime(dc as Dc, hh as String, mm as String) as Void {
        var font = _timeFont;
        if (font == null) {
            return;
        }
        var cy = _timeCy;
        drawDigits(dc, font, CT_L, CT_R, CT_TOP, CT_BOT,
                   _cx, cy, hh, mm, _colonGap, 5 * _s, 16 * _s, COLOR_TEXT, _accent);
    }

    // Accent from Body Battery: 80+ blue → 50 bronze → 20 and below red
    private function bbColor(bb as Number?) as Number {
        if (bb == null) { return BB_MID; }
        if (bb >= 80) { return BB_HIGH; }
        if (bb <= 20) { return BB_LOW; }
        if (bb >= 50) { return mix(BB_MID, BB_HIGH, (bb - 50) / 30.0); }
        return mix(BB_LOW, BB_MID, (bb - 20) / 30.0);
    }

    private function mix(a as Number, b as Number, t as Float) as Number {
        var r = ((a >> 16) & 0xFF) + ((((b >> 16) & 0xFF) - ((a >> 16) & 0xFF)) * t);
        var g = ((a >> 8) & 0xFF) + ((((b >> 8) & 0xFF) - ((a >> 8) & 0xFF)) * t);
        var bl = (a & 0xFF) + (((b & 0xFF) - (a & 0xFF)) * t);
        return (r.toNumber() << 16) | (g.toNumber() << 8) | bl.toNumber();
    }

    // Which metric is under the finger, or null for a miss.
    function complicationAt(x as Number, y as Number) as Complications.Type? {
        if (!_mainScreen) {       // the night and always-on screens show no metrics
            return null;
        }
        var cy = _timeCy;
        var side = _sideX;
        var bx = _bottomX;
        if ((y - cy).abs() <= 40 * _s) {
            if ((x - (_cx - side)).abs() <= 30 * _s) { return Complications.COMPLICATION_TYPE_HEART_RATE; }
            if ((x - (_cx + side)).abs() <= 30 * _s) { return Complications.COMPLICATION_TYPE_BODY_BATTERY; }
        }
        if (y >= 138 * _s && y <= 180 * _s) {
            var nx = _rowNotifX;
            if (nx != null && (x - nx).abs() <= 34 * _s) {
                return Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT;
            }
            if ((x - _rowStressX).abs() <= 40 * _s) {
                return Complications.COMPLICATION_TYPE_STRESS;
            }
        }
        if (y >= 275 * _s && y <= 350 * _s) {
            if ((x - (_cx - bx)).abs() <= 50 * _s) { return Complications.COMPLICATION_TYPE_STEPS; }
            if ((x - (_cx + bx)).abs() <= 50 * _s) { return Complications.COMPLICATION_TYPE_CALORIES; }
        }
        return null;
    }

    // Metric layout:
    //   left and right of the time, heart rate and Body Battery, icon above number;
    //   along the bottom in two columns, steps and calories.
    private function drawStats(dc as Dc, bb as Number?, bbCol as Number) as Void {
        var cy = _timeCy;
        var side = _sideX;
        var bx = _bottomX;
        var iconY = BOTTOM_ICON_Y * _s;
        var valY = BOTTOM_VAL_Y * _s;

        var am = ActivityMonitor.getInfo();
        var steps = am.steps;
        var kcal = am.calories;
        var hr = getHeartRate();

        iconHeart(dc, _cx - side, cy - 18 * _s);
        iconBolt(dc, _cx + side, cy - 18 * _s, bbCol);
        iconSteps(dc, _cx - bx, iconY);
        iconCalories(dc, _cx + bx, iconY);

        dc.setColor(COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        var j = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var f = _statsFont;
        if (f == null) {
            return;
        }
        dc.drawText(_cx - side, cy + 15 * _s, f, hr != null ? hr.format("%d") : "--", j);
        dc.drawText(_cx + side, cy + 15 * _s, f, bb != null ? bb.format("%d") : "--", j);
        dc.drawText(_cx - bx, valY, f, steps != null ? steps.format("%d") : "--", j);
        dc.drawText(_cx + bx, valY, f, kcal != null ? kcal.format("%d") : "--", j);
    }

    // ---------- Icons: vector only, no bitmaps ----------

    // Steps — rune ᚱ raidho, "the ride, the road"
    private function iconSteps(dc as Dc, x as Numeric, y as Numeric) as Void {
        dc.setPenWidth(2);
        dc.setColor(COLOR_ICON, Graphics.COLOR_TRANSPARENT);
        drawRuneAt(dc, RUNE_RAIDHO, x + 1 * _s, y - 10 * _s, 2.0 * _s);
    }

    // Heart rate — a faceted heart, as if cut from stone. Always red.
    private function iconHeart(dc as Dc, x as Numeric, y as Numeric) as Void {
        var s = _s;
        dc.setColor(BB_LOW, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [x - 9 * s, y - 3 * s], [x - 5 * s, y - 9 * s], [x, y - 5 * s],
            [x + 5 * s, y - 9 * s], [x + 9 * s, y - 3 * s], [x, y + 9 * s]
        ]);
        // the central facet is a thin dark line
        dc.setPenWidth(1);
        dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y - 5 * s, x, y + 7 * s);
    }

    // Body Battery — rune ᛊ sowilo, "sun, energy".
    // The colour carries the level: blue → bronze → red.
    private function iconBolt(dc as Dc, x as Numeric, y as Numeric, color as Number) as Void {
        dc.setPenWidth(3);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        drawRuneAt(dc, RUNE_SOWILO, x, y - 10 * _s, 2.0 * _s);
    }

    // Calories — rune ᚲ kaunan, "torch, fire"
    private function iconCalories(dc as Dc, x as Numeric, y as Numeric) as Void {
        dc.setPenWidth(2);
        dc.setColor(COLOR_ICON, Graphics.COLOR_TRANSPARENT);
        drawRuneAt(dc, RUNE_KAUNAN, x + 1 * _s, y - 12 * _s, 2.6 * _s);
    }

    private function iconBell(dc as Dc, x as Numeric, y as Numeric, color as Number) as Void {
        var s = _s;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y - 3 * s, 5 * s);                          // dome
        dc.fillRectangle(x - 5 * s, y - 3 * s, 10 * s, 5 * s);       // body
        dc.fillPolygon([[x - 7 * s, y + 4 * s], [x + 7 * s, y + 4 * s],
                        [x + 5 * s, y + 1 * s], [x - 5 * s, y + 1 * s]]);  // skirt
        dc.fillCircle(x, y + 6.5 * s, 1.8 * s);                      // clapper
    }

    // ---------- Data ----------

    // Hour 0..23 regardless of the watch's clock settings.
    // On some firmware System.getClockTime().hour returns 1..12 when the watch is set
    // to a 12-hour format: the time rendered correctly, but the ring and the ætt rune
    // were off by twelve hours, lighting an evening hour as if it were morning. So we
    // work it out ourselves: UTC seconds plus the time zone offset, which already
    // includes daylight saving.
    private function hour24(clock as System.ClockTime) as Number {
        var local = (Time.now().value() + clock.timeZoneOffset) % 86400;
        if (local < 0) {                     // just in case: % is signed in Monkey C
            local += 86400;
        }
        return local / 3600;
    }

    // Date, battery, Body Battery and the sleep schedule: once a minute is enough.
    private function refreshSlowData() as Void {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        _dateText = dateText(info);
        _batt = System.getSystemStats().battery.toNumber();
        pollBodyBattery();
        pollStress();

        _dow = info.day_of_week as Number;

        if (_nightSource == NIGHT_PROFILE) {
            // no reason to read the profile every second either
            var p = UserProfile.getProfile();
            if (p != null && p.sleepTime != null && p.wakeTime != null) {
                _sleepSec = (p.sleepTime as Time.Duration).value();
                _wakeWeekday = (p.wakeTime as Time.Duration).value();
                _wakeWeekend = _wakeWeekday;
            } else {
                _sleepSec = null;
                _wakeWeekday = null;
                _wakeWeekend = null;
            }
        } else {
            // the manual times are parsed for the DND source too: the trigger differs, but
            // the wake-up shown beside the bell still has to come from somewhere
            _sleepSec    = parseTimeOfDay(_nightStartText);
            _wakeWeekday = parseTimeOfDay(_wakeWeekdayText);
            _wakeWeekend = parseTimeOfDay(_wakeWeekendText);
        }
    }

    // Which wake-up ends the night we are currently in. Past bedtime the night belongs to
    // tomorrow morning, so Friday evening is governed by Saturday's later wake-up.
    private function wakeForTonight(h24 as Number, minute as Number) as Number? {
        var sleep = _sleepSec;
        var weekday = _wakeWeekday;
        var weekend = _wakeWeekend;
        if (sleep == null || weekday == null || weekend == null) {
            return null;
        }
        var dow = _dow;
        if (h24 * 3600 + minute * 60 >= sleep) {
            dow = (dow % 7) + 1;
        }
        return (dow == 1 || dow == 7) ? weekend : weekday;   // 1 Sunday, 7 Saturday
    }

    private function getHeartRate() as Number? {
        var ai = Activity.getActivityInfo();
        if (ai != null && ai.currentHeartRate != null) {
            return ai.currentHeartRate;
        }
        if (ActivityMonitor has :getHeartRateHistory) {
            var sample = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return sample.heartRate;
            }
        }
        return null;
    }

    // Garmin metrics are read in two passes: first the value the native watch faces
    // see (Complications), then the most recent non-empty sample in the sensor history.
    // If neither has anything, keep the last known value — otherwise taking the watch
    // off and putting it back on left a dash on screen.
    private function pollBodyBattery() as Void {
        var v = complicationValue(Complications.COMPLICATION_TYPE_BODY_BATTERY);
        if (v == null && (Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
            v = lastSample(SensorHistory.getBodyBatteryHistory({
                :period => 30,
                :order => SensorHistory.ORDER_NEWEST_FIRST
            }));
        }
        if (v != null) {
            _lastBB = v;
        }
    }

    private function pollStress() as Void {
        var v = complicationValue(Complications.COMPLICATION_TYPE_STRESS);
        if (v == null && (Toybox has :SensorHistory) && (SensorHistory has :getStressHistory)) {
            v = lastSample(SensorHistory.getStressHistory({
                :period => 30,
                :order => SensorHistory.ORDER_NEWEST_FIRST
            }));
        }
        if (v != null) {
            _stress = v;
        }
    }

    private function complicationValue(type as Complications.Type) as Number? {
        if (!(Toybox has :Complications)) {
            return null;
        }
        try {
            var c = Complications.getComplication(new Complications.Id(type));
            if (c != null && c.value != null) {
                return (c.value as Numeric).toNumber();
            }
        } catch (e) {
            return null;
        }
        return null;
    }

    // Newest samples come first, but the leading ones may be empty — take the first that is not
    private function lastSample(it as SensorHistory.SensorHistoryIterator) as Number? {
        var sample = it.next();
        while (sample != null) {
            var d = sample.data;
            if (d != null) {
                return d.toNumber();
            }
            sample = it.next();
        }
        return null;
    }

    // ---------- Always-on, the low-power screen ----------

    private function drawAod(dc as Dc, hh as String, mm as String, minute as Number,
                             h24 as Number) as Void {
        var font = _aodFont;
        var dateFont = _dateFont;
        if (font == null || dateFont == null) {
            return;
        }
        // Shift the picture once a minute to protect the AMOLED panel from burn-in.
        // The step is derived from the minute rather than a call counter, which would
        // depend on how often the system wakes us.
        var k = (minute % 8) * 2;
        var dx = DRIFT[k] * _s;
        var dy = DRIFT[k + 1] * _s;

        // the same ætt head as on the main screen; this used to be hard-coded to ᛏ,
        // which was only right between 16:00 and 24:00
        // scaled to the larger always-on digits, and kept centred where it was
        dc.setPenWidth(3);
        dc.setColor(_accent, Graphics.COLOR_TRANSPARENT);
        drawRuneAt(dc, (h24 / 8) * 8, _cx + dx, 122 * _s + dy, 2.6 * _s);

        drawDigits(dc, font, CN_L, CN_R, CN_TOP, CN_BOT,
                   _cx + dx, 215 * _s + dy, hh, mm, CN_GAP * _s, 6 * _s, 19 * _s, COLOR_AOD, COLOR_AOD);

        var text = _dateText;
        if (text != null) {
            dc.setColor(COLOR_AOD_DIM, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_cx + dx, 296 * _s + dy + CD_VDY * _s, dateFont, text,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // ---------- Night screen ----------

    // Sleep window from the Garmin Connect profile, refreshed in refreshSlowData()
    private function isNightTime(h24 as Number, minute as Number) as Boolean {
        if (_nightSource == NIGHT_DND) {
            return _dnd;
        }
        var sleep = _sleepSec;
        var wake = _wakeNow;
        if (sleep == null || wake == null) {
            return false;
        }
        var now = h24 * 3600 + minute * 60;
        if (sleep > wake) {                     // for example 23:00 → 07:00
            return now >= sleep || now < wake;
        }
        return now >= sleep && now < wake;
    }

    private function drawNight(dc as Dc, hh as String, mm as String, minute as Number) as Void {
        var font = _aodFont;
        var dateFont = _dateFont;
        if (font == null || dateFont == null) {
            return;
        }
        // The burn-in shift is only needed in always-on, where the screen stays lit for
        // hours and updates arrive once a minute. An awake screen calls onUpdate once a
        // second, and a counter-driven shift made the whole face jump. So leave it still.
        var k = (minute % 8) * 2;
        var off = _sleeping ? DRIFT[k + 1] * _s : 0.0;      // vertical part of the drift
        var x = _cx + (_sleeping ? DRIFT[k] * _s : 0.0);
        // awake screen brighter, always-on muted
        var bright = _sleeping ? COLOR_NIGHT_AOD : COLOR_NIGHT;
        var dim    = _sleeping ? COLOR_NIGHT_DIM_AOD : COLOR_NIGHT_DIM;
        var j = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        // Top: a moon when Do Not Disturb or sleep mode is on, otherwise the rune
        if (_dnd) {
            iconMoon(dc, x, 132 * _s + off, dim);
        } else {
            dc.setPenWidth(3);
            dc.setColor(dim, Graphics.COLOR_TRANSPARENT);
            drawRuneAt(dc, RUNE_DAGAZ, x, 112 * _s + off, 3.0 * _s);
        }

        // Time
        drawDigits(dc, font, CN_L, CN_R, CN_TOP, CN_BOT,
                   x, 222 * _s + off, hh, mm, CN_GAP * _s, 6 * _s, 19 * _s, bright, bright);

        // Bottom: the bell and the wake-up time
        var nextY = 310 * _s;
        var wake = wakeTimeText();
        if (_hasAlarm && wake != null) {
            var tw = dc.getTextWidthInPixels(wake, dateFont);
            var total = 18 * _s + 10 * _s + tw;
            var left = x - total / 2.0;
            iconBell(dc, left + 9 * _s, nextY + off, dim);
            dc.setColor(dim, Graphics.COLOR_TRANSPARENT);
            dc.drawText(left + 28 * _s, nextY + off + CD_VDY * _s, dateFont, wake,
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            nextY += 36 * _s;
        }

        // battery always shown; at 20% and below a little brighter, to catch the eye at bedtime
        dc.setColor(_batt <= 20 ? bright : dim, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, nextY + off + CD_VDY * _s, dateFont, _batt.format("%d") + "%", j);
    }

    // The wake-up time that ends tonight — from the settings, or from the Garmin Connect
    // sleep schedule. Connect IQ never exposes the time of the alarm itself, only whether
    // any alarm is set at all (alarmCount), which is what gates the bell.
    private function wakeTimeText() as String? {
        var secs = _wakeNow;
        if (secs == null) {
            return null;
        }
        var h = secs / 3600;
        var m = (secs % 3600) / 60;
        if (!_is24h) {
            h = h % 12;
            if (h == 0) { h = 12; }
            return h.format("%d") + ":" + m.format("%02d");
        }
        return h.format("%02d") + ":" + m.format("%02d");
    }

    private function iconMoon(dc as Dc, x as Numeric, y as Numeric, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 10 * _s);
        dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x + 5 * _s, y - 4 * _s, 9 * _s);
    }

    function onEnterSleep() as Void {
        _sleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _sleeping = false;
        WatchUi.requestUpdate();
    }
}
