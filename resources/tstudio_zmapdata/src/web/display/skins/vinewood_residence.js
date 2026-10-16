// Skin: Vinewood Residence — white marble, beige and gold, matching the
// building's luxury interior. Set display.logo in the elevator config to show
// an image in place of the wordmark.
(function () {
  window.SKINS = window.SKINS || {};

  var GOLD = '#92742f';

  var css = [
    'body.skin-vinewood_residence { background: #ece4d6; }',
    '#vw { position: relative; width: 100%; height: 100%; padding: 24px 26px 20px 26px;',
    '  display: flex; flex-direction: column; font-family: "Segoe UI", system-ui, sans-serif;',
    '  color: #33302a; overflow: hidden;',
    '  background: linear-gradient(168deg, #fdfaf4 0%, #f2ece0 38%, #e9e0cf 70%, #f4efe4 100%); }',
    // soft marble veining, static so the page never repaints for it
    '#vw::before { content: ""; position: absolute; inset: 0; pointer-events: none; opacity: 0.55;',
    '  background: repeating-linear-gradient(114deg, rgba(255,255,255,0) 0 38px,',
    '    rgba(160,148,126,0.10) 38px 40px, rgba(255,255,255,0) 40px 92px),',
    '    repeating-linear-gradient(74deg, rgba(255,255,255,0) 0 64px,',
    '    rgba(140,126,102,0.07) 64px 66px, rgba(255,255,255,0) 66px 150px); }',
    '#vw > * { position: relative; }',

    // status bar
    '.vw-status { display: flex; justify-content: space-between; font-size: 12px; font-weight: 600;',
    '  color: rgba(46,40,30,0.95); letter-spacing: 0.5px; margin-bottom: 14px; }',

    // brand / logo
    '.vw-brand { text-align: center; overflow-wrap: break-word; }',
    '.vw-brand .m { font-size: 38px; font-weight: 700; letter-spacing: 8px; color: #6f5417; }',
    '#vw[data-brand="long"] .vw-brand .m { font-size: 26px; letter-spacing: 4px; }',
    '.vw-brand .s { font-size: 11px; font-weight: 600; letter-spacing: 7px; color: rgba(52,46,34,0.9);',
    '  margin-top: 2px; text-transform: uppercase; }',
    // multiply drops the white of line-art logos into the marble, so a plain
    // white-background export looks the same as one with transparency
    '.vw-brand img { max-width: 70%; max-height: 110px; object-fit: contain;',
    '  mix-blend-mode: multiply; }',

    '.vw-sep { height: 1px; margin: 16px 0; flex-shrink: 0;',
    '  background: linear-gradient(90deg, transparent, rgba(146,116,47,0.45), transparent); }',

    '.vw-lbl { font-size: 10px; font-weight: 700; letter-spacing: 3px; text-transform: uppercase;',
    '  color: rgba(52,46,34,0.88); }',
    '.vw-lbl-wide { text-align: center; margin-bottom: 12px; }',

    // hero: clock | current floor | arrow
    '.vw-hero { display: flex; align-items: center; justify-content: space-between; gap: 12px;',
    '  margin-bottom: 18px; }',
    '.vw-clock { width: 56px; height: 56px; border-radius: 50%; position: relative; flex-shrink: 0;',
    '  border: 2px solid rgba(146,116,47,0.55); background: rgba(255,255,255,0.6);',
    '  box-shadow: 0 1px 6px rgba(120,100,60,0.16), inset 0 0 10px rgba(255,255,255,0.9); }',
    '.vw-tick { position: absolute; left: 50%; top: 0; width: 2px; height: 100%; margin-left: -1px;',
    '  transform-origin: center center; }',
    '.vw-tick::before { content: ""; position: absolute; top: 4px; left: 0; width: 2px; height: 4px;',
    '  background: rgba(146,116,47,0.4); border-radius: 1px; }',
    '.vw-tick.major::before { height: 7px; background: rgba(146,116,47,0.9); }',
    '.vw-hand { position: absolute; left: 50%; bottom: 50%; transform-origin: bottom center;',
    '  background: #7a5f28; border-radius: 2px; }',
    '.vw-hand.h { width: 3px; height: 13px; margin-left: -1.5px; }',
    '.vw-hand.m { width: 2px; height: 19px; margin-left: -1px; }',
    '.vw-clock::after { content: ""; position: absolute; left: 50%; top: 50%; width: 5px; height: 5px;',
    '  margin: -2.5px 0 0 -2.5px; border-radius: 50%; background: #7a5f28; }',

    '.vw-cur { flex: 1; min-width: 0; text-align: center; }',
    '.vw-cur .vw-lbl { margin-bottom: 6px; }',
    '.vw-bigfloor { font-weight: 700; line-height: 1.05; color: #1c1810; text-align: center;',
    '  overflow-wrap: break-word; letter-spacing: 1px; }',
    '#vw[data-cur="lg"] .vw-bigfloor { font-size: 100px; }',
    '#vw[data-cur="md"] .vw-bigfloor { font-size: 50px; }',
    '#vw[data-cur="sm"] .vw-bigfloor { font-size: 33px; }',
    '#vw[data-cur="xs"] .vw-bigfloor { font-size: 24px; }',
    '#vw.st-arrived .vw-bigfloor { animation: vw-ding 0.7s ease; }',
    '@keyframes vw-ding { 35% { color: #92742f; text-shadow: 0 0 26px rgba(190,150,60,0.55); } }',

    '.vw-arrow { width: 56px; flex-shrink: 0; text-align: center; font-size: 46px; line-height: 1;',
    '  color: rgba(146,116,47,0.22); }',
    '.vw-arrow.on { color: #92742f; animation: vw-blink 0.65s steps(1, end) infinite; }',
    '@keyframes vw-blink { 50% { opacity: 0.3; } }',

    // weather strip
    '.vw-weather { display: flex; gap: 6px; }',
    '.vw-wcell { flex: 1; min-width: 0; padding: 6px 2px; text-align: center; border-radius: 4px;',
    '  background: rgba(255,255,255,0.55); border: 1px solid rgba(146,116,47,0.18); }',
    '.vw-wcell .d { font-size: 8px; font-weight: 700; letter-spacing: 1px;',
    '  color: rgba(52,46,34,0.88); text-transform: uppercase;',
    '  white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }',
    '.vw-wcell .i { font-size: 15px; line-height: 1.25; color: #6f5417; }',
    '.vw-wcell .t { font-size: 10px; font-weight: 700; color: rgba(38,33,24,0.95); }',

    // floor grid - uniform buttons, scrolls when the list is long
    '.vw-grid { display: grid; gap: 10px; margin-bottom: 18px;',
    '  grid-auto-rows: minmax(52px, auto); align-items: stretch;',
    '  flex: 1; min-height: 0; overflow-y: auto; padding-right: 5px; }',
    '.vw-grid::-webkit-scrollbar { width: 4px; }',
    '.vw-grid::-webkit-scrollbar-track { background: rgba(146,116,47,0.10); border-radius: 2px; }',
    '.vw-grid::-webkit-scrollbar-thumb { background: rgba(146,116,47,0.5); border-radius: 2px; }',
    '#vw[data-cols="4"] .vw-grid { grid-template-columns: repeat(4, 1fr); }',
    '#vw[data-cols="3"] .vw-grid { grid-template-columns: repeat(3, 1fr); }',
    '#vw[data-cols="2"] .vw-grid { grid-template-columns: repeat(2, 1fr); }',
    '#vw[data-cols="1"] .vw-grid { grid-template-columns: 1fr; }',

    '.vw-btn { position: relative; padding: 12px 8px; text-align: center; border-radius: 5px;',
    '  border: 1px solid rgba(146,116,47,0.4); background: rgba(255,255,255,0.68); cursor: pointer;',
    '  box-shadow: 0 1px 3px rgba(120,100,60,0.12); min-width: 0; min-height: 0; overflow: hidden;',
    '  display: flex; flex-direction: column; align-items: center; justify-content: center; }',
    '.vw-btn .n { display: block; font-weight: 700; color: #211d15; line-height: 1.15;',
    '  letter-spacing: 0.5px; overflow-wrap: break-word; hyphens: auto; }',
    '#vw[data-size="lg"] .vw-btn .n { font-size: 25px; }',
    '#vw[data-size="md"] .vw-btn .n { font-size: 19px; }',
    '#vw[data-size="sm"] .vw-btn .n { font-size: 15px; }',
    '#vw[data-size="xs"] .vw-btn .n { font-size: 13px; letter-spacing: -0.2px; }',
    '.vw-btn .d { display: block; font-size: 8px; font-weight: 600; letter-spacing: 0.8px;',
    '  text-transform: uppercase; color: rgba(52,46,34,0.9); margin-top: 2px;',
    '  overflow-wrap: break-word; }',
    '.vw-btn:hover { border-color: #92742f; background: #fff;',
    '  box-shadow: 0 2px 10px rgba(146,116,47,0.28); }',
    '.vw-btn:active { background: rgba(240,230,205,0.95); }',
    '.vw-btn.active { border-color: #92742f;',
    '  background: linear-gradient(160deg, #e5c675 0%, #d4af49 55%, #c09c38 100%);',
    '  box-shadow: 0 2px 12px rgba(180,145,55,0.45); }',
    '.vw-btn.active .n { color: #33290f; }',
    '.vw-btn.active .d { color: rgba(51,41,15,0.7); }',

    // cancel
    '.vw-cancel { text-align: center; margin-bottom: 14px; cursor: pointer; }',
    '.vw-cancel .x { display: inline-flex; align-items: center; justify-content: center;',
    '  width: 30px; height: 30px; border-radius: 50%; font-size: 15px; color: #92742f;',
    '  border: 1px solid rgba(146,116,47,0.5); background: rgba(255,255,255,0.6); }',
    '.vw-cancel:hover .x { border-color: #92742f; background: #fff;',
    '  box-shadow: 0 2px 10px rgba(146,116,47,0.3); }',
    '.vw-cancel .l { font-size: 9px; letter-spacing: 2px; text-transform: uppercase;',
    '  color: rgba(52,46,34,0.9); margin-top: 3px; }',

    // door indicators (not controls)
    '.vw-doors { display: flex; gap: 10px; }',
    '.vw-door { flex: 1; min-width: 0; padding: 11px 0 8px 0; text-align: center; border-radius: 5px;',
    '  border: 1px solid rgba(146,116,47,0.22); background: rgba(255,255,255,0.4); }',
    '.vw-door .g { display: block; font-size: 16px; color: rgba(146,116,47,0.6); letter-spacing: 2px; }',
    '.vw-door .l { display: block; font-size: 9px; letter-spacing: 2px; text-transform: uppercase;',
    '  color: rgba(58,52,40,0.8); margin-top: 2px; padding: 0 4px; overflow-wrap: break-word; }',

    // status line - one line; a long destination name is cut with an ellipsis
    '.vw-line { text-align: center; font-size: 10px; font-weight: 700; letter-spacing: 2.5px;',
    '  text-transform: uppercase; color: rgba(52,46,34,0.88); margin-top: 12px; height: 12px;',
    '  white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }',
  ].join('\n');

  var DAYS = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  var ICONS = ['☀', '⛅', '☁', '☂'];
  var WEATHER_ICON = {
    EXTRASUNNY: '☀', CLEAR: '☀', NEUTRAL: '⛅', CLOUDS: '⛅', CLEARING: '⛅',
    OVERCAST: '☁', SMOG: '☁', FOGGY: '☁', HALLOWEEN: '☁',
    RAIN: '☂', THUNDER: '☂', RAIN_HALLOWEEN: '☂',
    SNOW: '❄', BLIZZARD: '❄', SNOWLIGHT: '❄', XMAS: '❄', SNOW_HALLOWEEN: '❄'
  };

  var lastActive = null; // last floor we auto-scrolled to

  // Panel metrics used to size the floor grid (512px design width, 26px padding
  // each side), and a rough average glyph width relative to the font size.
  var CONTENT_W = 460, GRID_GAP = 10, BTN_PADDING = 16, CHAR_W = 0.58;
  // Width left for the current floor: hero row minus clock, arrow and gaps
  var CUR_W = CONTENT_W - 56 - 56 - 2 * 12;
  var TIERS = ['lg', 'md', 'sm', 'xs'];
  var BTN_PX = [25, 19, 15, 13];
  var CUR_PX = [100, 50, 33, 24];

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

  // Real width of the widest text at a size (letter-spacing included), so a
  // translated name wider than the per-character estimate steps down a size
  var measureCtx = null;
  function widest(texts, px, weight, spacing) {
    if (!measureCtx) measureCtx = document.createElement('canvas').getContext('2d');
    if (!measureCtx) return 0;
    measureCtx.font = weight + ' ' + px + 'px "Segoe UI", system-ui, sans-serif';
    var w = 0;
    for (var i = 0; i < texts.length; i++) {
      var s = String(texts[i] || '');
      w = Math.max(w, measureCtx.measureText(s).width + spacing * s.length);
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

  // Stable per-day variation so the outlook differs day to day without
  // flickering while the panel is on screen.
  function outlook(dayIndex, baseTemp) {
    var n = Math.sin(dayIndex * 12.9898) * 43758.5453;
    n = n - Math.floor(n);
    return {
      temp: Math.round(baseTemp - 4 + n * 9),
      icon: ICONS[Math.floor(n * ICONS.length) % ICONS.length]
    };
  }

  function escapeAttr(s) {
    return String(s).replace(/&/g, '&amp;').replace(/"/g, '&quot;')
      .replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function render(S) {
    var ticks = '';
    for (var t = 0; t < 12; t++) {
      ticks += '<div class="vw-tick' + (t % 3 === 0 ? ' major' : '') +
        '" style="transform: rotate(' + (t * 30) + 'deg)"></div>';
    }

    var cells = '';
    for (var w = 0; w < 5; w++) {
      cells += '<div class="vw-wcell"><div class="d"></div><div class="i"></div><div class="t"></div></div>';
    }

    var grid = '';
    for (var i = 0; i < S.floors.length; i++) {
      grid += '<div class="vw-btn" data-floor="' + (i + 1) +
        '"><span class="n"></span><span class="d"></span></div>';
    }

    // An image logo when the map supplies one, otherwise the wordmark. The name
    // stays underneath either way so the panel always says where you are.
    var brand = S.display.logo
      ? '<img src="' + escapeAttr(S.display.logo) + '" alt=""><div class="s"></div>'
      : '<div class="m"></div><div class="s"></div>';

    return [
      '<div id="vw">',
      '  <div class="vw-status"><span class="vw-t1"></span><span class="vw-t2"></span></div>',
      '  <div class="vw-brand">' + brand + '</div>',
      '  <div class="vw-sep"></div>',
      '  <div class="vw-hero">',
      '    <div class="vw-clock">' + ticks + '<div class="vw-hand h"></div><div class="vw-hand m"></div></div>',
      '    <div class="vw-cur">',
      '      <div class="vw-lbl">' + esc(txt(S, 'current-floor', 'Current Floor')) + '</div>',
      '      <div class="vw-bigfloor">--</div>',
      '    </div>',
      '    <div class="vw-arrow">▼</div>',
      '  </div>',
      '  <div class="vw-weather">' + cells + '</div>',
      '  <div class="vw-sep"></div>',
      '  <div class="vw-lbl vw-lbl-wide">' + esc(txt(S, 'select-floor', 'Select your floor')) + '</div>',
      '  <div class="vw-grid">' + grid + '</div>',
      '  <div class="vw-cancel" data-action="close"><div class="x">✕</div><div class="l">' + esc(txt(S, 'cancel', 'Cancel')) + '</div></div>',
      '  <div class="vw-doors">',
      '    <div class="vw-door"><span class="g">|◀▶|</span><span class="l">' + esc(txt(S, 'door-open', 'Open')) + '</span></div>',
      '    <div class="vw-door"><span class="g">▶|◀</span><span class="l">' + esc(txt(S, 'door-close', 'Close')) + '</span></div>',
      '  </div>',
      '  <div class="vw-line"></div>',
      '</div>',
    ].join('');
  }

  // Floor names range from "3" to "Hallway Floor 12": pick the densest grid the
  // longest name can carry, then the largest type size that fits a column.
  function fitToLabels(vw, S) {
    var n = S.floors.length;
    var names = [];
    var longest = 0;
    for (var i = 0; i < n; i++) {
      names.push(S.floors[i].name || '');
      longest = Math.max(longest, names[i].length);
    }

    var cols = longest <= 3 ? 4 : longest <= 6 ? 3 : longest <= 12 ? 2 : 1;
    if (n >= 7) cols = Math.max(cols, 2);
    if (n <= 2) cols = Math.min(cols, n);
    else if (n <= 4) cols = Math.min(cols, 2);

    // The estimate sets the upper bound; the measured width steps it down
    var perCol = (CONTENT_W - (cols - 1) * GRID_GAP) / cols - BTN_PADDING;
    var fits = function (px) { return longest * px * CHAR_W <= perCol; };
    var size = fits(25) ? 0 : fits(19) ? 1 : fits(15) ? 2 : 3;
    while (size < 3 && widest(names, BTN_PX[size], 700, 0.5) > perCol) size++;

    vw.setAttribute('data-cols', String(cols));
    vw.setAttribute('data-size', TIERS[size]);

    // Current floor: multi-word names wrap, but a single long word can't, so
    // the widest word has to fit the hero width
    var cur = S.floors[S.current - 1];
    var curName = cur ? (cur.name || '') : '--';
    var curLen = cur ? curName.length : 2;
    var c = curLen <= 3 ? 0 : curLen <= 8 ? 1 : curLen <= 16 ? 2 : 3;
    var words = curName.split(/\s+/);
    while (c < 3 && widest(words, CUR_PX[c], 700, 1) > CUR_W) c++;
    vw.setAttribute('data-cur', TIERS[c]);
  }

  function update(S) {
    var vw = document.getElementById('vw');
    if (!vw) return;

    vw.className = 'st-' + S.status;
    fitToLabels(vw, S);

    // Everything time- and weather-related comes from the game itself
    var env = S.env || {};
    var baseTemp = typeof env.temp === 'number' ? env.temp : 72;
    var unit = env.unit || '°F';
    var mins = env.minutes || 0, hrs = (env.hours || 0) % 12;

    vw.querySelector('.vw-t1').textContent = timeStr(S);
    vw.querySelector('.vw-t2').textContent = baseTemp + unit;

    vw.querySelector('.vw-hand.h').style.transform = 'rotate(' + ((hrs + mins / 60) * 30) + 'deg)';
    vw.querySelector('.vw-hand.m').style.transform = 'rotate(' + (mins * 6) + 'deg)';

    var days = list(S, 'days', DAYS);
    var wcells = vw.querySelectorAll('.vw-wcell');
    var date = new Date(env.year || 2013, env.month || 0, env.day || 1);
    var today = date.getDay();
    var dayIndex = (env.year || 0) * 372 + (env.month || 0) * 31 + (env.day || 0);
    for (var w = 0; w < wcells.length; w++) {
      var o = outlook(dayIndex + w, baseTemp);
      wcells[w].querySelector('.d').textContent = days[(today + w) % 7];
      wcells[w].querySelector('.i').textContent =
        w === 0 ? (WEATHER_ICON[env.weather] || o.icon) : o.icon;
      wcells[w].querySelector('.t').textContent = (w === 0 ? baseTemp : o.temp) + '°';
    }

    var name = upper(S, S.display.building || S.theme.title || 'VINEWOOD RESIDENCE');
    var mainEl = vw.querySelector('.vw-brand .m');
    var subEl = vw.querySelector('.vw-brand .s');

    if (mainEl) {
      // Wordmark: first word large, the rest spaced out beneath it
      var parts = name.split(' ');
      var main = parts[0], sub = parts.slice(1).join(' ');
      vw.setAttribute('data-brand', (main.length > 10 || sub.length > 18) ? 'long' : 'short');
      mainEl.textContent = main;
      if (subEl) subEl.textContent = sub;
    } else if (subEl) {
      // Logo image: the whole name goes on the line under it
      subEl.textContent = name;
    }

    var cur = S.floors[S.current - 1];
    vw.querySelector('.vw-bigfloor').textContent = cur ? cur.name : '--';

    var arrow = vw.querySelector('.vw-arrow');
    arrow.textContent = S.dir < 0 ? '▼' : '▲';
    arrow.className = 'vw-arrow' + (S.dir !== 0 ? ' on' : '');

    var btns = vw.querySelectorAll('.vw-btn');
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
    vw.querySelector('.vw-line').textContent = line;
  }

  window.SKINS.vinewood_residence = { css: css, render: render, update: update, tick: true };
})();
