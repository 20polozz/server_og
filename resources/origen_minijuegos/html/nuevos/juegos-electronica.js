/* LOS MINIJUEGOS NUEVOS · electronica y precision
 *   huella   clonar huella          clave   descifrar la clave
 *   senal    sintonizar la señal    corte   corte de precision
 */
(function () {
  'use strict'

  var MJ = window.OrigenMJ
  var U = MJ.util

  /* ═══ CLONAR HUELLA ═══════════════════════════════════════════════════
     cfg: rondas, piezas, opciones, parecido (0..0.9), fallos, tiempo

     La huella no es una imagen: es una funcion. Con los mismos numeros sale
     siempre el mismo dibujo, asi que un trozo se pinta calculando esa funcion
     solo en su recuadro, sin recortar nada. */
  function huellaAlAzar() {
    return {
      cx: U.azar(-0.25, 0.25), cy: U.azar(-0.3, 0.2),
      sx: U.azar(0.85, 1.35), sy: U.azar(0.95, 1.5),
      frec: U.azar(62, 80),
      k1: U.azar(0.04, 0.13), f1: U.azar(2, 6), p1: U.azar(0, 6.28),
      k2: U.azar(0.04, 0.13), f2: U.azar(2, 6), p2: U.azar(0, 6.28),
      k3: U.azar(-0.45, 0.45), giro: U.azar(-0.6, 0.6),
      /* Por debajo del nucleo las crestas se aplanan, como en una huella de
         verdad: arriba son arcos, abajo casi rectas. */
      bajo: U.azar(0.2, 0.6),
    }
  }

  function mezclar(a, b, t) {
    var r = {}
    for (var k in a) r[k] = a[k] + (b[k] - a[k]) * t
    return r
  }

  function tinta(h, x, y) {
    var c = Math.cos(h.giro), s = Math.sin(h.giro)
    var u0 = x - h.cx, w0 = y - h.cy
    var u = (u0 * c - w0 * s) * h.sx
    var w = (u0 * s + w0 * c) * h.sy
    if (w > 0) w *= h.bajo
    var d = Math.sqrt(u * u + w * w) + h.k1 * Math.sin(u * h.f1 + h.p1) + h.k2 * Math.sin(w * h.f2 + h.p2) + h.k3 * u * w
    return Math.sin(d * h.frec)
  }

  /* Pinta en `lienzo` el recuadro [x0,x1]x[y0,y1] de la huella (coordenadas -1..1). */
  function pintarHuella(lienzo, h, x0, y0, x1, y1, color, conForma) {
    var g = lienzo.getContext('2d')
    var W = lienzo.width, H = lienzo.height
    var img = g.createImageData(W, H)
    var datos = img.data
    for (var j = 0; j < H; j++) {
      var y = y0 + (y1 - y0) * (j + 0.5) / H
      for (var i = 0; i < W; i++) {
        var x = x0 + (x1 - x0) * (i + 0.5) / W
        var v = tinta(h, x, y)
        var alfa = v > 0.15 ? 255 : (v > -0.05 ? Math.round((v + 0.05) / 0.2 * 255) : 0)
        if (conForma && alfa) {
          /* El borde de la yema: un ovalo que se deshace hacia fuera. */
          var borde = (x * x) / 0.72 + (y * y) / 0.94
          if (borde > 1) alfa = 0
          else if (borde > 0.82) alfa = Math.round(alfa * (1 - borde) / 0.18)
        }
        var n = (j * W + i) * 4
        datos[n] = color[0]; datos[n + 1] = color[1]; datos[n + 2] = color[2]; datos[n + 3] = alfa
      }
    }
    g.putImageData(img, 0, 0)
  }

  function aRGB(texto, porDefecto) {
    var t = (texto || '').trim()
    // Una tinta en tres cifras ('#fff') se expande: sin esto se pintaba con el marron por defecto.
    if (/^#[0-9a-f]{3}$/i.test(t)) t = '#' + t[1] + t[1] + t[2] + t[2] + t[3] + t[3]
    var m = /^#([0-9a-f]{6})$/i.exec(t)
    if (!m) return porDefecto
    var n = parseInt(m[1], 16)
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
  }

  MJ.registrar('huella', {
    titulo: 'Clonar huella',
    ayuda: 'Marca los trozos que son de **ESTA** huella (al pasar por uno se ve de dónde sale) y pulsa **COMPROBAR**.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var rondas = U.tope(Math.round(cfg.rondas || 1), 1, 6)
      var opciones = U.tope(Math.round(cfg.opciones || 8), 3, 12)
      var buenas = U.tope(Math.round(cfg.piezas || 3), 1, opciones - 1)
      var parecido = U.tope(Number(cfg.parecido) || 0, 0, 0.92)
      var color = aRGB(U.color('--arc-ink', '#0b0b0d'), [11, 11, 13])

      var ronda = 0
      var trozos = []
      var marcados = 0

      var cuerpo = ctx.el('div', 'hl-cuerpo')
      ctx.zona.appendChild(cuerpo)

      var izquierda = ctx.el('div', 'hl-muestra')
      var lienzoMuestra = document.createElement('canvas')
      lienzoMuestra.width = 230
      lienzoMuestra.height = 300
      lienzoMuestra.className = 'hl-lienzo'
      var lupa = ctx.el('div', 'hl-lupa')
      izquierda.appendChild(lienzoMuestra)
      izquierda.appendChild(lupa)
      cuerpo.appendChild(izquierda)

      var derecha = ctx.el('div', 'hl-derecha')
      var rejilla = ctx.el('div', 'hl-rejilla')
      rejilla.style.gridTemplateColumns = 'repeat(' + (opciones <= 6 ? 2 : (opciones <= 9 ? 3 : 4)) + ', 1fr)'
      var boton = ctx.el('button', 'mj-boton', 'COMPROBAR')
      boton.type = 'button'
      derecha.appendChild(rejilla)
      derecha.appendChild(boton)
      cuerpo.appendChild(derecha)

      /* La muestra enseña x en ±0.85 e y en ±1.1; los trozos salen de una
         rejilla de 4x5 sobre el centro, donde hay dibujo de sobra. */
      var VX = 0.85, VY = 1.1
      var COLS = 4, FILAS = 5, LADO = 0.3

      function nuevaRonda() {
        var huella = huellaAlAzar()
        pintarHuella(lienzoMuestra, huella, -VX, -VY, VX, VY, color, true)

        var celdas = []
        for (var f = 0; f < FILAS; f++) for (var c = 0; c < COLS; c++) celdas.push({ c: c, f: f })
        celdas = U.barajar(celdas).slice(0, opciones)

        rejilla.innerHTML = ''
        trozos = []
        marcados = 0
        lupa.style.display = 'none'

        var cuales = U.barajar(celdas.map(function (_, i) { return i })).slice(0, buenas)

        celdas.forEach(function (celda, i) {
          var esBuena = cuales.indexOf(i) !== -1
          var x0 = -COLS * LADO / 2 + celda.c * LADO
          var y0 = -FILAS * LADO / 2 + celda.f * LADO
          var de = esBuena ? huella : mezclar(huellaAlAzar(), huella, parecido)

          var caja = ctx.el('button', 'hl-trozo')
          caja.type = 'button'
          var lienzo = document.createElement('canvas')
          lienzo.width = 96
          lienzo.height = 96
          pintarHuella(lienzo, de, x0, y0, x0 + LADO, y0 + LADO, color, false)
          caja.appendChild(lienzo)
          rejilla.appendChild(caja)

          var trozo = { caja: caja, buena: esBuena, marcado: false }
          trozos.push(trozo)

          caja.addEventListener('mouseenter', function () {
            lupa.style.display = 'block'
            lupa.style.left = ((x0 + VX) / (2 * VX) * 100) + '%'
            lupa.style.top = ((y0 + VY) / (2 * VY) * 100) + '%'
            lupa.style.width = (LADO / (2 * VX) * 100) + '%'
            lupa.style.height = (LADO / (2 * VY) * 100) + '%'
          })
          caja.addEventListener('mouseleave', function () { lupa.style.display = 'none' })
          caja.addEventListener('click', function () {
            if (!ctx.viva()) return
            if (!trozo.marcado && marcados >= buenas) return
            trozo.marcado = !trozo.marcado
            marcados += trozo.marcado ? 1 : -1
            caja.classList.toggle('hl-trozo--marcado', trozo.marcado)
            ctx.sonido('tic')
            alDia()
          })
        })
        alDia()
        ctx.progreso(ronda, rondas)
      }

      function alDia() {
        boton.disabled = marcados !== buenas
        boton.textContent = marcados === buenas ? 'COMPROBAR' : ('MARCA ' + (buenas - marcados) + ' MÁS')
      }

      function comprobar() {
        if (!ctx.viva() || marcados !== buenas) return
        var bien = trozos.every(function (t) { return t.marcado === t.buena })
        if (bien) {
          ronda++
          ctx.acierto()
          ctx.progreso(ronda, rondas)
          if (ronda >= rondas) { ctx.ganar(); return }
          nuevaRonda()
        } else if (!ctx.fallo()) {
          /* Huella nueva: probar combinaciones a ciegas no lleva a nada. */
          nuevaRonda()
        }
      }

      ctx.escuchar(boton, 'click', comprobar)
      ctx.tecla(function (codigo, abajo, e, repetida) {
        if (abajo && !repetida && (codigo === 'Enter' || codigo === 'Space')) comprobar()
      })

      nuevaRonda()
    },
  })

  /* ═══ DESCIFRAR LA CLAVE ══════════════════════════════════════════════
     cfg: digitos, simbolos, intentos, repetidos, porPosicion, tiempo */
  MJ.registrar('clave', {
    titulo: 'Descifrar la clave',
    ayuda: 'Escribe la clave con el teclado o el ratón y pulsa **INTRO** para probar.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var digitos = U.tope(Math.round(cfg.digitos || 4), 2, 6)
      var simbolos = U.tope(Math.round(cfg.simbolos || 8), 2, 10)
      var repetidos = cfg.repetidos === true || simbolos < digitos
      var intentos = U.tope(Math.round(cfg.intentos || 7), 1, 12)
      var porPosicion = cfg.porPosicion !== false

      var clave = []
      if (repetidos) {
        for (var i = 0; i < digitos; i++) clave.push(U.entero(0, simbolos - 1))
      } else {
        var bolsa = []
        for (var b = 0; b < simbolos; b++) bolsa.push(b)
        clave = U.barajar(bolsa).slice(0, digitos)
      }

      var usados = 0
      var escrito = []

      ctx.ayuda((porPosicion
        ? '**VERDE**: en su sitio · **ÁMBAR**: está, pero en otro sitio · **GRIS**: no está. '
        : 'Tras cada intento se dice cuántas cifras están en su sitio y cuántas descolocadas. ')
        + (repetidos ? 'La clave puede repetir cifras.' : 'La clave no repite cifras.')
        + ' Teclado o ratón; **INTRO** para probar.')

      var cuerpo = ctx.el('div', 'cl-cuerpo')
      ctx.zona.appendChild(cuerpo)

      var historial = ctx.el('div', 'cl-historial')
      cuerpo.appendChild(historial)

      var lado = ctx.el('div', 'cl-lado')
      cuerpo.appendChild(lado)
      var pantalla = ctx.el('div', 'cl-pantalla')
      lado.appendChild(pantalla)
      var casillas = []
      for (var d = 0; d < digitos; d++) {
        var casilla = ctx.el('span', 'cl-casilla', '')
        pantalla.appendChild(casilla)
        casillas.push(casilla)
      }

      var teclado = ctx.el('div', 'cl-teclado')
      lado.appendChild(teclado)
      var teclas = {}
      var orden = [1, 2, 3, 4, 5, 6, 7, 8, 9, 'borrar', 0, 'probar']
      orden.forEach(function (que) {
        var t = ctx.el('button', 'cl-tecla')
        t.type = 'button'
        if (que === 'borrar') { t.textContent = '←'; t.classList.add('cl-tecla--accion') }
        else if (que === 'probar') { t.textContent = 'OK'; t.classList.add('cl-tecla--accion', 'cl-tecla--ok') }
        else {
          t.textContent = String(que)
          if (que >= simbolos) { t.disabled = true; t.classList.add('cl-tecla--fuera') }
          teclas[que] = t
        }
        ctx.escuchar(t, 'click', function () {
          if (que === 'borrar') borrar()
          else if (que === 'probar') probar()
          else escribir(que)
        })
        teclado.appendChild(t)
      })

      function pintarPantalla() {
        casillas.forEach(function (c, i) {
          c.textContent = escrito[i] === undefined ? '' : String(escrito[i])
          c.classList.toggle('cl-casilla--ahora', i === escrito.length)
        })
      }

      function escribir(n) {
        if (!ctx.viva() || n >= simbolos || escrito.length >= digitos) return
        escrito.push(n)
        ctx.sonido('tic')
        pintarPantalla()
      }

      function borrar() {
        if (!ctx.viva() || !escrito.length) return
        escrito.pop()
        pintarPantalla()
      }

      /* Como el Wordle: primero las exactas, y cada cifra de la clave solo
         puede justificar UNA ambar. */
      function pistas(intento) {
        var res = [], libres = {}
        for (var i = 0; i < digitos; i++) {
          if (intento[i] === clave[i]) res[i] = 'bien'
          else libres[clave[i]] = (libres[clave[i]] || 0) + 1
        }
        for (var k = 0; k < digitos; k++) {
          if (res[k]) continue
          if (libres[intento[k]] > 0) { res[k] = 'casi'; libres[intento[k]]-- }
          else res[k] = 'no'
        }
        return res
      }

      function probar() {
        if (!ctx.viva() || escrito.length !== digitos) return
        var intento = escrito.slice()
        var res = pistas(intento)
        usados++

        var fila = ctx.el('div', 'cl-fila')
        var exactas = 0, casi = 0
        intento.forEach(function (n, i) {
          if (res[i] === 'bien') exactas++
          if (res[i] === 'casi') casi++
          fila.appendChild(ctx.el('span', 'cl-cifra' + (porPosicion ? ' cl-cifra--' + res[i] : ''), String(n)))
        })
        if (!porPosicion) fila.appendChild(ctx.el('span', 'cl-recuento', exactas + ' en su sitio · ' + casi + ' descolocadas'))
        historial.appendChild(fila)
        historial.scrollTop = historial.scrollHeight

        /* Una tecla que ya se sabe que no esta se apaga (solo con pista por cifra). */
        if (porPosicion) {
          intento.forEach(function (n, i) {
            if (res[i] === 'no' && clave.indexOf(n) === -1 && teclas[n]) teclas[n].classList.add('cl-tecla--descartada')
          })
        }

        escrito = []
        pintarPantalla()
        ctx.vidas(intentos - usados, intentos)

        if (exactas === digitos) { ctx.ganar(); return }
        if (usados >= intentos) { ctx.perder(); return }
        ctx.sonido('clic')
      }

      ctx.tecla(function (codigo, abajo, e) {
        if (!abajo) return
        var m = /^(?:Digit|Numpad)(\d)$/.exec(codigo)
        if (m) escribir(Number(m[1]))
        else if (codigo === 'Backspace' || codigo === 'Delete') borrar()
        else if (codigo === 'Enter' || codigo === 'NumpadEnter') probar()
      })

      ctx.vidas(intentos, intentos)
      pintarPantalla()
    },
  })

  /* ═══ SINTONIZAR LA SEÑAL ═════════════════════════════════════════════
     cfg: rondas, mandos (2|3), margen, mantener (s), deriva, tiempo */
  MJ.registrar('senal', {
    titulo: 'Sintonizar la señal',
    ayuda: 'Pon tu onda encima de la gris y aguántala hasta que se llene.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var rondas = U.tope(Math.round(cfg.rondas || 3), 1, 8)
      var conFase = Math.round(cfg.mandos || 2) >= 3
      var margen = U.tope(Number(cfg.margen) || 0.1, 0.02, 0.4)
      var mantener = Math.max(0.2, Number(cfg.mantener) || 1)
      var deriva = U.tope(Number(cfg.deriva) || 0, 0, 1)

      ctx.ayuda('Pon tu onda encima de la gris: **W**/**S** altura · **A**/**D** frecuencia'
        + (conFase ? ' · **Q**/**E** fase' : '') + ' (o arrastra los mandos). Aguántala hasta que se llene.')

      var ronda = 0
      var mia = { alto: 0.5, frec: 0.5, fase: 0 }
      var meta = { alto: 0.5, frec: 0.5, fase: 0 }
      var sostenido = 0
      var reloj = 0

      var pantalla = ctx.el('div', 'sn-pantalla')
      ctx.zona.appendChild(pantalla)

      var pie = ctx.el('div', 'sn-pie')
      ctx.zona.appendChild(pie)

      var fila = ctx.el('div', 'mj-pie')
      fila.appendChild(ctx.el('span', 'mj-etiqueta', 'COINCIDE'))
      var medidor = ctx.el('div', 'mj-medidor')
      var relleno = ctx.el('div', 'mj-medidor__relleno')
      var marca = ctx.el('div', 'mj-medidor__marca')
      medidor.appendChild(relleno)
      medidor.appendChild(marca)
      fila.appendChild(medidor)
      pie.appendChild(fila)

      var mandos = ctx.el('div', 'sn-mandos')
      pie.appendChild(mandos)
      var deslizadores = {}
      var LISTA = [['alto', 'ALTURA'], ['frec', 'FRECUENCIA']]
      if (conFase) LISTA.push(['fase', 'FASE'])
      LISTA.forEach(function (par) {
        var caja = ctx.el('label', 'sn-mando')
        caja.appendChild(ctx.el('span', 'mj-etiqueta', par[1]))
        var d = document.createElement('input')
        d.type = 'range'; d.min = '0'; d.max = '1000'; d.step = '1'
        d.className = 'sn-deslizador'
        d.tabIndex = -1
        caja.appendChild(d)
        mandos.appendChild(caja)
        deslizadores[par[0]] = d
        ctx.escuchar(d, 'input', function () { mia[par[0]] = Number(d.value) / 1000 })
        /* Que las flechas no muevan el mando a la vez que el juego. */
        ctx.escuchar(d, 'keydown', function (e) { e.preventDefault() })
      })

      /* El lienzo se mide cuando ya esta todo lo demas puesto: antes, la
         pantalla ocupa el panel entero y saldria estirado. */
      var L = U.lienzo(pantalla)

      var cLinea = U.color('--arc-ink-3', '#55555c')
      var cMia = U.color('--arc-accent', '#d81b55')
      var cBien = U.color('--arc-ok', '#146636')

      /* De 0..1 a lo que pinta: altura 0.2..1, frecuencia 1..5 ondas, fase 0..2π. */
      function onda(o, x, extra) {
        var alto = 0.2 + o.alto * 0.8
        var frec = 1 + o.frec * 4
        return alto * Math.sin(x * Math.PI * 2 * frec + o.fase * Math.PI * 2 + (extra || 0))
      }

      function metaAhora() {
        if (!deriva) return meta
        return {
          alto: U.tope(meta.alto + Math.sin(reloj * 0.9) * 0.16 * deriva, 0, 1),
          frec: U.tope(meta.frec + Math.sin(reloj * 0.6 + 1.3) * 0.1 * deriva, 0, 1),
          fase: meta.fase + (conFase ? Math.sin(reloj * 0.5) * 0.12 * deriva : 0),
        }
      }

      function error() {
        var m = metaAhora()
        var suma = 0, N = 64
        for (var i = 0; i < N; i++) suma += Math.abs(onda(mia, i / N) - onda(m, i / N))
        return suma / N / 2
      }

      function nuevaRonda() {
        meta = { alto: U.azar(0.15, 1), frec: U.azar(0, 1), fase: conFase ? U.azar(0, 1) : 0 }
        var vueltas = 0
        do {
          mia = { alto: U.azar(0, 1), frec: U.azar(0, 1), fase: conFase ? U.azar(0, 1) : 0 }
          vueltas++
        } while (error() < margen * 3 && vueltas < 40)
        sostenido = 0
        ctx.progreso(ronda, rondas)
      }

      function trazar(o, color, ancho, discontinua) {
        var g = L.g
        g.beginPath()
        for (var i = 0; i <= 160; i++) {
          var x = i / 160
          var y = L.alto / 2 - onda(o, x) * L.alto * 0.42
          if (i === 0) g.moveTo(x * L.ancho, y)
          else g.lineTo(x * L.ancho, y)
        }
        g.setLineDash(discontinua ? [7, 6] : [])
        g.lineWidth = ancho
        g.strokeStyle = color
        g.lineJoin = 'round'
        g.stroke()
      }

      ctx.fotograma(function (dt) {
        reloj += dt
        var paso = dt / 2.4
        var lento = ctx.pulsada('ShiftLeft') ? 0.35 : 1
        mia.alto = U.tope(mia.alto + ((ctx.pulsada('KeyW') || ctx.pulsada('ArrowUp') ? 1 : 0) - (ctx.pulsada('KeyS') || ctx.pulsada('ArrowDown') ? 1 : 0)) * paso * lento, 0, 1)
        mia.frec = U.tope(mia.frec + ((ctx.pulsada('KeyD') || ctx.pulsada('ArrowRight') ? 1 : 0) - (ctx.pulsada('KeyA') || ctx.pulsada('ArrowLeft') ? 1 : 0)) * paso * lento, 0, 1)
        if (conFase) {
          mia.fase = (mia.fase + ((ctx.pulsada('KeyE') ? 1 : 0) - (ctx.pulsada('KeyQ') ? 1 : 0)) * paso * lento + 1) % 1
        }
        for (var k in deslizadores) deslizadores[k].value = String(Math.round(mia[k] * 1000))

        var err = error()
        var dentro = err <= margen
        sostenido = dentro ? sostenido + dt : Math.max(0, sostenido - dt * 2)

        var g = L.g
        g.clearRect(0, 0, L.ancho, L.alto)
        g.setLineDash([])
        g.lineWidth = 1
        g.strokeStyle = cLinea
        g.globalAlpha = 0.25
        g.beginPath()
        g.moveTo(0, L.alto / 2); g.lineTo(L.ancho, L.alto / 2)
        g.stroke()
        g.globalAlpha = 0.75
        trazar(metaAhora(), cLinea, 5, false)
        g.globalAlpha = 1
        trazar(mia, dentro ? cBien : cMia, 2.5, false)

        var coincide = U.tope(1 - err / 0.5, 0, 1)
        relleno.style.width = (coincide * 100).toFixed(1) + '%'
        relleno.classList.toggle('mj-medidor__relleno--bien', dentro)
        marca.style.left = ((1 - margen / 0.5) * 100).toFixed(1) + '%'
        pantalla.style.setProperty('--sn-lleno', U.tope(sostenido / mantener, 0, 1).toFixed(3))

        if (sostenido >= mantener) {
          ronda++
          ctx.acierto()
          if (ronda >= rondas) { ctx.progreso(ronda, rondas); ctx.ganar(); return }
          nuevaRonda()
        }
      })

      nuevaRonda()
    },
  })

  /* ═══ CORTE DE PRECISION ══════════════════════════════════════════════
     cfg: rondas, curvas, ancho (% del panel), fallos, tiempo */
  MJ.registrar('corte', {
    titulo: 'Corte de precisión',
    ayuda: 'Pulsa sobre el **PUNTO** y, sin soltar, sigue la línea hasta el final. Si te sales, vuelves a la última marca.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var rondas = U.tope(Math.round(cfg.rondas || 1), 1, 6)
      var curvas = U.tope(Math.round(cfg.curvas || 4), 2, 10)

      var L = U.lienzo(ctx.zona)
      var medio = Math.max(3, L.ancho * U.tope(Number(cfg.ancho) || 4, 1, 12) / 100 / 2)

      var ronda = 0
      var camino = []
      var hasta = 0           // indice del camino hasta donde esta cortado
      var marca = 0           // indice al que se vuelve al salirse
      var cortando = false
      var ultimo = null

      var cSuave = U.color('--arc-ink-3', '#55555c')
      var cTinta = U.color('--arc-ink', '#0b0b0d')
      var cCorte = U.color('--arc-accent', '#d81b55')
      var cBien = U.color('--arc-ok', '#146636')

      function nuevoCamino() {
        /* Puntos de paso de izquierda a derecha con la altura al azar, unidos
           con una curva de Catmull-Rom. */
        var pasos = []
        var margenX = 0.09, margenY = 0.16
        for (var i = 0; i <= curvas; i++) {
          var x = margenX + (1 - margenX * 2) * i / curvas
          var y = U.azar(margenY, 1 - margenY)
          if (i > 0) {
            /* Que cada tramo suba o baje de verdad: una linea casi recta no es un reto. */
            var antes = pasos[i - 1].y
            var vueltas = 0
            while (Math.abs(y - antes) < 0.22 && vueltas++ < 20) y = U.azar(margenY, 1 - margenY)
          }
          pasos.push({ x: x * L.ancho, y: y * L.alto })
        }
        camino = []
        for (var s = 0; s < pasos.length - 1; s++) {
          var p0 = pasos[Math.max(0, s - 1)], p1 = pasos[s], p2 = pasos[s + 1], p3 = pasos[Math.min(pasos.length - 1, s + 2)]
          for (var k = 0; k < 40; k++) {
            var t = k / 40, t2 = t * t, t3 = t2 * t
            camino.push({
              x: 0.5 * ((2 * p1.x) + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
              y: U.tope(0.5 * ((2 * p1.y) + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3), medio + 4, L.alto - medio - 4),
            })
          }
        }
        camino.push(pasos[pasos.length - 1])
        hasta = 0
        marca = 0
        cortando = false
        ultimo = null
        ctx.progreso(ronda, rondas)
      }

      function posicion(e) {
        var r = L.nodo.getBoundingClientRect()
        return { x: (e.clientX - r.left) * L.ancho / r.width, y: (e.clientY - r.top) * L.alto / r.height }
      }

      function dist(a, b) { return Math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)) }

      /* Avanza el corte hasta el punto del camino mas cercano a `p`, mirando
         solo un poco por delante (no vale saltarse un trozo). false = fuera. */
      function avanzar(p) {
        var mejor = -1, mejorD = Infinity
        var desde = Math.max(0, hasta - 6), fin = Math.min(camino.length - 1, hasta + 14)
        for (var i = desde; i <= fin; i++) {
          var d = dist(p, camino[i])
          if (d < mejorD) { mejorD = d; mejor = i }
        }
        if (mejorD > medio) return false
        if (mejor > hasta) hasta = mejor
        return true
      }

      function salirse() {
        cortando = false
        ultimo = null
        hasta = marca
        ctx.fallo()
      }

      ctx.escuchar(L.nodo, 'mousedown', function (e) {
        if (e.button !== 0 || !ctx.viva()) return
        var p = posicion(e)
        if (dist(p, camino[hasta]) <= Math.max(medio, 12) * 1.4) {
          cortando = true
          ultimo = p
        }
      })
      ctx.escuchar(window, 'mouseup', function () { cortando = false; ultimo = null })

      ctx.escuchar(window, 'mousemove', function (e) {
        if (!cortando || !ctx.viva()) return
        var p = posicion(e)
        /* El raton da saltos: se recorre el salto a trocitos para que ir
           deprisa pero bien no cuente como salirse. */
        var tramo = dist(ultimo, p)
        var trozos = Math.max(1, Math.ceil(tramo / 3))
        for (var i = 1; i <= trozos; i++) {
          var q = { x: ultimo.x + (p.x - ultimo.x) * i / trozos, y: ultimo.y + (p.y - ultimo.y) * i / trozos }
          if (!avanzar(q)) { salirse(); return }
        }
        ultimo = p

        /* Una marca cada cuarto del camino. */
        var cuarto = Math.floor(hasta / (camino.length / 4)) * Math.floor(camino.length / 4)
        if (cuarto > marca && cuarto < camino.length - 1) { marca = cuarto; ctx.sonido('tic') }

        if (hasta >= camino.length - 2) {
          ronda++
          ctx.acierto()
          if (ronda >= rondas) { ctx.progreso(ronda, rondas); ctx.ganar(); return }
          nuevoCamino()
        }
      })

      function linea(desde, fin, color, ancho, alfa) {
        if (fin <= desde) return
        var g = L.g
        g.beginPath()
        g.moveTo(camino[desde].x, camino[desde].y)
        for (var i = desde + 1; i <= fin; i++) g.lineTo(camino[i].x, camino[i].y)
        g.lineWidth = ancho
        g.lineCap = 'round'
        g.lineJoin = 'round'
        g.strokeStyle = color
        g.globalAlpha = alfa
        g.stroke()
        g.globalAlpha = 1
      }

      function punto(p, radio, color, alfa) {
        var g = L.g
        g.beginPath()
        g.arc(p.x, p.y, radio, 0, Math.PI * 2)
        g.fillStyle = color
        g.globalAlpha = alfa
        g.fill()
        g.globalAlpha = 1
      }

      ctx.fotograma(function (dt, t) {
        var g = L.g
        g.clearRect(0, 0, L.ancho, L.alto)
        var ultimoI = camino.length - 1
        linea(0, ultimoI, cSuave, medio * 2, 0.22)
        linea(0, ultimoI, cTinta, 1.5, 0.55)
        linea(0, hasta, cBien, Math.max(3, medio * 0.7), 0.95)
        punto(camino[ultimoI], Math.max(6, medio * 0.8), cTinta, 0.8)
        if (marca > 0) punto(camino[marca], 4, cBien, 1)
        var late = cortando ? 1 : 1 + Math.sin(t * 6) * 0.18
        punto(camino[hasta], Math.max(7, medio * 0.9) * late, cCorte, 1)
      })

      nuevoCamino()
    },
  })
})()
