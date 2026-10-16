// Skin: UV calibration pattern — shows exactly which part of the page lands on
// the screen face. All four corner tags visible = UVs span the full 0-1 space.
(function () {
  window.SKINS = window.SKINS || {};

  var css = [
    'body.skin-calib { background: #000; }',
    '#cal { position: relative; width: 100%; height: 100%; font-family: Consolas, monospace;',
    '  background: repeating-linear-gradient(45deg, #101010 0 14px, #161616 14px 28px); }',
    // 0-100% edge band
    '.cal-edge { position: absolute; background: #e0245e; }',
    '.cal-edge.t { top: 0; left: 0; right: 0; height: 6px; }',
    '.cal-edge.b { bottom: 0; left: 0; right: 0; height: 6px; }',
    '.cal-edge.l { top: 0; bottom: 0; left: 0; width: 6px; }',
    '.cal-edge.r { top: 0; bottom: 0; right: 0; width: 6px; }',
    // 90% safe area
    '.cal-safe { position: absolute; inset: 5%; border: 2px dashed #2ecc71; }',
    '.cal-safe::after { content: "90% SAFE AREA"; position: absolute; top: 4px; left: 50%;',
    '  transform: translateX(-50%); font-size: 13px; color: #2ecc71; letter-spacing: 1px; }',
    // corner tags
    '.cal-c { position: absolute; font-size: 21px; font-weight: 700; color: #fff; background: #e0245e;',
    '  padding: 5px 9px; letter-spacing: 1px; }',
    '.cal-c.tl { top: 6px; left: 6px; } .cal-c.tr { top: 6px; right: 6px; }',
    '.cal-c.bl { bottom: 6px; left: 6px; } .cal-c.br { bottom: 6px; right: 6px; }',
    // center crosshair
    '.cal-mid { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; }',
    '.cal-mid .x { font-size: 46px; color: #f1c40f; line-height: 1; }',
    '.cal-mid .l { font-size: 15px; color: #f1c40f; letter-spacing: 2px; margin-top: 4px; }',
    '.cal-mid .r { font-size: 12px; color: rgba(255,255,255,0.55); margin-top: 3px; }',
    '.cal-hline { position: absolute; top: 50%; left: 0; right: 0; height: 1px; background: rgba(241,196,15,0.5); }',
    '.cal-vline { position: absolute; left: 50%; top: 0; bottom: 0; width: 1px; background: rgba(241,196,15,0.5); }',
    // 10% ruler ticks
    '.cal-tick { position: absolute; left: 8px; font-size: 11px; color: #6cc9f0; }',
    '.cal-tickline { position: absolute; left: 0; right: 0; height: 1px; background: rgba(108,201,240,0.28); }',
  ].join('\n');

  function render(S) {
    var ticks = '';
    for (var p = 10; p <= 90; p += 10) {
      ticks += '<div class="cal-tickline" style="top:' + p + '%"></div>';
      ticks += '<div class="cal-tick" style="top:calc(' + p + '% + 2px)">' + p + '%</div>';
    }

    return [
      '<div id="cal">',
      '  <div class="cal-edge t"></div><div class="cal-edge b"></div>',
      '  <div class="cal-edge l"></div><div class="cal-edge r"></div>',
      ticks,
      '  <div class="cal-hline"></div><div class="cal-vline"></div>',
      '  <div class="cal-safe"></div>',
      '  <div class="cal-c tl">TL</div><div class="cal-c tr">TR</div>',
      '  <div class="cal-c bl">BL</div><div class="cal-c br">BR</div>',
      '  <div class="cal-mid"><div class="x">✛</div><div class="l">CENTER</div>',
      '    <div class="r">512 × 1024 · 1:2</div></div>',
      '</div>',
    ].join('');
  }

  function update(S) { /* static pattern */ }

  window.SKINS.calib = { css: css, render: render, update: update };
})();
