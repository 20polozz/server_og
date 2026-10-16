/* LOS MINIJUEGOS NUEVOS · segunda tanda, la red
 *   tunel      esquivar cortafuegos     circuito   girar piezas, dar corriente
 *   ritmo      notas que caen           inyeccion  teclear codigos que caen
 * Todos son «grandes»: pantalla al centro, pintados en lienzo con fx.js.
 */
(function () {
  'use strict'

  var MJ = window.OrigenMJ
  var U = MJ.util
  var C = MJ.fx.COLOR
  var TAU = Math.PI * 2

  function difAngulo(a, b) { return Math.abs(((a - b) % 360 + 540) % 360 - 180) }

  /* ═══ TUNEL ═══════════════════════════════════════════════════════════
     cfg: muros, velocidad, hueco (grados), fallos, tiempo */
  MJ.registrar('tunel', {
    titulo: 'Túnel de datos',
    grande: true,
    ayuda: 'Gira alrededor del túnel con **A**/**D** (o el **RATÓN**) y pasa por el **HUECO** de cada cortafuegos.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var total = U.tope(Math.round(cfg.muros || 12), 3, 60)
      var vel = Math.max(0.3, Number(cfg.velocidad) || 1)
      var hueco = U.tope(Number(cfg.hueco) || 80, 25, 200)
      var E = MJ.fx.escenario(ctx)
      var cx = E.W / 2, cy = E.H / 2
      var R = Math.min(E.W, E.H) * 0.46

      var nave = 90           // grados; 90 = abajo
      var conRaton = false
      var muros = [], creados = 0, pasados = 0, ultimoHueco = 90
      var crono = 0.6, final = 0
      var estrellas = []
      for (var i = 0; i < 70; i++) estrellas.push({ a: Math.random() * TAU, z: Math.random() })

      /* de profundidad (1 lejos .. 0 encima) a radio en pantalla */
      function radio(z) { return R * 0.09 / (z * 0.95 + 0.09) }

      ctx.escuchar(E.nodo, 'mousemove', function (e) {
        var p = E.raton(e)
        if (Math.abs(p.x - cx) + Math.abs(p.y - cy) < 12) return
        conRaton = true
        nave = (Math.atan2(p.y - cy, p.x - cx) * 180 / Math.PI + 360) % 360
      })

      ctx.fotograma(function (dt) {
        var g = E.g
        E.abrir(dt, false)

        var mueve = (ctx.pulsada('KeyD') || ctx.pulsada('ArrowRight') ? 1 : 0) - (ctx.pulsada('KeyA') || ctx.pulsada('ArrowLeft') ? 1 : 0)
        if (mueve) { conRaton = false; nave = (nave - mueve * 250 * dt + 360) % 360 }

        /* estrellas: rayas que salen del centro */
        g.globalCompositeOperation = 'lighter'
        for (var s = 0; s < estrellas.length; s++) {
          var st = estrellas[s]
          st.z -= dt * 0.55 * vel
          if (st.z <= 0.02) { st.z = 1; st.a = Math.random() * TAU }
          var r0 = radio(st.z) * 1.5, r1 = radio(st.z + 0.04) * 1.5
          g.strokeStyle = C.cian; g.globalAlpha = (1 - st.z) * 0.5; g.lineWidth = 1.2
          g.beginPath(); g.moveTo(cx + Math.cos(st.a) * r0, cy + Math.sin(st.a) * r0); g.lineTo(cx + Math.cos(st.a) * r1, cy + Math.sin(st.a) * r1); g.stroke()
        }
        g.globalAlpha = 1
        g.globalCompositeOperation = 'source-over'

        /* las costillas del tunel */
        /* los ocho largueros, del fondo a la boca */
        g.strokeStyle = 'rgba(53,224,255,0.16)'; g.lineWidth = 1
        g.beginPath()
        for (var lg = 0; lg < 8; lg++) { var al = lg / 8 * TAU + Math.PI / 8; g.moveTo(cx + Math.cos(al) * radio(1), cy + Math.sin(al) * radio(1)); g.lineTo(cx + Math.cos(al) * radio(0) * 1.3, cy + Math.sin(al) * radio(0) * 1.3) }
        g.stroke()
        for (var k = 0; k < 14; k++) {
          var z = ((k / 14) - (E.t * 0.42 * vel) % (1 / 14) + 1) % 1
          var rr = radio(z)
          g.strokeStyle = 'rgba(53,224,255,' + (0.06 + (1 - z) * (1 - z) * 0.5).toFixed(3) + ')'
          g.lineWidth = 1 + (1 - z) * 2.5
          g.beginPath()
          for (var v = 0; v <= 8; v++) { var av = v / 8 * TAU + Math.PI / 8; if (v === 0) g.moveTo(cx + Math.cos(av) * rr, cy + Math.sin(av) * rr); else g.lineTo(cx + Math.cos(av) * rr, cy + Math.sin(av) * rr) }
          g.stroke()
        }

        /* nacen muros */
        if (final === 0) {
          crono -= dt
          if (crono <= 0 && creados < total) {
            /* el hueco siguiente cae a una distancia que da tiempo a recorrer */
            ultimoHueco = (ultimoHueco + U.azar(50, 140) * (Math.random() < 0.5 ? -1 : 1) + 360) % 360
            muros.push({ z: 1, hueco: ultimoHueco, visto: false })
            creados++
            crono = 1.55 / vel
          }
        }

        for (var m = muros.length - 1; m >= 0; m--) {
          var w = muros[m]
          w.z -= dt * 0.42 * vel
          var rw = radio(Math.max(0, w.z))
          var a0 = (w.hueco + hueco / 2) * Math.PI / 180, a1 = (w.hueco - hueco / 2 + 360) * Math.PI / 180
          var cerca = 1 - U.tope(w.z, 0, 1)
          /* el muro tiene cuerpo: una corona translucida, y el canto en neon */
          g.save()
          g.globalCompositeOperation = 'lighter'
          g.globalAlpha = 0.1 + cerca * 0.28
          g.fillStyle = C.rosa
          g.beginPath(); g.arc(cx, cy, rw, a0, a1); g.arc(cx, cy, rw * 0.72, a1, a0, true); g.closePath(); g.fill()
          g.restore()
          ;(function (rw, a0, a1, cerca) {
            E.neon(function (g) { g.arc(cx, cy, rw, a0, a1) }, C.rosa, 2 + cerca * 5, 0.35 + cerca * 0.65)
            E.neon(function (g) { g.arc(cx, cy, rw * 0.72, a0, a1) }, C.rosa, 1 + cerca * 2, 0.2 + cerca * 0.5)
          })(rw, a0, a1, cerca)

          if (w.z <= 0.045 && !w.visto) {
            w.visto = true
            pasados++
            ctx.progreso(pasados, total)
            if (difAngulo(nave, w.hueco) <= hueco / 2) {
              ctx.sonido('tic')
              E.chispas(cx + Math.cos(nave * Math.PI / 180) * R * 0.86, cy + Math.sin(nave * Math.PI / 180) * R * 0.86, 10, { color: C.cian, fuerza: 200, gravedad: 0 })
            } else {
              E.sacudir(16)
              E.destellar(C.rojo, 0.4)
              E.chispas(cx + Math.cos(nave * Math.PI / 180) * R * 0.86, cy + Math.sin(nave * Math.PI / 180) * R * 0.86, 50, { color: C.rosa, fuerza: 380, gravedad: 0 })
              if (ctx.fallo()) { E.cerrar(dt); return }
            }
            if (pasados >= total) { final = 0.001; ctx.acierto() }
          }
          if (w.z < -0.06) muros.splice(m, 1)
        }

        /* la nave */
        var an = nave * Math.PI / 180
        var nx = cx + Math.cos(an) * R * 0.86, ny = cy + Math.sin(an) * R * 0.86
        E.halo(nx, ny, 34, C.cian, 0.7)
        g.save(); g.translate(nx, ny); g.rotate(an + Math.PI)
        g.fillStyle = '#eafcff'
        g.beginPath(); g.moveTo(16, 0); g.lineTo(-10, -10); g.lineTo(-4, 0); g.lineTo(-10, 10); g.closePath(); g.fill()
        g.restore()
        E.fuego(nx + Math.cos(an) * 8, ny + Math.sin(an) * 8, 1, 4)

        /* el proximo hueco, avisado con una marca en el borde */
        var prox = null
        for (var q = 0; q < muros.length; q++) if (!muros[q].visto && (!prox || muros[q].z < prox.z)) prox = muros[q]
        if (prox) {
          var ap = prox.hueco * Math.PI / 180
          E.neon(function (g) { g.arc(cx, cy, R * 0.98, ap - hueco * Math.PI / 360, ap + hueco * Math.PI / 360) }, C.verde, 2.5, 0.35 + (1 - prox.z) * 0.65)
        }

        if (final > 0) {
          final += dt
          E.halo(cx, cy, R * final * 2.2, '#ffffff', Math.min(0.9, final))
          if (final > 0.9) { E.cerrar(dt); ctx.ganar(); return }
        }
        E.cerrar(dt)
      })

      ctx.progreso(0, total)
    },
  })

  /* ═══ CIRCUITO ════════════════════════════════════════════════════════
     cfg: tamano, chips, senuelos, tiempo */
  MJ.registrar('circuito', {
    titulo: 'Puentear el circuito',
    grande: true,
    ayuda: '**CLIC** gira una pieza (clic derecho, al revés). Lleva la corriente desde la **BATERÍA** hasta todos los **CHIPS**.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var n = U.tope(Math.round(cfg.tamano || 5), 3, 8)
      var chips = U.tope(Math.round(cfg.chips || 1), 1, 4)
      var senuelos = U.tope(Math.round(cfg.senuelos || 0), 0, 14)
      var E = MJ.fx.escenario(ctx)
      var lado = Math.min(E.W * 0.62, E.H * 0.9)
      var celda = lado / n, x0 = (E.W - lado) / 2, y0 = (E.H - lado) / 2

      /* Bits de conexion: 1 arriba, 2 derecha, 4 abajo, 8 izquierda. */
      var DX = [0, 1, 0, -1], DY = [-1, 0, 1, 0]
      function girar(m) { return ((m << 1) | (m >> 3)) & 15 }
      function opuesto(d) { return (d + 2) % 4 }

      var piezas, fuente, destinos, final = 0

      function generar() {
        for (var intento = 0; intento < 200; intento++) {
          piezas = []
          for (var i = 0; i < n * n; i++) piezas.push({ meta: 0, mascara: 0, anim: 0, chip: false, fuente: false })
          fuente = U.entero(0, n - 1) * n            // columna izquierda
          piezas[fuente].fuente = true
          destinos = []
          var ok = true
          /* Si no caben tantos chips en la placa, se va rebajando en vez de no arrancar. */
          var pideChips = Math.max(1, chips - Math.floor(intento / 50))
          for (var c = 0; c < pideChips && ok; c++) {
            /* un paseo desde algun punto ya cableado hasta una casilla lejana libre */
            var cableadas = piezas.map(function (p, i) { return p.meta || p.fuente ? i : -1 }).filter(function (i) { return i >= 0 })
            var desde = c === 0 ? fuente : cableadas[U.entero(0, cableadas.length - 1)]
            var pos = desde, pasos = 0, largo = U.entero(n, n * 2)
            while (pasos < largo) {
              var opciones = []
              for (var d = 0; d < 4; d++) {
                var x = pos % n + DX[d], y = Math.floor(pos / n) + DY[d]
                if (x < 0 || y < 0 || x >= n || y >= n) continue
                var j = y * n + x
                if (piezas[j].meta || piezas[j].fuente || piezas[j].chip) continue
                opciones.push({ d: d, j: j })
              }
              if (!opciones.length) break
              var o = opciones[U.entero(0, opciones.length - 1)]
              piezas[pos].meta |= 1 << o.d
              piezas[o.j].meta |= 1 << opuesto(o.d)
              pos = o.j
              pasos++
            }
            if (pasos < 2 || pos === desde) { ok = false; break }
            piezas[pos].chip = true
            destinos.push(pos)
          }
          if (!ok) continue
          /* señuelos: piezas sueltas que no llevan a ningun lado */
          var libres = U.barajar(piezas.map(function (p, i) { return !p.meta && !p.fuente ? i : -1 }).filter(function (i) { return i >= 0 }))
          libres.slice(0, senuelos).forEach(function (i) { piezas[i].meta = [3, 5, 6, 7, 9, 10, 12][U.entero(0, 6)]; piezas[i].senuelo = true })
          /* desordenar */
          for (var v = 0; v < 20; v++) {
            piezas.forEach(function (p) { p.mascara = p.meta; for (var g = U.entero(0, 3); g > 0; g--) p.mascara = girar(p.mascara) })
            if (!completo(corriente())) return true
          }
        }
        return false
      }

      function corriente() {
        var con = {}, cola = [fuente]
        con[fuente] = true
        while (cola.length) {
          var i = cola.pop()
          for (var d = 0; d < 4; d++) {
            if (!(piezas[i].mascara & (1 << d))) continue
            var x = i % n + DX[d], y = Math.floor(i / n) + DY[d]
            if (x < 0 || y < 0 || x >= n || y >= n) continue
            var j = y * n + x
            if (con[j] || !(piezas[j].mascara & (1 << opuesto(d)))) continue
            con[j] = true
            cola.push(j)
          }
        }
        return con
      }

      function completo(con) { return destinos.every(function (d) { return con[d] }) }

      function rotar(i, alReves) {
        if (!ctx.viva() || final > 0) return
        var p = piezas[i]
        if (!p || !p.mascara) return
        p.mascara = alReves ? girar(girar(girar(p.mascara))) : girar(p.mascara)
        p.anim = alReves ? -1 : 1
        ctx.sonido('clic')
        if (completo(corriente())) { final = 0.001; ctx.acierto(); E.destellar(C.verde, 0.3) }
      }

      if (!generar()) { ctx.perder(); return }

      function cual(e) {
        var p = E.raton(e)
        var cxn = Math.floor((p.x - x0) / celda), cyn = Math.floor((p.y - y0) / celda)
        return cxn >= 0 && cyn >= 0 && cxn < n && cyn < n ? cyn * n + cxn : -1
      }
      ctx.escuchar(E.nodo, 'mousedown', function (e) { var i = cual(e); if (i >= 0) rotar(i, e.button === 2) })
      ctx.escuchar(E.nodo, 'contextmenu', function (e) { e.preventDefault() })

      ctx.fotograma(function (dt) {
        var g = E.g
        E.abrir(dt)
        g.fillStyle = '#0b1a14'
        g.fillRect(x0 - 8, y0 - 8, lado + 16, lado + 16)
        g.strokeStyle = '#1f5a45'; g.lineWidth = 2; g.strokeRect(x0 - 8, y0 - 8, lado + 16, lado + 16)

        var con = corriente()
        var hechos = destinos.filter(function (d) { return con[d] }).length
        ctx.progreso(hechos, destinos.length)

        for (var i = 0; i < piezas.length; i++) {
          var p = piezas[i]
          var px = x0 + (i % n + 0.5) * celda, py = y0 + (Math.floor(i / n) + 0.5) * celda
          g.strokeStyle = 'rgba(60,230,164,0.08)'; g.lineWidth = 1
          g.strokeRect(px - celda / 2 + 2, py - celda / 2 + 2, celda - 4, celda - 4)
          if (!p.mascara) continue
          p.anim *= Math.pow(0.0006, dt)
          var viva = con[i] === true
          g.save()
          g.translate(px, py)
          g.rotate(-p.anim * Math.PI / 2)
          ;(function (p, viva) {
            var traza = function (g) {
              for (var d = 0; d < 4; d++) if (p.mascara & (1 << d)) { g.moveTo(0, 0); g.lineTo(DX[d] * celda / 2, DY[d] * celda / 2) }
            }
            if (viva) {
              E.neon(traza, final > 0 ? C.verde : C.cian, celda * 0.09)
              /* la corriente corre: rayitas blancas que avanzan */
              g.setLineDash([celda * 0.12, celda * 0.3]); g.lineDashOffset = -E.t * celda * 1.6
              g.strokeStyle = '#ffffff'; g.lineWidth = celda * 0.045; g.lineCap = 'round'
              g.beginPath(); traza(g); g.stroke()
              g.setLineDash([])
            } else {
              g.strokeStyle = '#3d5148'; g.lineWidth = celda * 0.1; g.lineCap = 'round'
              g.beginPath(); traza(g); g.stroke()
            }
          })(p, viva)
          g.fillStyle = viva ? '#eafff6' : '#55695f'
          g.beginPath(); g.arc(0, 0, celda * 0.085, 0, TAU); g.fill()
          g.restore()

          if (p.fuente) {
            g.fillStyle = '#1a222b'; g.fillRect(px - celda * 0.3, py - celda * 0.22, celda * 0.6, celda * 0.44)
            g.strokeStyle = C.ambar; g.lineWidth = 2; g.strokeRect(px - celda * 0.3, py - celda * 0.22, celda * 0.6, celda * 0.44)
            E.texto('⚡', px, py + 1, celda * 0.3, C.ambar)
            E.halo(px, py, celda * 0.7, C.ambar, 0.35 + Math.sin(E.t * 6) * 0.1)
          }
          if (p.chip) {
            var on = con[i] === true
            g.fillStyle = on ? '#0f3d2c' : '#1a222b'
            g.fillRect(px - celda * 0.27, py - celda * 0.27, celda * 0.54, celda * 0.54)
            g.strokeStyle = on ? C.verde : '#6d7b88'; g.lineWidth = 2
            g.strokeRect(px - celda * 0.27, py - celda * 0.27, celda * 0.54, celda * 0.54)
            for (var pata = -1; pata <= 1; pata++) {
              g.beginPath()
              g.moveTo(px + pata * celda * 0.16, py - celda * 0.27); g.lineTo(px + pata * celda * 0.16, py - celda * 0.36)
              g.moveTo(px + pata * celda * 0.16, py + celda * 0.27); g.lineTo(px + pata * celda * 0.16, py + celda * 0.36)
              g.stroke()
            }
            if (on) { E.halo(px, py, celda * 0.9, C.verde, 0.6); if (Math.random() < 0.2) E.chispas(px, py, 1, { color: C.verde, fuerza: 90, gravedad: 0, dura: 0.4 }) }
          }
        }

        if (final > 0) {
          final += dt
          if (final > 1) { E.cerrar(dt); ctx.ganar(); return }
        }
        E.cerrar(dt)
      })
    },
  })

  /* ═══ RITMO ═══════════════════════════════════════════════════════════
     cfg: notas, velocidad, ritmo (notas/s), margen (ms), fallos, tiempo */
  MJ.registrar('ritmo', {
    titulo: 'Sincronizar paquetes',
    grande: true,
    ayuda: 'Pulsa **A** **S** **D** **F** cuando cada paquete cruce la **LÍNEA**. Los que se escapan cuentan como fallo.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var total = U.tope(Math.round(cfg.notas || 20), 4, 120)
      var vel = Math.max(0.3, Number(cfg.velocidad) || 1)
      var cadencia = Math.max(0.4, Number(cfg.ritmo) || 2)
      var margen = U.tope(Number(cfg.margen) || 140, 40, 400) / 1000
      var E = MJ.fx.escenario(ctx)

      var TECLAS = ['KeyA', 'KeyS', 'KeyD', 'KeyF'], LETRAS = ['A', 'S', 'D', 'F']
      var COLORES = [C.rosa, C.cian, C.verde, C.ambar]
      var anchoPista = Math.min(E.W * 0.6, E.H * 0.9)
      var x0 = (E.W - anchoPista) / 2, carril = anchoPista / 4
      var yLinea = E.H * 0.84
      var caida = 1.9 / vel            // segundos de arriba a la linea

      var notas = [], creadas = 0, resueltas = 0, crono = 0.8, reloj = 0
      var racha = 0, pulso = [0, 0, 0, 0], final = 0, ultimoCarril = -1

      function golpe(c) {
        if (!ctx.viva() || final > 0) return
        pulso[c] = 1
        var mejor = null
        for (var i = 0; i < notas.length; i++) {
          var nn = notas[i]
          if (nn.carril !== c || nn.hecha) continue
          var d = Math.abs(nn.cuando - reloj)
          if (d <= margen && (!mejor || d < Math.abs(mejor.cuando - reloj))) mejor = nn
        }
        if (!mejor) return           // pulsar al aire no castiga
        mejor.hecha = true
        resueltas++
        racha++
        ctx.tono(330 + c * 110, 0.09, 'triangle', 0, 0.8)
        E.chispas(x0 + (c + 0.5) * carril, yLinea, 22, { color: COLORES[c], fuerza: 300, gravedad: 200, angulo: -Math.PI / 2, abanico: 2.2 })
        ctx.progreso(resueltas, total)
        if (resueltas >= total) { final = 0.001; ctx.acierto() }
      }

      ctx.tecla(function (codigo, abajo, e, repetida) {
        if (!abajo || repetida) return
        var c = TECLAS.indexOf(codigo)
        if (c === -1) c = ['Digit1', 'Digit2', 'Digit3', 'Digit4'].indexOf(codigo)
        if (c >= 0) golpe(c)
      })
      ctx.escuchar(E.nodo, 'mousedown', function (e) {
        var p = E.raton(e)
        var c = Math.floor((p.x - x0) / carril)
        if (c >= 0 && c < 4) golpe(c)
      })

      ctx.fotograma(function (dt) {
        var g = E.g
        reloj += dt
        E.abrir(dt, false)

        if (final === 0) {
          crono -= dt
          if (crono <= 0 && creadas < total) {
            var c
            do { c = U.entero(0, 3) } while (c === ultimoCarril && Math.random() < 0.7)
            ultimoCarril = c
            notas.push({ carril: c, cuando: reloj + caida, hecha: false, perdida: false })
            creadas++
            crono = (1 / cadencia) * U.azar(0.8, 1.2)
          }
        }

        /* la pista, en perspectiva */
        var lateFondo = 0.5 + Math.sin(E.t * cadencia * Math.PI) * 0.5
        for (var k = 0; k < 4; k++) {
          pulso[k] = Math.max(0, pulso[k] - dt * 5)
          var xa = x0 + k * carril
          var grad = g.createLinearGradient(0, 0, 0, E.H)
          grad.addColorStop(0, 'rgba(0,0,0,0)')
          grad.addColorStop(1, COLORES[k])
          g.globalAlpha = 0.07 + pulso[k] * 0.3 + lateFondo * 0.025
          g.fillStyle = grad
          g.fillRect(xa + 2, 0, carril - 4, E.H)
          g.globalAlpha = 1
          g.strokeStyle = 'rgba(255,255,255,0.08)'; g.lineWidth = 1
          g.beginPath(); g.moveTo(xa, 0); g.lineTo(xa, E.H); g.stroke()
        }
        g.beginPath(); g.moveTo(x0 + anchoPista, 0); g.lineTo(x0 + anchoPista, E.H); g.stroke()

        E.neon(function (g) { g.moveTo(x0, yLinea); g.lineTo(x0 + anchoPista, yLinea) }, '#ffffff', 2, 0.8)
        for (var t = 0; t < 4; t++) {
          var tx = x0 + (t + 0.5) * carril
          g.strokeStyle = COLORES[t]; g.lineWidth = 2 + pulso[t] * 3
          g.beginPath(); g.arc(tx, yLinea, carril * 0.26 * (1 + pulso[t] * 0.2), 0, TAU); g.stroke()
          E.texto(LETRAS[t], tx, yLinea + E.H * 0.1, E.H * 0.05, COLORES[t])
        }

        for (var i = notas.length - 1; i >= 0; i--) {
          var nn = notas[i]
          var falta = nn.cuando - reloj
          if (!nn.hecha && !nn.perdida && falta < -margen) {
            nn.perdida = true
            resueltas++
            racha = 0
            ctx.progreso(resueltas, total)
            E.sacudir(7)
            E.destellar(C.rojo, 0.18)
            if (ctx.fallo()) { E.cerrar(dt); return }
            if (resueltas >= total) { final = 0.001; ctx.acierto() }
          }
          if (nn.hecha || falta < -0.4) { notas.splice(i, 1); continue }
          var y = yLinea - (falta / caida) * yLinea
          var nx = x0 + (nn.carril + 0.5) * carril
          var tam = carril * 0.2
          E.halo(nx, y, tam * 2.6, COLORES[nn.carril], nn.perdida ? 0.15 : 0.55)
          g.fillStyle = nn.perdida ? '#55606b' : COLORES[nn.carril]
          g.beginPath(); g.moveTo(nx, y - tam); g.lineTo(nx + tam, y); g.lineTo(nx, y + tam); g.lineTo(nx - tam, y); g.closePath(); g.fill()
          g.fillStyle = 'rgba(255,255,255,0.85)'
          g.beginPath(); g.arc(nx, y, tam * 0.3, 0, TAU); g.fill()
        }

        if (racha >= 3) E.texto('x' + racha, x0 + anchoPista + (E.W - x0 - anchoPista) / 2, E.H * 0.2, E.H * 0.09, C.ambar)

        /* a los lados, un ecualizador que sigue el ritmo */
        var barras = 9, anchoLado = x0 - 30
        for (var lado2 = 0; lado2 < 2; lado2++) {
          for (var b = 0; b < barras; b++) {
            var alto = E.H * (0.08 + 0.32 * Math.abs(Math.sin(E.t * (2 + b * 0.37) + b * 1.7 + lado2)) * (0.5 + lateFondo * 0.5))
            var bx = lado2 === 0 ? 15 + b * (anchoLado / barras) : x0 + anchoPista + 15 + b * (anchoLado / barras)
            g.globalAlpha = 0.22
            g.fillStyle = COLORES[(b + lado2) % 4]
            g.fillRect(bx, E.H - alto, anchoLado / barras - 5, alto)
          }
        }
        g.globalAlpha = 1

        if (final > 0) {
          final += dt
          for (var f = 0; f < 4; f++) if (Math.random() < 0.5) E.chispas(x0 + (f + 0.5) * carril, yLinea, 3, { color: COLORES[f], fuerza: 420, angulo: -Math.PI / 2, abanico: 1.2 })
          if (final > 0.9) { E.cerrar(dt); ctx.ganar(); return }
        }
        E.cerrar(dt)
      })

      ctx.progreso(0, total)
    },
  })

  /* ═══ INYECCION ═══════════════════════════════════════════════════════
     cfg: codigos, longitud, velocidad, fallos, tiempo */
  MJ.registrar('inyeccion', {
    titulo: 'Inyección de código',
    grande: true,
    ayuda: '**TECLEA** cada código antes de que llegue abajo (letras A–F y números). Los que tocan el cortafuegos son un fallo.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var total = U.tope(Math.round(cfg.codigos || 9), 2, 60)
      var largo = U.tope(Math.round(cfg.longitud || 4), 2, 8)
      var vel = Math.max(0.3, Number(cfg.velocidad) || 1)
      var E = MJ.fx.escenario(ctx)
      var HEX = '0123456789ABCDEF'
      var yMuro = E.H * 0.9
      var caida = 9.5 / vel

      var codigos = [], creados = 0, resueltos = 0, crono = 0.5, fijado = null, final = 0
      var lluvia = []
      var cols = Math.floor(E.W / 22)
      for (var i = 0; i < cols; i++) lluvia.push({ y: Math.random() * E.H, v: 60 + Math.random() * 140, letras: [] })

      function nuevoCodigo() {
        var txt, intentos = 0
        do {
          txt = ''
          for (var k = 0; k < largo; k++) txt += HEX[U.entero(0, 15)]
          intentos++
        } while (intentos < 20 && codigos.some(function (c) { return !c.hecho && c.txt[0] === txt[0] }))
        codigos.push({ txt: txt, escrito: 0, x: U.azar(E.W * 0.12, E.W * 0.88), y: -20, hecho: false, muere: 0 })
        creados++
      }

      function teclear(ch) {
        if (!ctx.viva() || final > 0) return
        ch = String(ch).toUpperCase()
        if (HEX.indexOf(ch) === -1) return
        if (!fijado || fijado.hecho) {
          fijado = null
          codigos.forEach(function (c) { if (!c.hecho && c.txt[0] === ch && (!fijado || c.y > fijado.y)) fijado = c })
          if (!fijado) { E.destellar(C.rojo, 0.08); return }
        }
        if (fijado.txt[fijado.escrito] !== ch) { E.destellar(C.rojo, 0.08); ctx.tono(140, 0.06, 'square', 0, 0.4); return }
        fijado.escrito++
        ctx.sonido('tic')
        if (fijado.escrito >= fijado.txt.length) {
          fijado.hecho = true
          fijado.muere = 0.001
          resueltos++
          ctx.progreso(resueltos, total)
          ctx.tono(880, 0.12, 'triangle')
          E.chispas(fijado.x, fijado.y, 40, { color: C.verde, fuerza: 320, gravedad: 120 })
          E.sacudir(5)
          fijado = null
          if (resueltos >= total) { final = 0.001; ctx.acierto() }
        }
      }

      ctx.tecla(function (codigo, abajo, e) {
        if (!abajo) return
        if (e && e.key && e.key.length === 1) teclear(e.key)
        else {
          var m = /^(?:Digit|Numpad)(\d)$/.exec(codigo) || /^Key([A-F])$/.exec(codigo)
          if (m) teclear(m[1])
        }
      })

      ctx.fotograma(function (dt) {
        var g = E.g
        E.abrir(dt, false)

        /* lluvia de fondo */
        g.font = '16px "Share Tech Mono", Consolas, monospace'
        g.textAlign = 'center'
        for (var i = 0; i < lluvia.length; i++) {
          var l = lluvia[i]
          l.y += l.v * dt
          if (l.y > E.H + 200) { l.y = -Math.random() * 200; l.v = 60 + Math.random() * 140 }
          for (var k = 0; k < 9; k++) {
            g.fillStyle = k === 0 ? 'rgba(200,255,225,0.55)' : 'rgba(60,230,164,' + (0.4 - k * 0.042).toFixed(3) + ')'
            g.fillText(HEX[(i * 7 + k * 3 + Math.floor(l.y / 18)) % 16], i * 22 + 11, l.y - k * 18)
          }
        }

        if (final === 0) {
          crono -= dt
          if (crono <= 0 && creados < total) { nuevoCodigo(); crono = (2.3 / vel) * U.azar(0.8, 1.2) }
        }

        /* el cortafuegos */
        E.neon(function (g) { g.moveTo(0, yMuro); g.lineTo(E.W, yMuro) }, C.rosa, 2.5, 0.7 + Math.sin(E.t * 5) * 0.3)
        E.texto('CORTAFUEGOS', E.W * 0.12, yMuro + E.H * 0.05, E.H * 0.035, C.rosa)
        /* el cañon desde el que salen los rayos */
        g.fillStyle = '#1a222b'
        g.beginPath(); g.moveTo(E.W / 2 - 26, E.H); g.lineTo(E.W / 2 - 12, yMuro - 8); g.lineTo(E.W / 2 + 12, yMuro - 8); g.lineTo(E.W / 2 + 26, E.H); g.closePath(); g.fill()
        E.halo(E.W / 2, yMuro - 8, 30, C.verde, 0.5 + Math.sin(E.t * 8) * 0.2)

        for (var c = codigos.length - 1; c >= 0; c--) {
          var cod = codigos[c]
          if (cod.hecho) {
            cod.muere += dt
            if (cod.muere > 0.35) codigos.splice(c, 1)
            else {
              /* el rayo que lo revienta, desde abajo */
              ;(function (cod) { E.neon(function (g) { g.moveTo(E.W / 2, yMuro); g.lineTo(cod.x, cod.y) }, C.verde, 2, 1 - cod.muere / 0.35) })(cod)
            }
            continue
          }
          cod.y += (yMuro / caida) * dt
          if (cod.y >= yMuro) {
            codigos.splice(c, 1)
            if (fijado === cod) fijado = null
            resueltos++
            ctx.progreso(resueltos, total)
            E.sacudir(14)
            E.destellar(C.rojo, 0.35)
            E.chispas(cod.x, yMuro, 40, { color: C.rosa, fuerza: 300 })
            if (ctx.fallo()) { E.cerrar(dt); return }
            if (resueltos >= total) { final = 0.001; ctx.acierto() }
            continue
          }
          var tam = E.H * 0.05
          g.font = tam + 'px "Share Tech Mono", Consolas, monospace'
          var ancho = g.measureText(cod.txt).width + 22
          var mio = fijado === cod
          g.fillStyle = mio ? 'rgba(53,224,255,0.16)' : 'rgba(6,8,12,0.82)'
          g.fillRect(cod.x - ancho / 2, cod.y - tam * 0.75, ancho, tam * 1.5)
          g.strokeStyle = mio ? C.cian : 'rgba(255,255,255,0.35)'; g.lineWidth = mio ? 2 : 1
          g.strokeRect(cod.x - ancho / 2, cod.y - tam * 0.75, ancho, tam * 1.5)
          if (mio) E.halo(cod.x, cod.y, ancho * 0.8, C.cian, 0.25)
          /* letra a letra: lo escrito, en verde */
          g.textAlign = 'left'; g.textBaseline = 'middle'
          var xl = cod.x - ancho / 2 + 11
          for (var q = 0; q < cod.txt.length; q++) {
            g.fillStyle = q < cod.escrito ? C.verde : (q === cod.escrito && mio ? '#ffffff' : '#c9d2dc')
            g.fillText(cod.txt[q], xl, cod.y + 1)
            xl += g.measureText(cod.txt[q]).width
          }
          g.textAlign = 'center'
        }

        if (final > 0) {
          final += dt
          E.halo(E.W / 2, E.H / 2, E.H * final, C.verde, Math.min(0.5, final))
          if (final > 0.9) { E.cerrar(dt); ctx.ganar(); return }
        }
        E.cerrar(dt)
      })

      ctx.progreso(0, total)
    },
  })
})()
