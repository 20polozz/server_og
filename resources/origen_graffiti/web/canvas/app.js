(function () {
  const canvas = document.getElementById('c');
  const ctx = canvas.getContext('2d', { alpha: true });

  canvas.width = 512;
  canvas.height = 512;

  var maxStrokes = 8000;
  var strokes = [];
  var lastU = null;
  var lastV = null;
  var resName = '';
  var showDebugPattern = false;
  // Dimensiones físicas del quad (metros). Se inicializan desde el mensaje 'init'
  // para compensar el estiramiento del canvas cuadrado sobre un quad rectangular.
  var quadW = 1;
  var quadH = 1;
  var sprayCfg = {
    dMin: 0.4,
    dMax: 7.0,
    rClose: 0.78,
    rFar: 1.45,
    iClose: 1.15,
    iFar: 0.4,
    dDefault: 2.5,
  };

  function sprayFactorsFromCamDist(distM) {
    var d =
      distM != null && typeof distM === 'number' && isFinite(distM)
        ? distM
        : sprayCfg.dDefault;
    var t = (d - sprayCfg.dMin) / (sprayCfg.dMax - sprayCfg.dMin);
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    return {
      radiusMul: sprayCfg.rClose + (sprayCfg.rFar - sprayCfg.rClose) * t,
      intensityMul: sprayCfg.iClose + (sprayCfg.iFar - sprayCfg.iClose) * t,
    };
  }

  function seedComposite() {
    ctx.fillStyle = 'rgba(0,0,0,0.004)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
  }

  function drawTestPattern() {
    var w = canvas.width;
    var h = canvas.height;
    var hw = w * 0.5;
    var hh = h * 0.5;
    ctx.save();
    ctx.globalCompositeOperation = 'source-over';
    ctx.fillStyle = '#cc3333';
    ctx.fillRect(0, 0, hw, hh);
    ctx.fillStyle = '#3333cc';
    ctx.fillRect(hw, 0, hw, hh);
    ctx.fillStyle = '#33aa33';
    ctx.fillRect(0, hh, hw, hh);
    ctx.fillStyle = '#cccc33';
    ctx.fillRect(hw, hh, hw, hh);
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 6;
    ctx.strokeRect(3, 3, w - 6, h - 6);
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 56px sans-serif';
    ctx.textBaseline = 'top';
    ctx.fillText('DUI OK', 24, 20);
    ctx.font = '22px sans-serif';
    ctx.fillText('UV 0,0 arriba-izq', 24, 88);
    ctx.textAlign = 'right';
    ctx.fillText('UV 1,1 abajo-der', w - 24, h - 36);
    ctx.textAlign = 'left';
    ctx.restore();
  }

  seedComposite();

  function drawSpraySegment(d) {
    const w = canvas.width;
    const h = canvas.height;
    const x1 = d.u1 * w;
    const y1 = d.v1 * h;
    const x2 = d.u2 * w;
    const y2 = d.v2 * h;
    const sf = sprayFactorsFromCamDist(d.dist);

    // Corrección de aspect ratio: para que el pincel sea un círculo en el espacio
    // físico del mundo, el canvas cuadrado necesita pintar una elipse que compense
    // el estiramiento de DrawSpritePoly sobre el quad rectangular.
    // Fórmula: baseRx = radius * canvasSize * min(qw,qh) / qw
    //          baseRy = radius * canvasSize * min(qw,qh) / qh
    // Si qw == qh (cuadrado): baseRx == baseRy → círculo perfecto. ✓
    const qw = quadW > 0.01 ? quadW : 1;
    const qh = quadH > 0.01 ? quadH : 1;
    const side = Math.min(qw, qh);
    const rad = d.radius || 0.01;
    let baseRx = Math.max(2, rad * (side / qw) * w) * sf.radiusMul;
    let baseRy = Math.max(2, rad * (side / qh) * h) * sf.radiusMul;
    // Radio geométrico medio: para cálculos de densidad y steps (escala-invariante)
    const baseR = Math.sqrt(baseRx * baseRy);

    const intMul = sf.intensityMul;
    const dx = x2 - x1;
    const dy = y2 - y1;
    const segPx = Math.sqrt(dx * dx + dy * dy);
    const perpX = segPx > 1e-6 ? -dy / segPx : 1;
    const perpY = segPx > 1e-6 ? dx / segPx : 0;
    const rCol = d.r | 0;
    const gCol = d.g | 0;
    const bCol = d.b | 0;

    ctx.save();
    if (d.eraser) {
      ctx.globalCompositeOperation = 'destination-out';
    } else {
      ctx.globalCompositeOperation = 'source-over';
    }

    // Dibuja una partícula de spray como elipse (compensa el estiramiento del quad)
    function speck(px, py, rrx, rry, alpha) {
      ctx.globalAlpha = Math.min(1, alpha * intMul);
      if (d.eraser) {
        ctx.fillStyle = 'rgba(0,0,0,1)';
      } else {
        ctx.fillStyle = 'rgb(' + rCol + ',' + gCol + ',' + bCol + ')';
      }
      ctx.beginPath();
      ctx.ellipse(px, py, Math.max(0.5, rrx), Math.max(0.5, rry), 0, 0, Math.PI * 2);
      ctx.fill();
    }

    if (segPx < 2) {
      const burst = Math.max(
        6,
        Math.min(52, Math.floor((22 + baseR * 0.18) * (0.65 + intMul * 0.5)))
      );
      for (let k = 0; k < burst; k++) {
        const ang = Math.random() * Math.PI * 2;
        const r = Math.random();
        const px = x1 + Math.cos(ang) * baseRx * 0.95 * r;
        const py = y1 + Math.sin(ang) * baseRy * 0.95 * r;
        const rrFrac = 0.05 + Math.random() * 0.38;
        const alpha = d.eraser ? 0.1 + Math.random() * 0.28 : 0.08 + Math.random() * 0.45;
        speck(px, py, baseRx * rrFrac, baseRy * rrFrac, alpha);
      }
      ctx.restore();
      return;
    }

    const steps = Math.max(1, Math.ceil(segPx / Math.max(1.5, baseR * 0.28)));
    const speckBase = Math.min(24, 5 + ((baseR * 0.14) | 0));
    const specks = Math.max(3, Math.floor(speckBase * (0.55 + intMul * 0.55)));
    for (let s = 0; s <= steps; s++) {
      const t = steps === 0 ? 0 : s / steps;
      const cx = x1 + dx * t;
      const cy = y1 + dy * t;
      for (let k = 0; k < specks; k++) {
        const j1 = (Math.random() - 0.5) * 2;
        const j2 = (Math.random() - 0.5) * 2;
        const px =
          cx +
          perpX * j1 * baseRx * 0.82 +
          (Math.random() - 0.5) * baseRx * 0.42;
        const py =
          cy +
          perpY * j1 * baseRy * 0.82 +
          (Math.random() - 0.5) * baseRy * 0.42;
        const px2 = px + perpX * j2 * baseRx * 0.35;
        const py2 = py + perpY * j2 * baseRy * 0.35;
        const rrFrac = 0.05 + Math.random() * 0.34;
        const alpha = d.eraser ? 0.1 + Math.random() * 0.24 : 0.09 + Math.random() * 0.4;
        speck(px2, py2, baseRx * rrFrac, baseRy * rrFrac, alpha);
      }
    }
    ctx.restore();
  }

  function redrawFromStrokes() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    seedComposite();
    if (strokes.length === 0) {
      if (showDebugPattern) drawTestPattern();
      return;
    }
    for (var i = 0; i < strokes.length; i++) {
      drawSpraySegment(strokes[i]);
    }
  }

  function resolveResourceName() {
    if (resName) return resName;
    if (typeof GetParentResourceName === 'function') {
      try {
        return GetParentResourceName();
      } catch (e) {
        return '';
      }
    }
    return '';
  }

  function postPngToLua() {
    var name = resolveResourceName();
    if (!name) return;
    if (strokes.length === 0) return;
    var dataUrl = canvas.toDataURL('image/png');
    fetch('https://' + name + '/graffiti_dui_export', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ imagePng: dataUrl }),
    }).catch(function () {});
  }

  function parseMessage(data) {
    if (data == null) return null;
    if (typeof data === 'string') {
      try {
        return JSON.parse(data);
      } catch (err) {
        return null;
      }
    }
    return typeof data === 'object' ? data : null;
  }

  window.addEventListener('message', function (e) {
    const d = parseMessage(e.data);
    if (!d || !d.action) return;

    if (d.action === 'init') {
      if (d.resource) resName = String(d.resource);
      if (typeof d.maxStrokes === 'number' && d.maxStrokes > 0) maxStrokes = d.maxStrokes | 0;
      showDebugPattern = !!d.debugPattern;
      if (typeof d.resolution === 'number' && d.resolution >= 64) {
        var res = d.resolution | 0;
        canvas.width = res;
        canvas.height = res;
        canvas.style.width = res + 'px';
        canvas.style.height = res + 'px';
        document.documentElement.style.width = res + 'px';
        document.documentElement.style.height = res + 'px';
        document.body.style.width = res + 'px';
        document.body.style.height = res + 'px';
        seedComposite();
      }
      if (typeof d.sprayDistMin === 'number') sprayCfg.dMin = d.sprayDistMin;
      if (typeof d.sprayDistMax === 'number') sprayCfg.dMax = d.sprayDistMax;
      if (typeof d.sprayRadiusMulClose === 'number') sprayCfg.rClose = d.sprayRadiusMulClose;
      if (typeof d.sprayRadiusMulFar === 'number') sprayCfg.rFar = d.sprayRadiusMulFar;
      if (typeof d.sprayIntensityMulClose === 'number') sprayCfg.iClose = d.sprayIntensityMulClose;
      if (typeof d.sprayIntensityMulFar === 'number') sprayCfg.iFar = d.sprayIntensityMulFar;
      if (typeof d.sprayDistDefault === 'number') sprayCfg.dDefault = d.sprayDistDefault;
      if (typeof d.quadW === 'number' && d.quadW > 0.01) quadW = d.quadW;
      if (typeof d.quadH === 'number' && d.quadH > 0.01) quadH = d.quadH;
      if (showDebugPattern) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        seedComposite();
        drawTestPattern();
      }
      return;
    }

    if (d.action === 'clear') {
      strokes = [];
      lastU = lastV = null;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      seedComposite();
      if (showDebugPattern) drawTestPattern();
      return;
    }

    if (d.action === 'undo') {
      if (strokes.length > 0) strokes.pop();
      redrawFromStrokes();
      lastU = lastV = null;
      return;
    }

    if (d.action === 'replay' && Array.isArray(d.strokes)) {
      strokes = d.strokes.slice();
      redrawFromStrokes();
      lastU = lastV = null;
      return;
    }

    if (d.action === 'requestExportPng') {
      postPngToLua();
      return;
    }

    if (d.action === 'loadImage' && typeof d.url === 'string' && d.url.length > 0) {
      strokes = [];
      lastU = lastV = null;
      var img = new Image();
      img.crossOrigin = 'anonymous';
      img.onload = function () {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      };
      img.onerror = function () {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        seedComposite();
      };
      img.src = d.url;
      return;
    }

    if (d.action === 'appendSegment' && d.segment && typeof d.segment === 'object') {
      drawSpraySegment(d.segment);
      if (strokes.length < maxStrokes) strokes.push(d.segment);
      return;
    }

    if (d.action === 'pointer') {
      if (!d.down) {
        lastU = null;
        lastV = null;
        return;
      }

      const u = d.u;
      const v = d.v;
      const camDist =
        d.dist != null && typeof d.dist === 'number' && isFinite(d.dist) ? d.dist : sprayCfg.dDefault;
      const brush = {
        r: d.r | 0,
        g: d.g | 0,
        b: d.b | 0,
        radius: d.radius,
        eraser: !!d.eraser,
      };

      if (lastU === null || lastV === null) {
        const dot = {
          u1: u,
          v1: v,
          u2: u + 0.001,
          v2: v,
          r: brush.r,
          g: brush.g,
          b: brush.b,
          radius: brush.radius,
          eraser: brush.eraser,
          dist: camDist,
        };
        drawSpraySegment(dot);
        if (strokes.length < maxStrokes) strokes.push(dot);
        lastU = u;
        lastV = v;
        return;
      }

      const du = u - lastU;
      const dv = v - lastV;
      if (du * du + dv * dv < 1e-14) return;

      const seg = {
        u1: lastU,
        v1: lastV,
        u2: u,
        v2: v,
        r: brush.r,
        g: brush.g,
        b: brush.b,
        radius: brush.radius,
        eraser: brush.eraser,
        dist: camDist,
      };
      drawSpraySegment(seg);
      if (strokes.length < maxStrokes) strokes.push(seg);
      lastU = u;
      lastV = v;
    }
  });
})();
