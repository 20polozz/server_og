// Skin: modern smart panel (Ocean Vista reference) — grid, status cards, clock
(function () {
  window.SKINS = window.SKINS || {};

  var css = [
    'body.skin-smartpanel { background: #14120f; }',
    '#sp { width: 100%; height: 100%; padding: 30px 26px 22px 26px; display: flex; flex-direction: column;',
    '  font-family: "Segoe UI", system-ui, sans-serif; color: #e9e2d6;',
    '  background: linear-gradient(175deg, #1c1916 0%, #14120f 45%, #191613 100%); }',
    '.sp-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; }',
    '.sp-name { font-size: 30px; font-weight: 650; letter-spacing: 0.5px; }',
    '.sp-sub { font-size: 11px; letter-spacing: 3px; color: rgba(233,226,214,0.4); text-transform: uppercase; margin-top: 2px; }',
    '.sp-clock { text-align: right; }',
    '.sp-time { font-size: 26px; font-weight: 600; }',
    '.sp-date { font-size: 11px; letter-spacing: 1.5px; color: rgba(233,226,214,0.4); text-transform: uppercase; }',
    '.sp-label { font-size: 11px; letter-spacing: 2.5px; color: rgba(233,226,214,0.45); text-transform: uppercase; margin-bottom: 8px; }',
    '.sp-current { text-align: center; margin-bottom: 14px; }',
    '.sp-flrow { display: flex; align-items: center; justify-content: center; gap: 16px; }',
    '.sp-floornum { font-size: 96px; font-weight: 700; line-height: 1; white-space: nowrap; }',
    '#sp.st-arrived .sp-floornum { animation: sp-ding 0.7s ease; }',
    '@keyframes sp-ding { 30% { text-shadow: 0 0 34px rgba(var(--c1, 200,170,110), 0.9); } }',
    '.sp-chev { display: flex; flex-direction: column; gap: 2px; font-size: 17px; color: rgba(233,226,214,0.18); flex-shrink: 0; }',
    '.sp-chev div.on { color: rgb(var(--c1, 200,170,110)); animation: sp-blink 0.6s steps(1,end) infinite; }',
    '@keyframes sp-blink { 50% { opacity: 0.3; } }',
    '.sp-grid { display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 9px; margin-bottom: 10px; }',
    '.sp-btn { padding: 15px 0; text-align: center; font-size: 21px; font-weight: 600; border-radius: 9px;',
    '  border: 1px solid rgba(233,226,214,0.10); background: rgba(255,255,255,0.03); cursor: pointer;',
    '  white-space: nowrap; overflow: hidden; }',
    '.sp-btn:hover { background: rgba(255,255,255,0.08); border-color: rgba(233,226,214,0.3); }',
    '.sp-btn:active { background: rgba(255,255,255,0.14); }',
    '.sp-btn.active { border-color: rgb(var(--c1, 200,170,110)); box-shadow: 0 0 0 1px rgb(var(--c1, 200,170,110)) inset; }',
    '.sp-primary { padding: 15px 8px; text-align: center; font-size: 15px; font-weight: 650; letter-spacing: 2.5px;',
    '  text-transform: uppercase; border-radius: 9px; border: 1px solid rgba(233,226,214,0.12);',
    '  background: rgba(255,255,255,0.04); cursor: pointer; margin-bottom: 14px; white-space: nowrap; overflow: hidden; }',
    '.sp-primary:hover { background: rgba(255,255,255,0.09); border-color: rgba(233,226,214,0.3); }',
    '.sp-primary.active { border-color: rgb(var(--c1, 200,170,110)); box-shadow: 0 0 0 1px rgb(var(--c1, 200,170,110)) inset; }',
    '.sp-cards { display: flex; gap: 10px; margin-bottom: 12px; flex: 1; min-height: 0; }',
    '.sp-card { flex: 1; min-width: 0; border-radius: 11px; border: 1px solid rgba(233,226,214,0.09); background: rgba(255,255,255,0.025);',
    '  padding: 14px 16px; display: flex; flex-direction: column; justify-content: center; gap: 9px; overflow-wrap: break-word; }',
    '.sp-kv .k { font-size: 10px; letter-spacing: 2px; color: rgba(233,226,214,0.4); text-transform: uppercase; }',
    '.sp-kv .v { font-size: 16px; font-weight: 600; margin-top: 1px; }',
    '.sp-status-v { font-size: 19px; font-weight: 650; }',
    '.sp-actions { display: flex; gap: 10px; margin-bottom: 12px; }',
    '.sp-act { flex: 1; min-width: 0; padding: 13px 0 10px 0; text-align: center; border-radius: 10px;',
    '  border: 1px solid rgba(233,226,214,0.09); background: rgba(255,255,255,0.025); cursor: pointer; }',
    '.sp-act:hover { background: rgba(255,255,255,0.07); }',
    '.sp-act:active { background: rgba(255,255,255,0.13); }',
    '.sp-act .g { font-size: 18px; display: block; margin-bottom: 3px; }',
    '.sp-act .t { font-size: 8.5px; letter-spacing: 1.5px; color: rgba(233,226,214,0.45); text-transform: uppercase;',
    '  display: block; padding: 0 4px; overflow-wrap: break-word; }',
    '.sp-footer { padding: 12px 8px; text-align: center; font-size: 12px; letter-spacing: 2px; text-transform: uppercase;',
    '  color: rgba(233,226,214,0.5); border-radius: 9px; background: rgba(0,0,0,0.3); border: 1px solid rgba(233,226,214,0.07);',
    '  overflow-wrap: break-word; }',
  ].join('\n');

  var FONT = '"Segoe UI", system-ui, sans-serif';
  // 512 design px minus 26px padding each side
  var CONTENT_W = 460;

  var DAYS = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  var MONTHS = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

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

  var measureCtx = null;
  function textWidth(text, font) {
    if (!measureCtx) measureCtx = document.createElement('canvas').getContext('2d');
    if (!measureCtx) return 0;
    measureCtx.font = font;
    return measureCtx.measureText(text).width;
  }

  // Shrinks a nowrap line until it fits `avail` px (translated names run longer);
  // the stylesheet size applies whenever the text already fits.
  function fitSize(el, text, base, min, avail, weight, spacing) {
    text = String(text);
    var w = textWidth(text, weight + ' 100px ' + FONT);
    var px = w > 0 ? Math.floor((avail - spacing * text.length) * 100 / w) : base;
    px = Math.max(min, Math.min(base, px));
    el.style.fontSize = px < base ? px + 'px' : '';
  }

  function pad(n) { return (n < 10 ? '0' : '') + n; }

  // Reads the game's clock (supplied by the client script), not the browser's
  function clock(S) {
    var env = S.env || {};
    var d = new Date(env.year || 2013, env.month || 0, env.day || 1);
    var h = env.hours || 0, m = pad(env.minutes || 0);
    var days = list(S, 'days', DAYS), mons = list(S, 'months', MONTHS);
    var time;
    if (env.clock24h) {
      time = pad(h) + ':' + m;
    } else {
      var ampm = h >= 12 ? txt(S, 'pm', 'PM') : txt(S, 'am', 'AM');
      h = h % 12; if (h === 0) h = 12;
      time = pad(h) + ':' + m + ' ' + ampm;
    }
    return {
      time: time,
      date: days[d.getDay()] + ', ' + mons[d.getMonth()] + ' ' + d.getDate(),
    };
  }

  function render(S) {
    // Grid shows non-primary floors, highest first; primary floor gets the wide bar
    var grid = '';
    var primary = '';
    for (var i = S.floors.length - 1; i >= 0; i--) {
      if (S.floors[i].primary) {
        // Every primary floor gets its own wide bar (stacked, highest first)
        primary += '<div class="sp-primary" data-floor="' + (i + 1) + '"></div>';
      } else {
        grid += '<div class="sp-btn" data-floor="' + (i + 1) + '"></div>';
      }
    }

    var act = function (glyph, key, fallback) {
      return '    <div class="sp-act"><span class="g">' + glyph + '</span><span class="t">' +
        esc(txt(S, key, fallback)) + '</span></div>';
    };

    return [
      '<div id="sp">',
      '  <div class="sp-top">',
      '    <div><div class="sp-name"></div><div class="sp-sub">' + esc(txt(S, 'elevator', 'Elevator')) + '</div></div>',
      '    <div class="sp-clock"><div class="sp-time"></div><div class="sp-date"></div></div>',
      '  </div>',
      '  <div class="sp-current"><div class="sp-label">' + esc(txt(S, 'current-floor', 'Current Floor')) + '</div>',
      '    <div class="sp-flrow"><div class="sp-floornum">--</div>',
      '      <div class="sp-chev"><div class="c-up">▲</div><div class="c-down">▼</div></div></div></div>',
      '  <div class="sp-label">' + esc(txt(S, 'select-destination', 'Select Destination')) + '</div>',
      '  <div class="sp-grid">' + grid + '</div>',
      primary,
      '  <div class="sp-cards">',
      '    <div class="sp-card">',
      '      <div class="sp-kv"><div class="k">' + esc(txt(S, 'max-capacity', 'Max Capacity')) + '</div><div class="v sp-cap"></div></div>',
      '      <div class="sp-kv"><div class="k">' + esc(txt(S, 'load', 'Load')) + '</div><div class="v sp-load"></div></div>',
      '    </div>',
      '    <div class="sp-card"><div class="sp-kv"><div class="k">' + esc(txt(S, 'elevator-status', 'Elevator Status')) + '</div></div>',
      '      <div class="sp-status-v"></div></div>',
      '  </div>',
      '  <div class="sp-actions">',
      act('◧◨', 'door-open', 'Open'),
      act('◨◧', 'door-close', 'Close'),
      act('⊘', 'stop', 'Stop'),
      act('✆', 'call-help', 'Help'),
      '  </div>',
      '  <div class="sp-footer"></div>',
      '</div>',
    ].join('');
  }

  function update(S) {
    var sp = document.getElementById('sp');
    if (!sp) return;

    if (S.theme.topColor) {
      var c = S.theme.topColor;
      document.documentElement.style.setProperty('--c1',
        Math.min(c.r + 90, 255) + ',' + Math.min(c.g + 90, 255) + ',' + Math.min(c.b + 90, 255));
    }

    sp.className = 'st-' + S.status;
    sp.querySelector('.sp-name').textContent = S.display.building || S.theme.title || txt(S, 'elevator', 'Elevator');

    var ck = clock(S);
    sp.querySelector('.sp-time').textContent = ck.time;
    sp.querySelector('.sp-date').textContent = ck.date;

    var cur = S.floors[S.current - 1];
    var num = sp.querySelector('.sp-floornum');
    num.textContent = cur ? cur.name : '--';
    // Row minus the chevrons and the 16px gap
    fitSize(num, num.textContent, 96, 24, CONTENT_W - 20 - 16, 700, 0);
    sp.querySelector('.c-up').className = 'c-up' + (S.dir > 0 ? ' on' : '');
    sp.querySelector('.c-down').className = 'c-down' + (S.dir < 0 ? ' on' : '');

    // Six grid columns sharing the width minus five 9px gaps and the borders
    var cellW = (CONTENT_W - 5 * 9) / 6 - 2 - 6;
    var btns = sp.querySelectorAll('[data-floor]');
    for (var i = 0; i < btns.length; i++) {
      var idx = Number(btns[i].dataset.floor);
      var f = S.floors[idx - 1];
      var label = f.primary && f.desc ? f.name + ' · ' + f.desc : f.name;
      btns[i].textContent = label;
      btns[i].classList.toggle('active', idx === S.current);
      if (f.primary) fitSize(btns[i], upper(S, label), 15, 9, CONTENT_W - 2 - 16, 650, 2.5);
      else fitSize(btns[i], label, 21, 9, cellW, 600, 0);
    }

    sp.querySelector('.sp-cap').textContent = S.display.capacity || '—';
    sp.querySelector('.sp-load').textContent = S.display.load || '—';

    var status = txt(S, 'ready', 'Ready');
    if (S.status === 'transit') status = txt(S, 'in-transit', 'In Transit') + ' ' + (S.dir > 0 ? '▲' : '▼');
    else if (S.status === 'arrived') status = txt(S, 'arrived', 'Arrived');
    sp.querySelector('.sp-status-v').textContent = status;

    var tgt = S.target && S.floors[S.target - 1];
    var foot = txt(S, 'select-destination', 'Select Destination');
    if (S.status === 'transit') foot = fill(txt(S, 'travelling-to', 'Traveling to %s'), tgt ? tgt.name : '') + ' …';
    else if (S.status === 'arrived') foot = txt(S, 'doors-opening', 'Doors opening');
    sp.querySelector('.sp-footer').textContent = foot;
  }

  window.SKINS.smartpanel = { css: css, render: render, update: update, tick: true };
})();
