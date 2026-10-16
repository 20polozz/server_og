// Skin: heritage brass panel (Disney hotel reference) — plates + lit buttons
(function () {
  window.SKINS = window.SKINS || {};

  var css = [
    'body.skin-heritage { background: #17090a; }',
    '#hg { width: 100%; height: 100%; padding: 36px 30px 26px 30px; display: flex; flex-direction: column;',
    '  font-family: Georgia, "Times New Roman", serif; color: #e8cf9a;',
    '  background: linear-gradient(165deg, #241012 0%, #17090a 40%, #1d0e10 75%, #120708 100%); }',
    '#hg::before { content: ""; position: absolute; inset: 0; pointer-events: none;',
    '  background: radial-gradient(ellipse at 50% 30%, rgba(255,190,90,0.06), rgba(0,0,0,0.45) 80%); }',
    '.hg-floors { flex: 1; display: flex; flex-direction: column-reverse; justify-content: center; gap: 13px; min-height: 0; }',
    '.hg-row { display: flex; align-items: center; gap: 14px; cursor: pointer; }',
    '.hg-plate { flex: 1; min-width: 0; padding: 9px 18px; border-radius: 5px; text-align: center; overflow-wrap: break-word;',
    '  background: linear-gradient(170deg, #7a5a30 0%, #a8834e 18%, #c9a86a 45%, #8a6437 78%, #6b4a26 100%);',
    '  border: 1px solid #3a2510; box-shadow: inset 0 1px 2px rgba(255,230,170,0.5), inset 0 -2px 3px rgba(0,0,0,0.4), 0 2px 5px rgba(0,0,0,0.55); }',
    '.hg-row:hover .hg-plate { box-shadow: inset 0 1px 2px rgba(255,230,170,0.7), inset 0 -2px 3px rgba(0,0,0,0.4), 0 0 14px rgba(255,190,90,0.35); }',
    '.hg-desc { font-size: 19px; font-weight: 600; color: #2e1c08; text-shadow: 0 1px 0 rgba(255,235,190,0.5); }',
    '.hg-fname { font-size: 12px; letter-spacing: 2.5px; color: rgba(46,28,8,0.75); text-transform: uppercase; margin-top: 1px; }',
    '.hg-btn { width: 64px; flex-shrink: 0; padding: 9px 0; text-align: center; font-size: 23px; font-weight: 700; color: #d9b878;',
    '  background: #100a06; border: 2px solid #8a6a3a; border-radius: 4px; white-space: nowrap; overflow: hidden;',
    '  clip-path: polygon(18% 0, 82% 0, 100% 30%, 100% 70%, 82% 100%, 18% 100%, 0 70%, 0 30%);',
    '  box-shadow: inset 0 0 8px rgba(0,0,0,0.9); }',
    '.hg-row:hover .hg-btn { border-color: #c9a86a; color: #f0d9a4; }',
    '.hg-row:active .hg-btn { background: #241505; }',
    '.hg-row.active .hg-btn { background: radial-gradient(circle, #ffdf9a 0%, #f5b93e 65%, #c98a1e 100%);',
    '  color: #3a2405; border-color: #ffe9b8; box-shadow: 0 0 22px rgba(255,190,80,0.85), inset 0 0 6px rgba(255,255,255,0.55); }',
    '#hg.st-arrived .hg-row.active .hg-btn { animation: hg-ding 0.7s ease; }',
    '@keyframes hg-ding { 40% { box-shadow: 0 0 42px rgba(255,205,100,1), inset 0 0 10px rgba(255,255,255,0.8); } }',
    '.hg-braille { width: 20px; height: 30px; opacity: 0.55; flex-shrink: 0;',
    '  background-image: radial-gradient(circle 2.5px, #c9a86a 55%, transparent 60%); background-size: 10px 10px; }',
    '.hg-bottom { display: flex; justify-content: center; gap: 26px; margin: 20px 0 16px 0; }',
    '.hg-door { width: 58px; height: 58px; border-radius: 50%; display: flex; align-items: center; justify-content: center;',
    '  font-size: 19px; color: #d9b878; background: #100a06; border: 2px solid #8a6a3a; cursor: pointer;',
    '  box-shadow: inset 0 0 8px rgba(0,0,0,0.9), 0 2px 5px rgba(0,0,0,0.5); font-family: "Segoe UI", sans-serif; }',
    '.hg-door:hover { border-color: #c9a86a; color: #f0d9a4; }',
    '.hg-door:active { background: #241505; }',
    '.hg-plaque { padding: 13px 18px; text-align: center; font-size: 15px; font-style: italic; color: #2e1c08; border-radius: 5px;',
    '  background: linear-gradient(170deg, #8a6a3a 0%, #c9a86a 50%, #7a5a30 100%); overflow-wrap: break-word;',
    '  border: 1px solid #3a2510; box-shadow: inset 0 1px 2px rgba(255,230,170,0.5), 0 2px 5px rgba(0,0,0,0.55);',
    '  text-shadow: 0 1px 0 rgba(255,235,190,0.4); }',
  ].join('\n');

  var FONT = 'Georgia, "Times New Roman", serif';
  // Usable width of the octagonal 64px button (border and cut corners)
  var BTN_TEXT_W = 52;

  // Texts come from locales/*.lua (display-* keys); English stands in for any
  // key the payload doesn't carry.
  function txt(S, key, fallback) {
    var v = S.strings && S.strings['display-' + key];
    return typeof v === 'string' ? v : fallback;
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
  function fitSize(el, text, base, min, avail, weight) {
    var w = textWidth(String(text), weight + ' 100px ' + FONT);
    var px = w > 0 ? Math.floor(avail * 100 / w) : base;
    px = Math.max(min, Math.min(base, px));
    el.style.fontSize = px < base ? px + 'px' : '';
  }

  function render(S) {
    var rows = S.floors.map(function (f, i) {
      return [
        '<div class="hg-row" data-floor="' + (i + 1) + '">',
        '  <div class="hg-plate"><div class="hg-desc"></div><div class="hg-fname"></div></div>',
        '  <div class="hg-btn"></div>',
        '  <div class="hg-braille"></div>',
        '</div>',
      ].join('');
    }).join('');

    return [
      '<div id="hg">',
      '  <div class="hg-floors">' + rows + '</div>',
      '  <div class="hg-bottom">',
      '    <div class="hg-door">◂▸</div>',
      '    <div class="hg-door">▸◂</div>',
      '  </div>',
      '  <div class="hg-plaque"></div>',
      '</div>',
    ].join('');
  }

  function update(S) {
    var hg = document.getElementById('hg');
    if (!hg) return;

    hg.className = 'st-' + S.status;

    var prefix = txt(S, 'floor-prefix', 'Floor');
    var rows = hg.querySelectorAll('.hg-row');
    for (var i = 0; i < rows.length; i++) {
      var idx = Number(rows[i].dataset.floor);
      var f = S.floors[idx - 1];
      rows[i].querySelector('.hg-desc').textContent = f.desc || f.name;
      rows[i].querySelector('.hg-fname').textContent = f.desc ? (prefix ? prefix + ' ' : '') + f.name : '';
      var btn = rows[i].querySelector('.hg-btn');
      btn.textContent = f.name;
      fitSize(btn, f.name, 23, 10, BTN_TEXT_W, 700);
      rows[i].classList.toggle('active', idx === S.current);
    }

    var cur = S.floors[S.current - 1];
    var tgt = S.target && S.floors[S.target - 1];
    var text = S.theme.title || txt(S, 'welcome', 'Welcome');
    if (S.status === 'transit') {
      text = txt(S, 'in-transit', 'In Transit') + ' ' + (S.dir > 0 ? '▲' : '▼') + ' — ' + (tgt ? (tgt.desc || tgt.name) : '');
    } else if (S.status === 'arrived') {
      text = txt(S, 'arrived', 'Arrived') + ' — ' + (cur ? (cur.desc || cur.name) : '');
    }
    hg.querySelector('.hg-plaque').textContent = text;
  }

  window.SKINS.heritage = { css: css, render: render, update: update };
})();
