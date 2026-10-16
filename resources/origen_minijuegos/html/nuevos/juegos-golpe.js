/* LOS MINIJUEGOS NUEVOS · segunda tanda, el golpe
 *   boveda   los anillos de la camara    termita  memoria que arde
 *   soplete  cortar la puerta            laser    espejos
 * Todos son «grandes»: pantalla al centro, pintados en lienzo con fx.js.
 */
(function () {
  'use strict'

  var MJ = window.OrigenMJ
  var U = MJ.util
  var C = MJ.fx.COLOR
  var TAU = Math.PI * 2

  function difAngulo(a, b) {
    var d = ((a - b) % 360 + 540) % 360 - 180
    return Math.abs(d)
  }

  /* ═══ BOVEDA ══════════════════════════════════════════════════════════
     cfg: anillos, velocidad, margen (grados), acelera, fallos, tiempo */
  MJ.registrar('boveda', {
    titulo: 'Cámara acorazada',
    grande: true,
    ayuda: 'Cada anillo gira solo. Pulsa **ESPACIO** (o **CLIC**) cuando su muesca pase por el **CERROJO** de arriba. De fuera hacia dentro.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var n = U.tope(Math.round(cfg.anillos || 4), 2, 7)
      var medio = U.tope(Number(cfg.margen) || 12, 3, 40) / 2
      var vel = Math.max(0.2, Number(cfg.velocidad) || 1)
      var acelera = U.tope(Number(cfg.acelera) || 0, 0, 0.6)
      var E = MJ.fx.escenario(ctx)
      var cx = E.W / 2, cy = E.H / 2 + E.H * 0.035
      var R = Math.min(E.W, E.H) * 0.4

      var anillos = []
      for (var i = 0; i < n; i++) {
        anillos.push({
          ang: U.azar(40, 320),
          vel: vel * 90 * U.azar(0.75, 1.2) * (i % 2 ? -1 : 1),
          fijo: false, golpe: 0,
        })
      }
      var activo = 0
      var final = 0       // > 0: la puerta se esta abriendo
      var volante = 0

      function radios(i) {
        var paso = (R * 0.72) / n
        return { fuera: R - i * paso, dentro: R - (i + 1) * paso + 3 }
      }

      function pulsar() {
        if (!ctx.viva() || final > 0) return
        var a = anillos[activo]
        if (difAngulo(a.ang, 0) <= medio) {
          a.fijo = true
          a.ang = 0
          a.golpe = 1
          var r = radios(activo)
          E.chispas(cx, cy - (r.fuera + r.dentro) / 2, 46, { color: C.ambar, fuerza: 320, dura: 0.7 })
          E.sacudir(9)
          E.destellar('#ffd27a', 0.18)
          ctx.acierto()
          activo++
          ctx.progreso(activo, n)
          if (activo >= n) final = 0.001
        } else {
          a.vel *= 1 + acelera
          E.sacudir(5)
          E.destellar(C.rojo, 0.2)
          ctx.fallo()
        }
      }

      ctx.tecla(function (codigo, abajo, e, repetida) {
        if (abajo && !repetida && (codigo === 'Space' || codigo === 'Enter')) pulsar()
      })
      ctx.escuchar(E.nodo, 'mousedown', function (e) { if (e.button === 0) pulsar() })

      function sector(g, r0, r1, a0, a1) {
        g.beginPath()
        g.arc(cx, cy, r1, a0, a1)
        g.arc(cx, cy, r0, a1, a0, true)
        g.closePath()
      }

      ctx.fotograma(function (dt) {
        var g = E.g
        E.abrir(dt)

        /* La puerta */
        var acero = g.createRadialGradient(cx - R * 0.3, cy - R * 0.4, R * 0.1, cx, cy, R * 1.12)
        acero.addColorStop(0, '#5a6572'); acero.addColorStop(0.6, '#2b333d'); acero.addColorStop(1, '#151a20')
        g.fillStyle = acero
        g.beginPath(); g.arc(cx, cy, R * 1.1, 0, TAU); g.fill()
        g.strokeStyle = '#0b0e12'; g.lineWidth = 3; g.stroke()
        for (var k = 0; k < 16; k++) {
          var ar = k / 16 * TAU
          g.fillStyle = '#7a8794'
          g.beginPath(); g.arc(cx + Math.cos(ar) * R * 1.04, cy + Math.sin(ar) * R * 1.04, R * 0.018, 0, TAU); g.fill()
        }

        for (var i = 0; i < n; i++) {
          var a = anillos[i]
          if (!a.fijo && final === 0) a.ang = ((a.ang + a.vel * dt) % 360 + 360) % 360
          a.golpe = Math.max(0, a.golpe - dt * 2.5)
          var r = radios(i)
          var rad = (a.ang - 90) * Math.PI / 180
          var hueco = Math.max(medio, 5) * Math.PI / 180 * 1.15

          g.save()
          if (final > 0) { g.translate(cx, cy); g.rotate(final * (i % 2 ? -1.6 : 1.6) * (1 + i * 0.2)); g.translate(-cx, -cy) }
          var tono = a.fijo ? '#2f5d4c' : (i === activo ? '#46525f' : '#333c46')
          g.fillStyle = tono
          sector(g, r.dentro, r.fuera, rad + hueco, rad - hueco + TAU)
          g.fill()
          g.strokeStyle = '#0b0e12'; g.lineWidth = 2; g.stroke()
          /* la muesca: un hueco negro, para que se vea de lejos */
          g.fillStyle = '#04060a'
          sector(g, r.dentro, r.fuera, rad - hueco, rad + hueco)
          g.fill()
          /* dientes del anillo */
          g.strokeStyle = 'rgba(255,255,255,0.10)'; g.lineWidth = 1
          for (var d = 0; d < 36; d++) {
            var ad = rad + d / 36 * TAU
            g.beginPath()
            g.moveTo(cx + Math.cos(ad) * (r.dentro + 3), cy + Math.sin(ad) * (r.dentro + 3))
            g.lineTo(cx + Math.cos(ad) * (r.fuera - 3), cy + Math.sin(ad) * (r.fuera - 3))
            g.stroke()
          }
          g.restore()

          /* la muesca, en neon */
          var color = a.fijo ? C.verde : (i === activo ? C.rosa : C.gris)
          ;(function (r, rad, hueco, color, fuerza) {
            E.neon(function (g) {
              g.moveTo(cx + Math.cos(rad - hueco) * r.dentro, cy + Math.sin(rad - hueco) * r.dentro)
              g.lineTo(cx + Math.cos(rad - hueco) * r.fuera, cy + Math.sin(rad - hueco) * r.fuera)
              g.moveTo(cx + Math.cos(rad + hueco) * r.dentro, cy + Math.sin(rad + hueco) * r.dentro)
              g.lineTo(cx + Math.cos(rad + hueco) * r.fuera, cy + Math.sin(rad + hueco) * r.fuera)
            }, color, 2.2, fuerza)
          })(r, rad, hueco, color, i === activo || a.fijo ? 1 : 0.35)
          if (a.golpe > 0) E.halo(cx, cy - (r.fuera + r.dentro) / 2, R * 0.3 * a.golpe, '#ffd27a', a.golpe)
        }

        /* el cerrojo de arriba: baja por los anillos ya fijados */
        var hasta = activo >= n ? radios(n - 1).dentro : radios(activo).fuera
        var baja = final > 0 ? Math.max(0, 1 - final * 2.2) : 1
        g.fillStyle = '#c9d2dc'
        var anchoC = R * 0.05
        g.fillRect(cx - anchoC / 2, cy - R * 1.1, anchoC, (R * 1.1 - hasta) * baja)
        E.neon(function (g) { g.moveTo(cx, cy - R * 1.1); g.lineTo(cx, cy - R * 1.1 + (R * 1.1 - hasta) * baja) }, C.cian, 1.6, 0.8)
        /* y la marca de donde hay que parar, siempre a la vista */
        g.fillStyle = C.cian
        g.beginPath(); g.moveTo(cx, cy - R * 1.12); g.lineTo(cx - R * 0.05, cy - R * 1.22); g.lineTo(cx + R * 0.05, cy - R * 1.22); g.closePath(); g.fill()
        E.halo(cx, cy - R * 1.16, R * 0.16, C.cian, 0.5)

        /* el volante */
        if (final > 0) volante += dt * 7
        var rv = radios(n - 1).dentro * 0.78
        g.save(); g.translate(cx, cy); g.rotate(volante)
        g.strokeStyle = '#aab4bf'; g.lineWidth = rv * 0.16; g.lineCap = 'round'
        for (var s = 0; s < 3; s++) { g.rotate(TAU / 3); g.beginPath(); g.moveTo(0, 0); g.lineTo(0, -rv); g.stroke() }
        g.beginPath(); g.arc(0, 0, rv, 0, TAU); g.lineWidth = rv * 0.12; g.stroke()
        g.fillStyle = '#d9e0e7'; g.beginPath(); g.arc(0, 0, rv * 0.22, 0, TAU); g.fill()
        g.restore()

        if (final > 0) {
          final += dt
          if (Math.random() < 0.5) E.chispas(cx + U.azar(-R, R) * 0.7, cy + U.azar(-R, R) * 0.7, 3, { color: C.verde, fuerza: 120, gravedad: 0 })
          E.halo(cx, cy, R * (0.4 + final), C.verde, Math.min(0.5, final))
          if (final > 1.1) { E.cerrar(dt); ctx.ganar(); return }
        }
        E.cerrar(dt)
      })

      ctx.progreso(0, n)
    },
  })

  /* ═══ TERMITA ═════════════════════════════════════════════════════════
     cfg: tamano, casillas, muestra (s), rondas, fallos, tiempo */
  MJ.registrar('termita', {
    titulo: 'Carga de termita',
    grande: true,
    ayuda: 'Mira dónde van las **CARGAS**, memorízalas y, cuando se apaguen, márcalas todas. Un toque donde no hay carga es un fallo.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var n = U.tope(Math.round(cfg.tamano || 6), 3, 9)
      var cuantas = U.tope(Math.round(cfg.casillas || 8), 1, n * n - 1)
      var muestra = Math.max(0.5, Number(cfg.muestra) || 3)
      var rondas = U.tope(Math.round(cfg.rondas || 1), 1, 6)
      var E = MJ.fx.escenario(ctx)

      var lado = Math.min(E.W * 0.7, E.H * 0.9)
      var x0 = (E.W - lado) / 2, y0 = (E.H - lado) / 2, celda = lado / n

      var ronda = 0, fase = 'mirar', reloj = 0
      var casillas = [], quedan = 0, encima = -1

      function nueva() {
        casillas = []
        for (var i = 0; i < n * n; i++) casillas.push({ carga: false, hecha: false, error: 0, arde: 0 })
        U.barajar(casillas.map(function (_, i) { return i })).slice(0, cuantas).forEach(function (i) { casillas[i].carga = true })
        quedan = cuantas
        fase = 'mirar'
        reloj = muestra
        ctx.progreso(ronda, rondas)
      }

      function centro(i) { return { x: x0 + (i % n + 0.5) * celda, y: y0 + (Math.floor(i / n) + 0.5) * celda } }

      function tocar(i) {
        if (!ctx.viva() || fase !== 'jugar' || i < 0) return
        var c = casillas[i]
        if (c.hecha || c.error > 0.2) return
        var p = centro(i)
        if (c.carga) {
          c.hecha = true
          c.arde = 1
          quedan--
          E.chispas(p.x, p.y, 26, { color: C.ambar, fuerza: 260 })
          ctx.sonido('clic')
          if (quedan <= 0) { fase = 'arder'; reloj = 1.2; ctx.acierto() }
        } else {
          c.error = 1
          E.sacudir(8)
          E.destellar(C.rojo, 0.22)
          ctx.fallo()
        }
      }

      function cual(e) {
        var p = E.raton(e)
        var cxn = Math.floor((p.x - x0) / celda), cyn = Math.floor((p.y - y0) / celda)
        if (cxn < 0 || cyn < 0 || cxn >= n || cyn >= n) return -1
        return cyn * n + cxn
      }
      ctx.escuchar(E.nodo, 'mousemove', function (e) { encima = cual(e) })
      ctx.escuchar(E.nodo, 'mouseleave', function () { encima = -1 })
      ctx.escuchar(E.nodo, 'mousedown', function (e) { if (e.button === 0) tocar(cual(e)) })

      ctx.fotograma(function (dt) {
        var g = E.g
        E.abrir(dt)

        /* la plancha de acero */
        g.fillStyle = '#1b222a'
        g.fillRect(x0 - 10, y0 - 10, lado + 20, lado + 20)
        g.strokeStyle = '#3a4653'; g.lineWidth = 2
        g.strokeRect(x0 - 10, y0 - 10, lado + 20, lado + 20)

        if (fase === 'mirar') { reloj -= dt; if (reloj <= 0) fase = 'jugar' }

        for (var i = 0; i < casillas.length; i++) {
          var c = casillas[i], p = centro(i)
          var m = celda * 0.07
          var x = p.x - celda / 2 + m, y = p.y - celda / 2 + m, w = celda - m * 2
          c.error = Math.max(0, c.error - dt * 1.6)
          g.fillStyle = i === encima && fase === 'jugar' && !c.hecha ? '#34404d' : '#262f39'
          g.fillRect(x, y, w, w)
          g.strokeStyle = 'rgba(255,255,255,0.07)'; g.lineWidth = 1
          g.strokeRect(x + 0.5, y + 0.5, w - 1, w - 1)

          var seVe = c.carga && (fase === 'mirar' || c.hecha || fase === 'arder')
          if (seVe) {
            var late = fase === 'mirar' ? 0.75 + Math.sin(E.t * 9 + i) * 0.25 : 1
            g.fillStyle = c.hecha || fase === 'arder' ? '#ff7a1a' : C.ambar
            g.globalAlpha = late
            g.fillRect(x + w * 0.18, y + w * 0.18, w * 0.64, w * 0.64)
            g.globalAlpha = 1
            E.halo(p.x, p.y, celda * 0.9, c.hecha ? '#ff6a00' : C.ambar, 0.35 * late)
            if (c.hecha || fase === 'arder') E.fuego(p.x, p.y + w * 0.2, fase === 'arder' ? 3 : 1, w * 0.6)
          }
          if (c.error > 0) {
            g.globalAlpha = c.error
            g.fillStyle = C.rojo
            g.fillRect(x, y, w, w)
            g.globalAlpha = 1
          }
        }

        if (fase === 'mirar') {
          E.texto('MEMORIZA', x0 / 2, E.H / 2, E.H * 0.055, C.ambar)
          g.fillStyle = C.ambar
          g.fillRect(x0, y0 + lado + 16, lado * Math.max(0, reloj / muestra), 4)
        } else if (fase === 'jugar') {
          E.texto('QUEDAN', x0 / 2, E.H / 2 - E.H * 0.05, E.H * 0.04, '#aab4bf')
          E.texto(String(quedan), x0 / 2, E.H / 2 + E.H * 0.04, E.H * 0.12, C.ambar)
        }

        if (fase === 'arder') {
          reloj -= dt
          E.sacudir(3)
          if (reloj <= 0) {
            ronda++
            ctx.progreso(ronda, rondas)
            if (ronda >= rondas) { E.cerrar(dt); ctx.ganar(); return }
            nueva()
          }
        }
        E.cerrar(dt)
      })

      nueva()
    },
  })

  /* ═══ SOPLETE ═════════════════════════════════════════════════════════
     cfg: ancho (% del alto), velocidad, forma (0..1), calor, fallos, tiempo */
  MJ.registrar('soplete', {
    titulo: 'Soplete',
    grande: true,
    ayuda: 'Pulsa sobre la **LLAMA** y, sin soltar, rodea la cerradura al ritmo del corte. Si te sales, fallo; si te paras con el soplete encendido, se recalienta.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var E = MJ.fx.escenario(ctx)
      var cx = E.W / 2, cy = E.H / 2
      var R = Math.min(E.W, E.H) * 0.34
      var medio = Math.max(4, E.H * U.tope(Number(cfg.ancho) || 5, 1.5, 14) / 100 / 2)
      var forma = U.tope(Number(cfg.forma) || 0, 0, 1)
      var ritmo = Math.max(0.2, Number(cfg.velocidad) || 1)
      var calorF = Math.max(0.1, Number(cfg.calor) || 1)

      var N = 360
      var camino = []
      var f1 = U.entero(2, 3), f2 = U.entero(4, 6), p1 = U.azar(0, TAU), p2 = U.azar(0, TAU)
      for (var i = 0; i <= N; i++) {
        var a = i / N * TAU - Math.PI / 2
        var r = R * (1 + forma * (0.16 * Math.sin(a * f1 + p1) + 0.08 * Math.sin(a * f2 + p2)))
        camino.push({ x: cx + Math.cos(a) * r, y: cy + Math.sin(a) * r, frio: 0 })
      }
      /* el primer y el ultimo punto coinciden: el corte se cierra */
      camino[N].x = camino[0].x; camino[N].y = camino[0].y

      var cabeza = 0            // hasta donde esta cortado (con decimales)
      var porSegundo = N / (14 / ritmo)
      var puntero = null, encendido = false
      var calor = 0, enfria = 0
      var final = 0

      function dist(a, b) { return Math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)) }

      function apuntar(p, pulsado) {
        puntero = p
        if (!pulsado) { encendido = false; return }
        if (!encendido && enfria <= 0 && p && dist(p, camino[Math.floor(cabeza)]) <= Math.max(medio, 14) * 1.5) encendido = true
      }

      ctx.escuchar(E.nodo, 'mousedown', function (e) { if (e.button === 0) apuntar(E.raton(e), true) })
      ctx.escuchar(window, 'mousemove', function (e) { apuntar(E.raton(e), encendido) })
      ctx.escuchar(window, 'mouseup', function () { encendido = false })

      function castigo() {
        encendido = false
        enfria = 0.7
        calor = 0.3
        E.sacudir(10)
        E.destellar(C.rojo, 0.25)
        ctx.fallo()
      }

      ctx.fotograma(function (dt) {
        var g = E.g
        E.abrir(dt, false)
        enfria = Math.max(0, enfria - dt)

        /* la puerta: acero cepillado */
        var acero = g.createLinearGradient(0, 0, E.W, E.H)
        acero.addColorStop(0, '#3a434d'); acero.addColorStop(0.5, '#262d35'); acero.addColorStop(1, '#343c45')
        g.fillStyle = acero
        g.fillRect(0, 0, E.W, E.H)
        g.strokeStyle = 'rgba(255,255,255,0.035)'; g.lineWidth = 1
        g.beginPath()
        for (var y = 3; y < E.H; y += 5) { g.moveTo(0, y); g.lineTo(E.W, y + 2) }
        g.stroke()

        var ih = Math.floor(cabeza)
        var punta = camino[Math.min(N, ih)]

        if (final === 0) {
          if (encendido && puntero) {
            /* ¿sigue dentro de la franja? se mira contra el tramo de delante */
            var mejor = Infinity, donde = ih
            for (var k = Math.max(0, ih - 4); k <= Math.min(N, ih + 26); k++) {
              var d = dist(puntero, camino[k])
              if (d < mejor) { mejor = d; donde = k }
            }
            if (mejor > medio * 1.35) castigo()
            else {
              var antes = cabeza
              if (donde > cabeza) cabeza = Math.min(donde, cabeza + porSegundo * dt, N)
              var avanza = cabeza - antes > porSegundo * dt * 0.25
              calor = U.tope(calor + (avanza ? -0.25 : 0.55 * calorF) * dt, 0, 1)
              if (calor >= 1) castigo()
              for (var q = Math.floor(antes); q <= Math.floor(cabeza); q++) camino[q].frio = 0
              E.chispas(punta.x, punta.y, avanza ? 5 : 2, { color: avanza ? '#ffd27a' : '#ff7a1a', fuerza: 260, dura: 0.55, angulo: Math.atan2(punta.y - cy, punta.x - cx), abanico: 2.4 })
              if (Math.random() < 0.3) E.fuego(punta.x, punta.y, 1, 8)
            }
          } else calor = Math.max(0, calor - 0.35 * dt)

          if (cabeza >= N - 0.5) { final = 0.001; encendido = false; ctx.acierto(); E.sacudir(14); E.destellar('#ffd27a', 0.35) }
        }

        /* la cerradura que se va a caer */
        g.save()
        if (final > 0) {
          final += dt
          g.translate(cx, cy + final * final * E.H * 0.9)
          g.rotate(final * 0.5)
          g.translate(-cx, -cy)
          g.globalAlpha = Math.max(0, 1 - final * 0.9)
        }
        g.beginPath()
        for (var s = 0; s <= N; s += 4) { if (s === 0) g.moveTo(camino[s].x, camino[s].y); else g.lineTo(camino[s].x, camino[s].y) }
        g.closePath()
        var disco = g.createRadialGradient(cx - R * 0.3, cy - R * 0.3, R * 0.1, cx, cy, R * 1.2)
        disco.addColorStop(0, '#56616d'); disco.addColorStop(1, '#2a323b')
        g.fillStyle = disco
        g.fill()
        g.fillStyle = '#11151a'
        g.beginPath(); g.arc(cx, cy, R * 0.2, 0, TAU); g.fill()
        g.fillRect(cx - R * 0.05, cy, R * 0.1, R * 0.34)
        g.strokeStyle = '#8e9aa6'; g.lineWidth = 3
        g.beginPath(); g.arc(cx, cy, R * 0.3, 0, TAU); g.stroke()
        g.restore()
        if (final > 0) {
          g.fillStyle = '#020304'
          g.globalAlpha = Math.min(1, final * 2)
          g.beginPath()
          for (var s2 = 0; s2 <= N; s2 += 4) { if (s2 === 0) g.moveTo(camino[s2].x, camino[s2].y); else g.lineTo(camino[s2].x, camino[s2].y) }
          g.closePath(); g.fill()
          g.globalAlpha = 1
        }

        /* la guia: por donde hay que cortar */
        if (final === 0) {
          g.setLineDash([6, 8])
          g.strokeStyle = 'rgba(245,240,230,0.35)'; g.lineWidth = 1.5
          g.beginPath()
          for (var t = ih; t <= N; t += 2) { if (t === ih) g.moveTo(camino[t].x, camino[t].y); else g.lineTo(camino[t].x, camino[t].y) }
          g.stroke()
          g.setLineDash([])
          g.strokeStyle = 'rgba(245,240,230,0.07)'; g.lineWidth = medio * 2; g.lineCap = 'round'
          g.beginPath()
          for (var t2 = ih; t2 <= Math.min(N, ih + 60); t2 += 2) { if (t2 === ih) g.moveTo(camino[t2].x, camino[t2].y); else g.lineTo(camino[t2].x, camino[t2].y) }
          g.stroke()
        }

        /* lo cortado: recien hecho es blanco-amarillo, luego naranja, luego rojo apagado */
        g.globalCompositeOperation = 'lighter'
        g.lineCap = 'round'
        for (var c = 0; c < ih; c += 3) {
          var pa = camino[c], pb = camino[Math.min(ih, c + 3)]
          pa.frio += dt * 3
          var fr = Math.min(1, pa.frio / 5)
          g.strokeStyle = fr < 0.25 ? '#fff1b8' : (fr < 0.6 ? '#ff9a2e' : '#a3261a')
          g.globalAlpha = 1 - fr * 0.45
          g.lineWidth = 5 - fr * 2
          g.beginPath(); g.moveTo(pa.x, pa.y); g.lineTo(pb.x, pb.y); g.stroke()
          g.globalAlpha = (1 - fr) * 0.25
          g.lineWidth = 16
          g.beginPath(); g.moveTo(pa.x, pa.y); g.lineTo(pb.x, pb.y); g.stroke()
        }
        g.globalAlpha = 1
        g.globalCompositeOperation = 'source-over'

        /* la llama */
        if (final === 0) {
          var late = 1 + Math.sin(E.t * 30) * 0.12
          E.halo(punta.x, punta.y, (encendido ? 46 : 22) * late, encendido ? '#9fd8ff' : C.rosa, encendido ? 0.9 : 0.6)
          g.fillStyle = encendido ? '#ffffff' : C.rosa
          g.beginPath(); g.arc(punta.x, punta.y, encendido ? 5 : 7 + Math.sin(E.t * 6) * 1.5, 0, TAU); g.fill()
          if (enfria > 0) E.texto('ESPERA', punta.x, punta.y - 30, 18, C.rojo)
        }

        /* el termometro */
        var bx = E.W - 46, by = E.H * 0.16, bh = E.H * 0.68
        g.fillStyle = 'rgba(0,0,0,0.5)'; g.fillRect(bx, by, 16, bh)
        g.fillStyle = calor > 0.7 ? C.rojo : C.ambar
        g.fillRect(bx, by + bh * (1 - calor), 16, bh * calor)
        g.strokeStyle = '#8e9aa6'; g.lineWidth = 1.5; g.strokeRect(bx, by, 16, bh)
        E.texto('CALOR', bx + 8, by - 14, 13, '#aab4bf')

        if (final > 1.15) { E.cerrar(dt); ctx.ganar(); return }
        E.cerrar(dt)
      })

      ctx.progreso(0, 1)
    },
  })

  /* ═══ LASER ═══════════════════════════════════════════════════════════
     cfg: tamano, espejos, senuelos, muros, giros (0 = sin limite), tiempo */
  MJ.registrar('laser', {
    titulo: 'Rejilla láser',
    grande: true,
    ayuda: 'Haz **CLIC** en los espejos para girarlos y lleva el rayo desde el **EMISOR** hasta el **RECEPTOR**.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var n = U.tope(Math.round(cfg.tamano || 6), 4, 9)
      var minimo = U.tope(Math.round(cfg.espejos || 4), 1, 10)
      var senuelos = U.tope(Math.round(cfg.senuelos || 0), 0, 12)
      var muros = U.tope(Math.round(cfg.muros || 0), 0, 8)
      var maxGiros = Math.max(0, Math.round(cfg.giros || 0))
      var E = MJ.fx.escenario(ctx)

      /* Deja sitio fuera de la rejilla: el emisor y el receptor van en el borde. */
      var lado = Math.min(E.W * 0.6, E.H * (1 - 2.3 / (n + 2.3)))
      var celda = lado / n
      var x0 = (E.W - lado) / 2, y0 = (E.H - lado) / 2

      /* Direcciones: 0 derecha, 1 abajo, 2 izquierda, 3 arriba.
         Espejo '/' (estado 0): derecha<->arriba, izquierda<->abajo.
         Espejo '\' (estado 1): derecha<->abajo, izquierda<->arriba. */
      var DX = [1, 0, -1, 0], DY = [0, 1, 0, -1]
      var REBOTE = [[3, 2, 1, 0], [1, 0, 3, 2]]

      var rejilla, emisor, receptor, giros = 0, final = 0

      function trazar(estados) {
        var x = -1, y = emisor, dir = 0, puntos = [{ x: -1, y: emisor }], tocados = [], pasos = 0
        while (pasos++ < 300) {
          x += DX[dir]; y += DY[dir]
          if (x < 0 || y < 0 || x >= n || y >= n) { puntos.push({ x: x, y: y }); return { puntos: puntos, sale: { x: x, y: y }, tocados: tocados } }
          var c = rejilla[y * n + x]
          if (c.tipo === 'muro') { puntos.push({ x: x, y: y, choca: true }); return { puntos: puntos, sale: null, tocados: tocados } }
          if (c.tipo === 'espejo') {
            puntos.push({ x: x, y: y })
            if (tocados.indexOf(y * n + x) === -1) tocados.push(y * n + x)
            dir = REBOTE[estados ? estados[y * n + x] : c.estado][dir]
          }
        }
        return { puntos: puntos, sale: null, tocados: tocados }
      }

      function generar() {
        for (var intento = 0; intento < 400; intento++) {
          rejilla = []
          for (var i = 0; i < n * n; i++) rejilla.push({ tipo: 'vacio', estado: 0, meta: null, giro: 0 })
          emisor = U.entero(0, n - 1)
          var libres = U.barajar(rejilla.map(function (_, i) { return i }))
          var cuantos = minimo + senuelos + 2
          libres.slice(0, cuantos).forEach(function (i) { rejilla[i].tipo = 'espejo'; rejilla[i].estado = U.entero(0, 1) })
          libres.slice(cuantos, cuantos + muros).forEach(function (i) { rejilla[i].tipo = 'muro' })
          var r = trazar()
          /* tiene que salir por un borde que no sea el del emisor y tocar bastantes espejos */
          /* Si lo pedido no cabe en la rejilla, se va rebajando en vez de no arrancar. */
          var pide = Math.max(1, minimo - Math.floor(intento / 80))
          if (!r.sale || r.sale.x < 0 || r.tocados.length < pide) continue
          receptor = r.sale
          r.tocados.forEach(function (i) { rejilla[i].meta = rejilla[i].estado })
          /* se quitan espejos sobrantes hasta dejar los señuelos pedidos */
          var sobran = rejilla.map(function (c, i) { return c.tipo === 'espejo' && c.meta === null ? i : -1 }).filter(function (i) { return i >= 0 })
          U.barajar(sobran).slice(senuelos).forEach(function (i) { rejilla[i].tipo = 'vacio' })
          if (trazar().tocados.length < pide) continue
          /* y se desordena, asegurando que no quede resuelto */
          for (var v = 0; v < 30; v++) {
            rejilla.forEach(function (c) { if (c.tipo === 'espejo') c.estado = U.entero(0, 1) })
            if (!llega(trazar())) return true
          }
        }
        return false
      }

      function llega(r) { return !!(r.sale && receptor && r.sale.x === receptor.x && r.sale.y === receptor.y) }

      function voltear(i) {
        if (!ctx.viva() || final > 0) return
        var c = rejilla[i]
        if (!c || c.tipo !== 'espejo') return
        c.estado = 1 - c.estado
        c.giro = 1
        giros++
        ctx.sonido('clic')
        if (maxGiros) ctx.vidas(Math.max(0, maxGiros - giros), maxGiros)
        var r = trazar()
        if (llega(r)) { final = 0.001; ctx.acierto(); E.destellar(C.verde, 0.3) }
        else if (maxGiros && giros >= maxGiros) { E.destellar(C.rojo, 0.3); ctx.perder() }
      }

      if (!generar()) { ctx.perder(); return }
      if (maxGiros) ctx.vidas(maxGiros, maxGiros)

      function px(p) { return { x: x0 + (p.x + 0.5) * celda, y: y0 + (p.y + 0.5) * celda } }

      ctx.escuchar(E.nodo, 'mousedown', function (e) {
        if (e.button !== 0) return
        var p = E.raton(e)
        var cxn = Math.floor((p.x - x0) / celda), cyn = Math.floor((p.y - y0) / celda)
        if (cxn >= 0 && cyn >= 0 && cxn < n && cyn < n) voltear(cyn * n + cxn)
      })

      ctx.fotograma(function (dt) {
        var g = E.g
        E.abrir(dt)

        g.fillStyle = 'rgba(12,18,26,0.85)'
        g.fillRect(x0, y0, lado, lado)
        g.strokeStyle = 'rgba(53,224,255,0.16)'; g.lineWidth = 1
        g.beginPath()
        for (var k = 0; k <= n; k++) { g.moveTo(x0 + k * celda, y0); g.lineTo(x0 + k * celda, y0 + lado); g.moveTo(x0, y0 + k * celda); g.lineTo(x0 + lado, y0 + k * celda) }
        g.stroke()

        var r = trazar()
        var bien = llega(r)

        /* emisor y receptor */
        var pe = px({ x: -1, y: emisor }), pr = px(receptor)
        g.fillStyle = '#2a323b'; g.fillRect(pe.x - celda * 0.1, pe.y - celda * 0.3, celda * 0.5, celda * 0.6)
        E.halo(pe.x + celda * 0.4, pe.y, celda * 0.5, C.rosa, 0.7)
        E.texto('EMISOR', pe.x - celda * 0.2, pe.y - celda * 0.5, 13, '#aab4bf', 'center')
        var late = 0.6 + Math.sin(E.t * 5) * 0.4
        g.strokeStyle = bien ? C.verde : C.cian; g.lineWidth = 3
        g.beginPath(); g.arc(pr.x, pr.y, celda * 0.26, 0, TAU); g.stroke()
        E.halo(pr.x, pr.y, celda * (bien ? 1.4 : 0.7 * late + 0.3), bien ? C.verde : C.cian, bien ? 0.9 : 0.5)
        E.texto('RECEPTOR', pr.x + (pr.x > x0 + lado ? 0 : celda * 0.9), pr.y + (pr.x > x0 + lado ? celda * 0.5 : 0), 13, '#aab4bf', 'center')

        for (var i = 0; i < rejilla.length; i++) {
          var c = rejilla[i], p = px({ x: i % n, y: Math.floor(i / n) })
          if (c.tipo === 'muro') {
            g.fillStyle = '#3a4653'; g.fillRect(p.x - celda * 0.42, p.y - celda * 0.42, celda * 0.84, celda * 0.84)
            g.strokeStyle = '#0b0e12'; g.lineWidth = 2; g.strokeRect(p.x - celda * 0.42, p.y - celda * 0.42, celda * 0.84, celda * 0.84)
          } else if (c.tipo === 'espejo') {
            c.giro = Math.max(0, c.giro - dt * 5)
            /* '/' sube hacia la derecha; '\' baja. El giro lo anima de uno a otro. */
            var ang = (c.estado === 0 ? -Math.PI / 4 : Math.PI / 4) + (c.estado === 0 ? 1 : -1) * c.giro * Math.PI / 2
            var lx = Math.cos(ang) * celda * 0.36, ly = Math.sin(ang) * celda * 0.36
            g.fillStyle = 'rgba(255,255,255,0.05)'
            g.beginPath(); g.arc(p.x, p.y, celda * 0.4, 0, TAU); g.fill()
            ;(function (p, lx, ly, toca) {
              E.neon(function (g) { g.moveTo(p.x - lx, p.y - ly); g.lineTo(p.x + lx, p.y + ly) }, toca ? '#ffffff' : '#9fb6c9', 3, toca ? 1 : 0.6)
            })(p, lx, ly, r.tocados.indexOf(i) !== -1)
          }
        }

        /* el rayo */
        var pts = r.puntos.map(px)
        E.neon(function (g) {
          g.moveTo(pts[0].x + celda * 0.4, pts[0].y)
          for (var k = 1; k < pts.length; k++) g.lineTo(pts[k].x, pts[k].y)
        }, bien ? C.verde : C.rosa, 2.6)
        for (var q = 1; q < pts.length - 1; q++) {
          E.halo(pts[q].x, pts[q].y, celda * 0.35, '#ffffff', 0.5)
          if (Math.random() < 0.25) E.chispas(pts[q].x, pts[q].y, 1, { color: bien ? C.verde : C.rosa, fuerza: 90, gravedad: 0, dura: 0.35 })
        }
        var ultimo = r.puntos[r.puntos.length - 1]
        if (ultimo.choca) E.chispas(pts[pts.length - 1].x, pts[pts.length - 1].y, 2, { color: C.ambar, fuerza: 140, dura: 0.4 })

        if (maxGiros) E.texto('GIROS ' + Math.max(0, maxGiros - giros), E.W - 20, 26, 20, C.blanco, 'right')

        if (final > 0) {
          final += dt
          E.chispas(pr.x, pr.y, 4, { color: C.verde, fuerza: 260, gravedad: 0 })
          if (final > 0.9) { E.cerrar(dt); ctx.ganar(); return }
        }
        E.cerrar(dt)
      })
    },
  })
})()
