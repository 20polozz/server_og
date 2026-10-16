// Skin: Ushero Nightclub — luxury red & gold panel (matches the baked elevator
// display texture so standby -> live is seamless)
(function () {
  window.SKINS = window.SKINS || {};

  var css = [
    'body.skin-ushero_nightclub { background: #0d0506; }',
    '#uh { position: relative; width: 100%; height: 100%; padding: 22px 24px 20px 24px;',
    '  display: flex; flex-direction: column; font-family: "Segoe UI", system-ui, sans-serif;',
    '  color: #e8dcc4; overflow: hidden;',
    '  background: radial-gradient(circle at 22% 12%, rgba(150,40,45,0.20), transparent 45%),',
    '    radial-gradient(circle at 82% 62%, rgba(110,25,30,0.18), transparent 48%),',
    '    linear-gradient(180deg, #2a0e11 0%, #140608 50%, #1d0a0c 100%); }',
    // faint gold dust
    '#uh::before { content: ""; position: absolute; inset: 0; pointer-events: none;',
    '  background-image: radial-gradient(circle 1.3px, rgba(212,175,55,0.16) 50%, transparent 55%),',
    '    radial-gradient(circle 2.4px, rgba(180,140,45,0.07) 50%, transparent 55%);',
    '  background-size: 41px 41px, 97px 97px; background-position: 0 0, 20px 26px; }',
    '#uh > * { position: relative; }',

    // status bar
    '.uh-status { display: flex; justify-content: space-between; font-size: 12px;',
    '  color: rgba(232,220,196,0.65); letter-spacing: 0.5px; margin-bottom: 16px; }',

    // hairline separators carry the spacing between sections
    '.uh-sep { height: 1px; margin: 18px 0; flex-shrink: 0;',
    '  background: linear-gradient(90deg, transparent, rgba(212,175,55,0.35), transparent); }',

    // small section labels
    '.uh-lbl { font-size: 10px; letter-spacing: 3px; text-transform: uppercase;',
    '  color: rgba(232,220,196,0.45); }',
    '.uh-lbl-wide { text-align: center; margin-bottom: 12px; }',

    // hero row: clock | current floor | arrow
    '.uh-hero { display: flex; align-items: center; justify-content: space-between; gap: 12px;',
    '  margin-bottom: 20px; }',
    '.uh-cur { flex: 1; min-width: 0; text-align: center; }',
    '.uh-cur .uh-lbl { margin-bottom: 6px; }',
    '.uh-clock { width: 58px; height: 58px; border-radius: 50%; position: relative; flex-shrink: 0;',
    '  border: 2px solid rgba(212,175,55,0.6); box-shadow: 0 0 12px rgba(212,175,55,0.28),',
    '  inset 0 0 12px rgba(120,20,25,0.5); background: rgba(20,7,9,0.6); }',
    // 12 hour ticks, long ones at 12/3/6/9
    '.uh-tick { position: absolute; left: 50%; top: 0; width: 2px; height: 100%; margin-left: -1px;',
    '  transform-origin: center center; }',
    '.uh-tick::before { content: ""; position: absolute; top: 4px; left: 0; width: 2px; height: 4px;',
    '  background: rgba(212,175,55,0.55); border-radius: 1px; }',
    '.uh-tick.major::before { height: 7px; background: rgba(242,201,76,0.95); }',
    '.uh-hand { position: absolute; left: 50%; bottom: 50%; transform-origin: bottom center;',
    '  background: #f2c94c; border-radius: 2px; box-shadow: 0 0 5px rgba(242,201,76,0.8); }',
    '.uh-hand.h { width: 3px; height: 13px; margin-left: -1.5px; }',
    '.uh-hand.m { width: 2px; height: 19px; margin-left: -1px; }',
    '.uh-clock::after { content: ""; position: absolute; left: 50%; top: 50%; width: 5px; height: 5px;',
    '  margin: -2.5px 0 0 -2.5px; border-radius: 50%; background: #f2c94c; }',

    '.uh-bigfloor { font-weight: 700; line-height: 1.05; color: #f2c94c; text-align: center;',
    '  flex: 1; min-width: 0; overflow-wrap: break-word;',
    '  text-shadow: 0 0 22px rgba(242,201,76,0.5), 0 0 60px rgba(200,150,40,0.25); }',
    '#uh[data-cur="lg"] .uh-bigfloor { font-size: 104px; }',
    '#uh[data-cur="md"] .uh-bigfloor { font-size: 52px; }',
    '#uh[data-cur="sm"] .uh-bigfloor { font-size: 34px; }',
    '#uh[data-cur="xs"] .uh-bigfloor { font-size: 25px; }',
    '#uh.st-arrived .uh-bigfloor { animation: uh-ding 0.7s ease; }',
    '@keyframes uh-ding { 35% { text-shadow: 0 0 46px rgba(255,225,140,0.95), 0 0 90px rgba(220,170,50,0.5); } }',

    '.uh-arrow { width: 58px; flex-shrink: 0; text-align: center; font-size: 50px; line-height: 1; color: rgba(242,201,76,0.20); }',
    '.uh-arrow.on { color: #f2c94c; text-shadow: 0 0 20px rgba(242,201,76,0.75);',
    '  animation: uh-blink 0.65s steps(1, end) infinite; }',
    '@keyframes uh-blink { 50% { opacity: 0.3; } }',

    // weather strip
    '.uh-weather { display: flex; gap: 6px; }',
    '.uh-wcell { flex: 1; min-width: 0; padding: 6px 2px; text-align: center; border-radius: 5px;',
    '  background: rgba(150,40,45,0.10); border: 1px solid rgba(212,175,55,0.18); }',
    '.uh-wcell .d { font-size: 8px; letter-spacing: 1px; color: rgba(232,220,196,0.5); text-transform: uppercase;',
    '  white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }',
    '.uh-wcell .i { font-size: 15px; line-height: 1.25; color: rgba(242,201,76,0.85); }',
    '.uh-wcell .t { font-size: 10px; color: rgba(232,220,196,0.8); }',

    // brand
    '.uh-brand { text-align: center; }',
    '.uh-brand .m { font-size: 40px; font-weight: 700; letter-spacing: 5px; color: #f2c94c;',
    '  text-shadow: 0 0 18px rgba(242,201,76,0.45); white-space: nowrap; overflow: hidden;',
    '  text-overflow: ellipsis; }',
    '#uh[data-brand="long"] .uh-brand .m { font-size: 27px; letter-spacing: 2px; }',
    '.uh-brand .s { font-size: 13px; letter-spacing: 8px; color: rgba(232,220,196,0.72); margin-top: -2px;',
    '  white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }',
    '#uh[data-brand="long"] .uh-brand .s { font-size: 11px; letter-spacing: 4px; }',

    // floor grid - uniform buttons; columns and type scale follow the longest
    // label, set on #uh as data-cols/data-size by update()
    // flex:1 + equal rows means the buttons share the leftover height instead of
    // leaving a dead gap above the door row
    // Rows keep a fixed height and the list scrolls once there are more floors
    // than fit, instead of spilling over the controls below it.
    '.uh-grid { display: grid; gap: 10px; margin-bottom: 18px;',
    '  grid-auto-rows: minmax(52px, auto); align-items: stretch;',
    '  flex: 1; min-height: 0; overflow-y: auto; padding-right: 5px; }',
    '.uh-grid::-webkit-scrollbar { width: 4px; }',
    '.uh-grid::-webkit-scrollbar-track { background: rgba(232,220,196,0.06); border-radius: 2px; }',
    '.uh-grid::-webkit-scrollbar-thumb { background: rgba(242,201,76,0.5); border-radius: 2px; }',
    '#uh[data-cols="4"] .uh-grid { grid-template-columns: repeat(4, 1fr); }',
    '#uh[data-cols="3"] .uh-grid { grid-template-columns: repeat(3, 1fr); }',
    '#uh[data-cols="2"] .uh-grid { grid-template-columns: repeat(2, 1fr); }',
    '#uh[data-cols="1"] .uh-grid { grid-template-columns: 1fr; }',
    '.uh-btn { position: relative; padding: 13px 8px 11px 8px; text-align: center; border-radius: 6px;',
    '  border: 1.5px solid rgba(212,175,55,0.45); background: rgba(150,40,45,0.10); cursor: pointer;',
    '  box-shadow: inset 0 0 12px rgba(120,25,30,0.25), 0 0 8px rgba(180,140,45,0.10);',
    '  min-width: 0; min-height: 0; overflow: hidden;',
    '  display: flex; flex-direction: column; align-items: center; justify-content: center; }',
    '.uh-btn .n { display: block; font-weight: 600; color: #f0e3c8; line-height: 1.15;',
    '  text-shadow: 0 0 10px rgba(212,175,55,0.4); overflow-wrap: break-word; hyphens: auto; }',
    '#uh[data-size="lg"] .uh-btn .n { font-size: 25px; }',
    '#uh[data-size="md"] .uh-btn .n { font-size: 19px; }',
    '#uh[data-size="sm"] .uh-btn .n { font-size: 15px; }',
    '#uh[data-size="xs"] .uh-btn .n { font-size: 13px; letter-spacing: -0.2px; }',
    '.uh-btn .d { display: block; font-size: 8px; letter-spacing: 0.8px; text-transform: uppercase;',
    '  color: rgba(232,220,196,0.55); margin-top: 2px; overflow-wrap: break-word; }',
    '.uh-btn:hover { border-color: rgba(242,201,76,0.95); background: rgba(180,60,55,0.20);',
    '  box-shadow: inset 0 0 16px rgba(150,40,45,0.35), 0 0 16px rgba(242,201,76,0.35); }',
    '.uh-btn:active { background: rgba(200,80,65,0.28); }',
    '.uh-btn.active { border-color: #f2c94c; background: rgba(242,201,76,0.12);',
    '  box-shadow: inset 0 0 16px rgba(242,201,76,0.20), 0 0 18px rgba(242,201,76,0.45); }',
    '.uh-btn.active .n { color: #f7d96f; text-shadow: 0 0 14px rgba(242,201,76,0.8); }',
    '.uh-btn.active .d { color: rgba(247,217,111,0.75); }',

    // cancel
    '.uh-cancel { text-align: center; margin-bottom: 14px; cursor: pointer; }',
    '.uh-cancel .x { display: inline-flex; align-items: center; justify-content: center;',
    '  width: 30px; height: 30px; border-radius: 50%; font-size: 15px; color: #f2c94c;',
    '  border: 1.5px solid rgba(242,201,76,0.5); box-shadow: 0 0 10px rgba(242,201,76,0.25); }',
    '.uh-cancel:hover .x { border-color: #f2c94c; box-shadow: 0 0 16px rgba(242,201,76,0.55); }',
    '.uh-cancel .l { font-size: 9px; letter-spacing: 2px; text-transform: uppercase;',
    '  color: rgba(232,220,196,0.55); margin-top: 3px; }',

    // door row - indicators, not controls: no hover, no pointer
    '.uh-doors { display: flex; gap: 10px; }',
    '.uh-door { flex: 1; min-width: 0; padding: 12px 0 9px 0; text-align: center; border-radius: 6px;',
    '  border: 1.5px solid rgba(212,175,55,0.22); background: rgba(150,40,45,0.05); }',
    '.uh-door .g { display: block; font-size: 17px; color: rgba(242,201,76,0.55); letter-spacing: 2px;',
    '  text-shadow: 0 0 10px rgba(212,175,55,0.45); }',
    '.uh-door .l { display: block; font-size: 9px; letter-spacing: 2px; text-transform: uppercase;',
    '  color: rgba(232,220,196,0.35); margin-top: 2px; padding: 0 4px; overflow-wrap: break-word; }',

    // status line - one line; a long destination name is cut with an ellipsis
    '.uh-line { text-align: center; font-size: 10px; letter-spacing: 2.5px; text-transform: uppercase;',
    '  color: rgba(232,220,196,0.5); margin-top: 14px; height: 12px;',
    '  white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }',
  ].join('\n');

  var DAYS = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  var ICONS = ['☀', '⛅', '☁', '☂'];

  // In-game weather type -> glyph
  var WEATHER_ICON = {
    EXTRASUNNY: '☀', CLEAR: '☀', NEUTRAL: '⛅', CLOUDS: '⛅', CLEARING: '⛅',
    OVERCAST: '☁', SMOG: '☁', FOGGY: '☁', HALLOWEEN: '☁',
    RAIN: '☂', THUNDER: '☂', RAIN_HALLOWEEN: '☂',
    SNOW: '❄', BLIZZARD: '❄', SNOWLIGHT: '❄', XMAS: '❄', SNOW_HALLOWEEN: '❄'
  };

  var lastActive = null; // last floor we auto-scrolled to

  // Panel metrics used to size the floor grid (512px design width, 24px padding
  // each side), and a rough average glyph width relative to the font size.
  var CONTENT_W = 464, GRID_GAP = 10, BTN_PADDING = 16, CHAR_W = 0.58;
  // Width left for the current floor: hero row minus clock, arrow and gaps
  var CUR_W = CONTENT_W - 58 - 58 - 2 * 12;
  var TIERS = ['lg', 'md', 'sm', 'xs'];
  var BTN_PX = [25, 19, 15, 13];
  var CUR_PX = [104, 52, 34, 25];

  // Texts come from locales/*.lua (display-* keys); English stands in for any
  // key the payload doesn't carry.
  function txt(S, key, fallback) {
    var v = S.strings && S.strings['display-' + key];
    return typeof v === 'string' ? v : fallback;
  }

  function list(S, key, fallback) {
    var v = S.strings && S.strings['display-' + key];
    return (Array.isArray(v) && v.length === fallback.length) ? v : fallback;
  }

  function fill(tpl, value) {
    if (tpl.indexOf('%s') < 0) return tpl + ' ' + value;
    return tpl.replace('%s', function () { return value; });
  }

  function upper(S, s) {
    s = String(s);
    try { return s.toLocaleUpperCase(S.lang || 'en'); } catch (e) { return s.toUpperCase(); }
  }

  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  // Real width of the widest text at a size, so a translated name that runs
  // wider than the per-character estimate steps down instead of overflowing
  var measureCtx = null;
  function widest(texts, px, weight) {
    if (!measureCtx) measureCtx = document.createElement('canvas').getContext('2d');
    if (!measureCtx) return 0;
    measureCtx.font = weight + ' ' + px + 'px "Segoe UI", system-ui, sans-serif';
    var w = 0;
    for (var i = 0; i < texts.length; i++) {
      w = Math.max(w, measureCtx.measureText(String(texts[i] || '')).width);
    }
    return w;
  }

  function pad(n) { return (n < 10 ? '0' : '') + n; }

  function timeStr(S) {
    var env = S.env || {};
    var h = env.hours || 0, m = pad(env.minutes || 0);
    if (env.clock24h) return pad(h) + ':' + m;
    var ampm = h >= 12 ? txt(S, 'pm', 'PM') : txt(S, 'am', 'AM');
    h = h % 12; if (h === 0) h = 12;
    return pad(h) + ':' + m + ' ' + ampm;
  }

  // Stable per-day pseudo-variation so the outlook differs day to day but
  // doesn't flicker while the panel is on screen.
  function outlook(dayIndex, baseTemp) {
    var n = Math.sin(dayIndex * 12.9898) * 43758.5453;
    n = n - Math.floor(n);
    return {
      temp: Math.round(baseTemp - 4 + n * 9),
      icon: ICONS[Math.floor(n * ICONS.length) % ICONS.length]
    };
  }

  function render(S) {
    var ticks = '';
    for (var t = 0; t < 12; t++) {
      ticks += '<div class="uh-tick' + (t % 3 === 0 ? ' major' : '') +
        '" style="transform: rotate(' + (t * 30) + 'deg)"></div>';
    }

    var cells = '';
    for (var w = 0; w < 5; w++) {
      cells += '<div class="uh-wcell"><div class="d"></div><div class="i"></div><div class="t"></div></div>';
    }

    var grid = '';
    for (var i = 0; i < S.floors.length; i++) {
      grid += '<div class="uh-btn" data-floor="' + (i + 1) + '"><span class="n"></span><span class="d"></span></div>';
    }

    return [
      '<div id="uh">',
      '  <div class="uh-status"><span class="uh-t1"></span><span class="uh-t2"></span></div>',
      '  <div class="uh-brand"><div class="m"></div><div class="s"></div></div>',
      '  <div class="uh-sep"></div>',
      '  <div class="uh-hero">',
      '    <div class="uh-clock">' + ticks + '<div class="uh-hand h"></div><div class="uh-hand m"></div></div>',
      '    <div class="uh-cur">',
      '      <div class="uh-lbl">' + esc(txt(S, 'current-floor', 'Current Floor')) + '</div>',
      '      <div class="uh-bigfloor">--</div>',
      '    </div>',
      '    <div class="uh-arrow">▼</div>',
      '  </div>',
      '  <div class="uh-weather">' + cells + '</div>',
      '  <div class="uh-sep"></div>',
      '  <div class="uh-lbl uh-lbl-wide">' + esc(txt(S, 'select-floor', 'Select your floor')) + '</div>',
      '  <div class="uh-grid">' + grid + '</div>',
      '  <div class="uh-cancel" data-action="close"><div class="x">✕</div><div class="l">' + esc(txt(S, 'cancel', 'Cancel')) + '</div></div>',
      '  <div class="uh-doors">',
      '    <div class="uh-door"><span class="g">|◀▶|</span><span class="l">' + esc(txt(S, 'door-open', 'Open')) + '</span></div>',
      '    <div class="uh-door"><span class="g">▶|◀</span><span class="l">' + esc(txt(S, 'door-close', 'Close')) + '</span></div>',
      '  </div>',
      '  <div class="uh-line"></div>',
      '</div>',
    ].join('');
  }

  // Floor names range from "3" to "Vanilla Unicorn Rooftop"; pick a grid and a
  // type size that fit the longest one instead of overflowing the panel.
  function fitToLabels(uh, S) {
    var names = [];
    var longest = 0;
    for (var i = 0; i < S.floors.length; i++) {
      names.push(S.floors[i].name || '');
      longest = Math.max(longest, names[i].length);
    }

    var n = S.floors.length;

    // Densest grid the longest name can carry...
    var cols = longest <= 3 ? 4 : longest <= 6 ? 3 : longest <= 12 ? 2 : 1;
    // ...but a long list gets two columns regardless: smaller type reads better
    // than scrolling past a single tall column of floors.
    if (n >= 7) cols = Math.max(cols, 2);
    // Few floors read better big.
    if (n <= 2) cols = Math.min(cols, n);
    else if (n <= 4) cols = Math.min(cols, 2);

    // Largest type size whose longest label still fits one column. The estimate
    // sets the upper bound; the measured width steps it down when needed.
    var perCol = (CONTENT_W - (cols - 1) * GRID_GAP) / cols - BTN_PADDING;
    var fits = function (px) { return longest * px * CHAR_W <= perCol; };
    var size = fits(25) ? 0 : fits(19) ? 1 : fits(15) ? 2 : 3;
    while (size < 3 && widest(names, BTN_PX[size], 600) > perCol) size++;

    uh.setAttribute('data-cols', String(cols));
    uh.setAttribute('data-size', TIERS[size]);

    // Current floor: multi-word names wrap, but a single long word can't, so
    // the widest word has to fit the hero width
    var cur = S.floors[S.current - 1];
    var curName = cur ? (cur.name || '') : '--';
    var curLen = cur ? curName.length : 2;
    var c = curLen <= 3 ? 0 : curLen <= 8 ? 1 : curLen <= 16 ? 2 : 3;
    var words = curName.split(/\s+/);
    while (c < 3 && widest(words, CUR_PX[c], 700) > CUR_W) c++;
    uh.setAttribute('data-cur', TIERS[c]);
  }

  function update(S) {
    var uh = document.getElementById('uh');
    if (!uh) return;

    uh.className = 'st-' + S.status;
    fitToLabels(uh, S);

    // Everything time- and weather-related comes from the game itself
    var env = S.env || {};
    var baseTemp = typeof env.temp === 'number' ? env.temp : 72;
    var unit = env.unit || '°F';
    var mins = env.minutes || 0, hrs = (env.hours || 0) % 12;

    // Time once, on the left; conditions on the right
    uh.querySelector('.uh-t1').textContent = timeStr(S);
    uh.querySelector('.uh-t2').textContent = baseTemp + unit;

    // analog clock hands
    uh.querySelector('.uh-hand.h').style.transform = 'rotate(' + ((hrs + mins / 60) * 30) + 'deg)';
    uh.querySelector('.uh-hand.m').style.transform = 'rotate(' + (mins * 6) + 'deg)';

    // 5-day strip: today is the live weather, the rest an outlook around it
    var days = list(S, 'days', DAYS);
    var wcells = uh.querySelectorAll('.uh-wcell');
    var date = new Date(env.year || 2013, env.month || 0, env.day || 1);
    var today = date.getDay();
    var dayIndex = (env.year || 0) * 372 + (env.month || 0) * 31 + (env.day || 0);
    for (var w = 0; w < wcells.length; w++) {
      var o = outlook(dayIndex + w, baseTemp);
      var icon = w === 0 ? (WEATHER_ICON[env.weather] || o.icon) : o.icon;
      var temp = w === 0 ? baseTemp : o.temp;
      wcells[w].querySelector('.d').textContent = days[(today + w) % 7];
      wcells[w].querySelector('.i').textContent = icon;
      wcells[w].querySelector('.t').textContent = temp + '°';
    }

    var brand = upper(S, S.display.building || S.theme.title || 'USHERO NIGHTCLUB').split(' ');
    var main = brand[0], sub = brand.slice(1).join(' ');
    uh.setAttribute('data-brand', (main.length > 9 || sub.length > 16) ? 'long' : 'short');
    uh.querySelector('.uh-brand .m').textContent = main;
    uh.querySelector('.uh-brand .s').textContent = sub;

    var cur = S.floors[S.current - 1];
    uh.querySelector('.uh-bigfloor').textContent = cur ? cur.name : '--';

    var arrow = uh.querySelector('.uh-arrow');
    arrow.textContent = S.dir < 0 ? '▼' : '▲';
    arrow.className = 'uh-arrow' + (S.dir !== 0 ? ' on' : '');

    var btns = uh.querySelectorAll('.uh-btn');
    var activeEl = null;
    for (var i = 0; i < btns.length; i++) {
      var idx = Number(btns[i].dataset.floor);
      var fl = S.floors[idx - 1];
      btns[i].querySelector('.n').textContent = fl.name;
      btns[i].querySelector('.d').textContent = fl.desc || '';
      var on = idx === S.current;
      btns[i].classList.toggle('active', on);
      if (on) activeEl = btns[i];
    }

    // Keep the current floor visible in a long, scrolling list - but only when
    // it changes, so it never fights a player scrolling by hand.
    if (activeEl && lastActive !== S.current) {
      lastActive = S.current;
      if (activeEl.scrollIntoView) activeEl.scrollIntoView({ block: 'nearest' });
    }

    var tgt = S.target && S.floors[S.target - 1];
    var line = txt(S, 'select-floor', 'Select your floor');
    if (S.status === 'transit') line = fill(txt(S, 'travelling-to', 'Traveling to %s'), tgt ? tgt.name : '');
    else if (S.status === 'arrived') line = txt(S, 'doors-opening', 'Doors opening');
    uh.querySelector('.uh-line').textContent = line;
  }

  window.SKINS.ushero_nightclub = { css: css, render: render, update: update, tick: true };
})();
