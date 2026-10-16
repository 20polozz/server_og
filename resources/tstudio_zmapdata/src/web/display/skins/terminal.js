// Skin: phosphor CRT terminal (vertical)
(function () {
  window.SKINS = window.SKINS || {};

  var css = [
    ':root { --ph: rgb(122,252,154); --ph-dim: rgba(122,252,154,0.35); --ph-faint: rgba(122,252,154,0.12); }',
    'body.skin-terminal { background: #050807; }',
    '#term { position: relative; width: 100%; height: 100%; padding: 34px; display: flex; flex-direction: column;',
    '  font-family: Consolas, "Courier New", monospace; color: var(--ph); text-shadow: 0 0 8px var(--ph-dim);',
    '  border: 2px solid var(--ph-dim); outline: 1px solid var(--ph-faint); outline-offset: -8px; }',
    '#term::after { content: ""; position: absolute; inset: 0; pointer-events: none;',
    '  background: repeating-linear-gradient(to bottom, rgba(0,0,0,0) 0px, rgba(0,0,0,0) 3px, rgba(0,0,0,0.22) 4px); }',
    '.t-head { text-align: center; font-size: 24px; letter-spacing: 2px; text-transform: uppercase; }',
    '.t-sys { font-size: 13px; color: var(--ph-dim); letter-spacing: 1px; margin-top: 6px; }',
    '.t-rule { border-bottom: 1px dashed var(--ph-dim); margin: 16px 0; }',
    '.t-label { font-size: 13px; letter-spacing: 3px; text-transform: uppercase; color: var(--ph-dim); margin-bottom: 8px; text-align: center; }',
    '.t-floorline { display: flex; align-items: center; justify-content: center; gap: 22px; margin-bottom: 14px; }',
    '.t-num { font-size: 110px; font-weight: 700; line-height: 1; letter-spacing: 4px; white-space: nowrap; }',
    '#term.st-arrived .t-num { animation: t-ding 0.6s steps(2, end); }',
    '@keyframes t-ding { 50% { text-shadow: 0 0 26px var(--ph), 0 0 60px var(--ph-dim); } }',
    '.t-arrow { font-size: 48px; width: 48px; flex-shrink: 0; color: var(--ph-faint); }',
    '.t-arrow.on { color: var(--ph); animation: t-blink 0.6s steps(1, end) infinite; }',
    '@keyframes t-blink { 50% { opacity: 0.25; } }',
    '.t-floors { flex: 1; display: flex; flex-direction: column-reverse; justify-content: center; gap: 10px; min-height: 0; }',
    '.t-floor { padding: 11px 20px; border: 1px solid var(--ph-dim); font-size: 26px; letter-spacing: 2px;',
    '  cursor: pointer; white-space: nowrap; text-align: center; }',
    '.t-floor::before { content: "["; color: var(--ph-dim); margin-right: 6px; }',
    '.t-floor::after { content: "]"; color: var(--ph-dim); margin-left: 6px; }',
    '.t-floor:hover { border-color: var(--ph); background: var(--ph-faint); }',
    '.t-floor:active { background: var(--ph-dim); }',
    '.t-floor.active { background: var(--ph); color: #041207; text-shadow: none; border-color: var(--ph); }',
    '.t-floor.active::before, .t-floor.active::after { color: #041207; }',
    '.t-prompt { margin-top: 16px; font-size: 17px; letter-spacing: 2px; text-transform: uppercase; white-space: pre; text-align: center; }',
    '.t-cursor { animation: t-blink2 1s steps(1, end) infinite; }',
    '@keyframes t-blink2 { 50% { opacity: 0; } }',
  ].join('\n');

  var FONT = 'Consolas, "Courier New", monospace';
  // Inner width of #term: 512 design px minus 34px padding and 2px border each side
  var INNER_W = 440;

  // Texts come from locales/*.lua (display-* keys); English stands in for any
  // key the payload doesn't carry.
  function txt(S, key, fallback) {
    var v = S.strings && S.strings['display-' + key];
    return typeof v === 'string' ? v : fallback;
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

  function lighten(c) {
    var r = Math.round(c.r + (255 - c.r) * 0.55);
    var g = Math.round(c.g + (255 - c.g) * 0.55);
    var b = Math.round(c.b + (255 - c.b) * 0.55);
    return r + ',' + g + ',' + b;
  }

  function render(S) {
    var floors = S.floors.map(function (f, i) {
      return '<div class="t-floor" data-floor="' + (i + 1) + '"></div>';
    }).join('');

    var sys = upper(S, txt(S, 'elevator', 'Elevator')) + ' OS v1.0 · ' + upper(S, txt(S, 'online', 'Online'));

    return [
      '<div id="term">',
      '  <div class="t-head"><div class="t-title"></div><div class="t-sys">' + esc(sys) + '</div></div>',
      '  <div class="t-rule"></div>',
      '  <div class="t-label">' + esc(txt(S, 'current-floor', 'Current Floor')) + '</div>',
      '  <div class="t-floorline"><div class="t-num">--</div><div class="t-arrow">▲</div></div>',
      '  <div class="t-rule"></div>',
      '  <div class="t-label">' + esc(txt(S, 'select-destination', 'Select Destination')) + '</div>',
      '  <div class="t-floors">' + floors + '</div>',
      '  <div class="t-prompt">&gt; <span class="t-ptext"></span><span class="t-cursor">_</span></div>',
      '</div>',
    ].join('');
  }

  function update(S) {
    var term = document.getElementById('term');
    if (!term) return;

    if (S.theme.topColor) {
      var rgb = lighten(S.theme.topColor);
      var root = document.documentElement;
      root.style.setProperty('--ph', 'rgb(' + rgb + ')');
      root.style.setProperty('--ph-dim', 'rgba(' + rgb + ',0.35)');
      root.style.setProperty('--ph-faint', 'rgba(' + rgb + ',0.12)');
    }

    term.className = 'st-' + S.status;
    term.querySelector('.t-title').textContent = upper(S, S.theme.title || 'TSTUDIO');

    var cur = S.floors[S.current - 1];
    var num = term.querySelector('.t-num');
    num.textContent = cur ? cur.name : '--';
    // Row minus the 48px arrow and the 22px gap
    fitSize(num, num.textContent, 110, 24, INNER_W - 48 - 22, 700, 4);

    var arrow = term.querySelector('.t-arrow');
    arrow.textContent = S.dir < 0 ? '▼' : '▲';
    arrow.className = 't-arrow' + (S.dir !== 0 ? ' on' : '');

    var nodes = term.querySelectorAll('.t-floor');
    for (var i = 0; i < nodes.length; i++) {
      var idx = Number(nodes[i].dataset.floor);
      var name = S.floors[idx - 1].name;
      nodes[i].textContent = name;
      nodes[i].classList.toggle('active', idx === S.current);
      // Button minus padding, border and the two bracket margins; the brackets
      // are measured along with the name
      fitSize(nodes[i], '[' + name + ']', 26, 12, INNER_W - 40 - 2 - 12, 400, 2);
    }

    var tgt = S.target && S.floors[S.target - 1];
    var text = upper(S, txt(S, 'ready', 'Ready'));
    if (S.status === 'transit') {
      text = upper(S, txt(S, 'in-transit', 'In Transit')) + ' ' + (S.dir > 0 ? '▲ ' : '▼ ') + (tgt ? tgt.name : '');
    } else if (S.status === 'arrived') {
      text = upper(S, txt(S, 'arrived', 'Arrived')) + ' · ' + (cur ? cur.name : '');
    }
    var prompt = term.querySelector('.t-prompt');
    term.querySelector('.t-ptext').textContent = text;
    fitSize(prompt, upper(S, '> ' + text + '_'), 17, 10, INNER_W, 400, 2);
  }

  window.SKINS.terminal = { css: css, render: render, update: update };
})();
