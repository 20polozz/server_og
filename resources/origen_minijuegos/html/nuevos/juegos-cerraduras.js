/* LOS MINIJUEGOS NUEVOS · cerraduras y cajas
 *   ganzua   ganzua de tension        pines    pines del bombin
 *   dial     dial de la caja fuerte   taladro  taladro
 */
(function () {
  'use strict'

  var MJ = window.OrigenMJ
  var U = MJ.util

  /* ═══ GANZUA DE TENSION ═══════════════════════════════════════════════
     cfg: cerraduras, margen (grados), aguante (s), fallos, tiempo */
  MJ.registrar('ganzua', {
    titulo: 'Ganzúa de tensión',
    ayuda: 'Mueve la ganzúa con el **RATÓN** (o **A**/**D**) y gira el bombín con **CLIC** o **ESPACIO**. Si tiembla, suelta: ahí no es.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var total = Math.max(1, Math.round(cfg.cerraduras || 1))
      var medio = Math.max(2, Number(cfg.margen) || 16) / 2
      var aguante = Math.max(0.2, Number(cfg.aguante) || 1.5)

      var hechas = 0
      var angulo = 0          // de la ganzua, -90..90 (0 = arriba)
      var giro = 0            // del bombin, 0..90
      var dulce = 0
      var desgaste = 0
      var tensando = false
      var conRaton = false
      var suelta = false      // tras partirse hay que soltar antes de volver a girar
      var pausa = 0
      var ticEn = 0

      var svg = U.svg('svg', { viewBox: '0 0 300 300', class: 'mj-svg' }, ctx.zona)
      U.svg('circle', { cx: 150, cy: 150, r: 128, class: 'gz-cuerpo' }, svg)
      U.svg('circle', { cx: 150, cy: 150, r: 112, class: 'gz-aro' }, svg)
      for (var i = -90; i <= 90; i += 15) {
        var rad = (i - 90) * Math.PI / 180
        U.svg('line', {
          x1: 150 + Math.cos(rad) * 116, y1: 150 + Math.sin(rad) * 116,
          x2: 150 + Math.cos(rad) * (i % 45 === 0 ? 126 : 122), y2: 150 + Math.sin(rad) * (i % 45 === 0 ? 126 : 122),
          class: 'gz-marca',
        }, svg)
      }
      var bombin = U.svg('g', {}, svg)
      U.svg('circle', { cx: 150, cy: 150, r: 74, class: 'gz-bombin' }, bombin)
      U.svg('rect', { x: 143, y: 96, width: 14, height: 108, rx: 5, class: 'gz-ranura' }, bombin)
      U.svg('circle', { cx: 150, cy: 150, r: 5, class: 'gz-eje' }, bombin)
      var ganzua = U.svg('g', {}, svg)
      U.svg('rect', { x: 147.5, y: 22, width: 5, height: 130, rx: 2.5, class: 'gz-ganzua' }, ganzua)
      U.svg('circle', { cx: 150, cy: 24, r: 7, class: 'gz-ganzua-punta' }, ganzua)

      var pie = ctx.el('div', 'mj-pie')
      pie.appendChild(ctx.el('span', 'mj-etiqueta', 'GANZÚA'))
      var barra = ctx.el('div', 'mj-medidor')
      var relleno = ctx.el('div', 'mj-medidor__relleno')
      barra.appendChild(relleno)
      pie.appendChild(barra)
      ctx.zona.appendChild(pie)

      function nueva() {
        dulce = U.azar(-82, 82)
        giro = 0
        desgaste = 0
        ctx.progreso(hechas, total)
      }
      nueva()

      ctx.escuchar(ctx.zona, 'mousemove', function (e) {
        if (tensando) return
        var r = ctx.zona.getBoundingClientRect()
        angulo = U.tope(((e.clientX - r.left) / r.width - 0.5) * 200, -90, 90)
      })
      ctx.escuchar(ctx.zona, 'mousedown', function (e) { if (e.button === 0) conRaton = true })
      ctx.escuchar(window, 'mouseup', function () { conRaton = false })

      ctx.fotograma(function (dt) {
        if (pausa > 0) {
          pausa -= dt
          if (pausa <= 0) {
            if (hechas >= total) { ctx.ganar(); return }
            nueva()
          }
          pintar(0)
          return
        }

        var quiere = conRaton || ctx.pulsada('Space') || ctx.pulsada('KeyE')
        if (!quiere) suelta = false
        tensando = quiere && !suelta

        if (!tensando) {
          var mover = (ctx.pulsada('KeyD') || ctx.pulsada('ArrowRight') ? 1 : 0) - (ctx.pulsada('KeyA') || ctx.pulsada('ArrowLeft') ? 1 : 0)
          if (mover) angulo = U.tope(angulo + mover * 75 * dt, -90, 90)
          giro = Math.max(0, giro - 260 * dt)
          desgaste = Math.max(0, desgaste - dt * 0.15)
          pintar(0)
          return
        }

        var lejos = Math.abs(angulo - dulce)
        var hasta = lejos <= medio ? 90 : Math.max(4, 90 * (1 - (lejos - medio) / 75))
        var temblor = 0

        if (giro < hasta) {
          giro = Math.min(hasta, giro + 150 * dt)
        } else if (hasta < 90) {
          /* Forzando donde no es: la ganzua sufre. */
          desgaste += dt
          temblor = 2.2
          ticEn -= dt
          if (ticEn <= 0) { ctx.sonido('tic'); ticEn = 0.09 }
          if (desgaste >= aguante) {
            desgaste = 0
            giro = 0
            suelta = true
            if (ctx.fallo()) return
          }
        }

        if (giro >= 90) {
          hechas++
          ctx.acierto()
          ctx.progreso(hechas, total)
          suelta = true
          pausa = 0.45
        }
        pintar(temblor)
      })

      function pintar(temblor) {
        var t = temblor ? (Math.random() - 0.5) * temblor * 2 : 0
        bombin.setAttribute('transform', 'rotate(' + (giro + t).toFixed(2) + ' 150 150)')
        ganzua.setAttribute('transform', 'rotate(' + (angulo + t * 1.5).toFixed(2) + ' 150 150)')
        var queda = U.tope(1 - desgaste / aguante, 0, 1)
        relleno.style.width = (queda * 100).toFixed(1) + '%'
        relleno.classList.toggle('mj-medidor__relleno--mal', queda < 0.4)
      }
    },
  })

  /* ═══ PINES DEL BOMBIN ════════════════════════════════════════════════
     cfg: pines, velocidad, margen (% del canal), seCaen, fallos, tiempo */
  MJ.registrar('pines', {
    titulo: 'Pines del bombín',
    ayuda: 'Elige pin con **A**/**D** (o un clic) y fíjalo con **ESPACIO** justo cuando cruza la línea.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var n = U.tope(Math.round(cfg.pines || 4), 2, 8)
      var medio = U.tope(Number(cfg.margen) || 15, 3, 60) / 200
      var vel = Math.max(0.1, Number(cfg.velocidad) || 1)

      var pines = []
      var elegido = 0
      var ordenFijados = []

      var fila = ctx.el('div', 'pn-fila')
      ctx.zona.appendChild(fila)

      for (var i = 0; i < n; i++) {
        (function (i) {
          var canal = ctx.el('div', 'pn-canal')
          var linea = ctx.el('div', 'pn-linea')
          var pin = ctx.el('div', 'pn-pin')
          var numero = ctx.el('div', 'pn-numero', String(i + 1))
          var donde = U.azar(0.3, 0.7)
          linea.style.top = ((donde - medio) * 100).toFixed(2) + '%'
          linea.style.height = (medio * 200).toFixed(2) + '%'
          canal.appendChild(linea)
          canal.appendChild(pin)
          canal.appendChild(numero)
          fila.appendChild(canal)
          pines.push({
            canal: canal, pin: pin, linea: donde,
            fase: U.azar(0, Math.PI * 2),
            ritmo: vel * U.azar(1.5, 2.9),
            pos: 0.5, fijo: false,
          })
          ctx.escuchar(canal, 'mousedown', function (e) {
            if (e.button !== 0) return
            if (elegido === i) fijar()
            else elegir(i)
          })
        })(i)
      }

      function elegir(i) {
        elegido = (i + n) % n
        pines.forEach(function (p, k) { p.canal.classList.toggle('pn-canal--elegido', k === elegido) })
      }

      function siguienteLibre(desde, paso) {
        for (var k = 1; k <= n; k++) {
          var i = (desde + paso * k + n * k) % n
          if (!pines[i].fijo) return i
        }
        return desde
      }

      function fijar() {
        var p = pines[elegido]
        if (!p || p.fijo) return
        if (Math.abs(p.pos - p.linea) <= medio) {
          p.fijo = true
          p.pos = p.linea
          p.canal.classList.add('pn-canal--fijo')
          ordenFijados.push(elegido)
          ctx.acierto()
          ctx.progreso(ordenFijados.length, n)
          if (ordenFijados.length >= n) { ctx.ganar(); return }
          elegir(siguienteLibre(elegido, 1))
        } else {
          if (cfg.seCaen && ordenFijados.length > 0) {
            var cae = pines[ordenFijados.pop()]
            cae.fijo = false
            cae.canal.classList.remove('pn-canal--fijo')
            ctx.progreso(ordenFijados.length, n)
          }
          ctx.fallo()
        }
      }

      ctx.tecla(function (codigo, abajo, e, repetida) {
        if (!abajo || repetida) return
        if (codigo === 'KeyA' || codigo === 'ArrowLeft') elegir(siguienteLibre(elegido, -1))
        else if (codigo === 'KeyD' || codigo === 'ArrowRight') elegir(siguienteLibre(elegido, 1))
        else if (codigo === 'Space' || codigo === 'KeyW' || codigo === 'ArrowUp' || codigo === 'Enter') fijar()
      })

      ctx.fotograma(function (dt) {
        for (var i = 0; i < n; i++) {
          var p = pines[i]
          if (!p.fijo) {
            p.fase += p.ritmo * dt
            p.pos = 0.5 + Math.sin(p.fase) * 0.44
          }
          p.pin.style.top = (p.pos * 100).toFixed(2) + '%'
        }
      })

      ctx.progreso(0, n)
      elegir(0)
    },
  })

  /* ═══ DIAL DE LA CAJA FUERTE ══════════════════════════════════════════
     cfg: numeros, margen, alcance, ruido, fallos, tiempo */
  MJ.registrar('dial', {
    titulo: 'Dial de la caja fuerte',
    ayuda: 'Gira con **A**/**D** o la **RUEDA** (con **MAYÚS**, despacio). Cuando el fonendo esté en lo más alto, confirma con **ESPACIO**.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var total = U.tope(Math.round(cfg.numeros || 3), 1, 8)
      var margen = Math.max(0, Number(cfg.margen) || 0)
      var alcance = Math.max(3, Number(cfg.alcance) || 15)
      var ruido = U.tope(Number(cfg.ruido) || 0, 0, 0.6)

      var valor = U.azar(0, 100)
      var objetivos = []
      var hechos = 0
      var vibra = 0
      var vibraEn = 0
      var ticEn = 0
      var arrastrando = false
      var anguloAntes = 0

      var anterior = Math.round(valor)
      for (var i = 0; i < total; i++) {
        var n
        do { n = U.entero(0, 99) } while (lejos(n, anterior) < 18)
        objetivos.push(n)
        anterior = n
      }

      function lejos(a, b) {
        var d = Math.abs(a - b) % 100
        return Math.min(d, 100 - d)
      }

      var cuerpo = ctx.el('div', 'dl-cuerpo')
      ctx.zona.appendChild(cuerpo)

      var cajaDial = ctx.el('div', 'dl-dial')
      cuerpo.appendChild(cajaDial)
      var svg = U.svg('svg', { viewBox: '0 0 300 300', class: 'mj-svg' }, cajaDial)
      U.svg('circle', { cx: 150, cy: 150, r: 140, class: 'dl-base' }, svg)
      var rueda = U.svg('g', {}, svg)
      U.svg('circle', { cx: 150, cy: 150, r: 124, class: 'dl-rueda' }, rueda)
      for (var k = 0; k < 100; k++) {
        var a = (k * 3.6 - 90) * Math.PI / 180
        var largo = k % 10 === 0 ? 16 : (k % 5 === 0 ? 11 : 6)
        U.svg('line', {
          x1: 150 + Math.cos(a) * 122, y1: 150 + Math.sin(a) * 122,
          x2: 150 + Math.cos(a) * (122 - largo), y2: 150 + Math.sin(a) * (122 - largo),
          class: k % 10 === 0 ? 'dl-raya dl-raya--gorda' : 'dl-raya',
        }, rueda)
        if (k % 10 === 0) {
          var t = U.svg('text', {
            x: 150 + Math.cos(a) * 92, y: 150 + Math.sin(a) * 92,
            class: 'dl-cifra', 'text-anchor': 'middle', 'dominant-baseline': 'central',
            transform: 'rotate(' + (k * 3.6) + ' ' + (150 + Math.cos(a) * 92) + ' ' + (150 + Math.sin(a) * 92) + ')',
          }, rueda)
          t.textContent = String(k)
        }
      }
      U.svg('circle', { cx: 150, cy: 150, r: 46, class: 'dl-pomo' }, rueda)
      U.svg('line', { x1: 150, y1: 150, x2: 150, y2: 112, class: 'dl-pomo-raya' }, rueda)
      U.svg('path', { d: 'M150 22 L141 4 L159 4 Z', class: 'dl-flecha' }, svg)

      var lado = ctx.el('div', 'dl-lado')
      cuerpo.appendChild(lado)
      var lectura = ctx.el('div', 'dl-lectura', '00')
      lado.appendChild(lectura)
      lado.appendChild(ctx.el('span', 'mj-etiqueta', 'FONENDO'))
      var fonendo = ctx.el('div', 'dl-fonendo')
      var nivel = ctx.el('div', 'dl-fonendo__nivel')
      fonendo.appendChild(nivel)
      lado.appendChild(fonendo)

      var combinacion = ctx.el('div', 'dl-combinacion')
      ctx.zona.appendChild(combinacion)
      var huecos = []
      for (var h = 0; h < total; h++) {
        var hueco = ctx.el('span', 'dl-hueco', '··')
        combinacion.appendChild(hueco)
        huecos.push(hueco)
      }
      huecos[0].classList.add('dl-hueco--ahora')

      function senal() {
        return Math.max(0, 1 - lejos(valor, objetivos[hechos]) / alcance)
      }

      function mover(cuanto) {
        if (!cuanto) return
        var antes = Math.floor(valor)
        valor = ((valor + cuanto) % 100 + 100) % 100
        if (Math.floor(valor) !== antes) {
          ticEn -= 1
          if (ticEn <= 0) { ctx.tono(300 + senal() * 900, 0.03, 'square', 0, 0.25 + senal() * 0.5); ticEn = 1 }
        }
      }

      function confirmar() {
        var numero = Math.round(valor) % 100
        if (lejos(numero, objetivos[hechos]) <= margen) {
          huecos[hechos].textContent = ('0' + objetivos[hechos]).slice(-2)
          huecos[hechos].classList.remove('dl-hueco--ahora')
          huecos[hechos].classList.add('dl-hueco--hecho')
          hechos++
          ctx.acierto()
          ctx.progreso(hechos, total)
          if (hechos >= total) { ctx.ganar(); return }
          huecos[hechos].classList.add('dl-hueco--ahora')
        } else {
          ctx.fallo()
        }
      }

      ctx.tecla(function (codigo, abajo, e, repetida) {
        if (abajo && !repetida && (codigo === 'Space' || codigo === 'Enter')) confirmar()
      })

      ctx.escuchar(ctx.zona, 'wheel', function (e) {
        e.preventDefault()
        mover((e.deltaY > 0 ? 1 : -1) * (e.shiftKey ? 0.5 : 1))
      }, { passive: false })

      function anguloDe(e) {
        var r = cajaDial.getBoundingClientRect()
        return Math.atan2(e.clientY - (r.top + r.height / 2), e.clientX - (r.left + r.width / 2)) * 180 / Math.PI
      }
      ctx.escuchar(cajaDial, 'mousedown', function (e) {
        if (e.button !== 0) return
        arrastrando = true
        anguloAntes = anguloDe(e)
      })
      ctx.escuchar(window, 'mouseup', function () { arrastrando = false })
      ctx.escuchar(window, 'mousemove', function (e) {
        if (!arrastrando) return
        var ahora = anguloDe(e)
        var delta = ahora - anguloAntes
        if (delta > 180) delta -= 360
        if (delta < -180) delta += 360
        anguloAntes = ahora
        /* Girar la rueda a la derecha baja el numero bajo la flecha. */
        mover(-delta / 3.6)
      })

      ctx.fotograma(function (dt) {
        var lento = ctx.pulsada('ShiftLeft') || ctx.pulsada('ShiftRight')
        var sentido = (ctx.pulsada('KeyD') || ctx.pulsada('ArrowRight') ? 1 : 0) - (ctx.pulsada('KeyA') || ctx.pulsada('ArrowLeft') ? 1 : 0)
        if (sentido) mover(sentido * (lento ? 4 : 16) * dt)

        vibraEn -= dt
        if (vibraEn <= 0) {
          vibra = (Math.random() - 0.5) * 2 * ruido
          vibraEn = 0.08
        }
        var s = U.tope(senal() + vibra, 0, 1)
        nivel.style.height = (s * 100).toFixed(1) + '%'
        nivel.classList.toggle('dl-fonendo__nivel--alto', s > 0.9)
        rueda.setAttribute('transform', 'rotate(' + (-valor * 3.6).toFixed(2) + ' 150 150)')
        lectura.textContent = ('0' + (Math.round(valor) % 100)).slice(-2)
      })

      ctx.progreso(0, total)
    },
  })

  /* ═══ TALADRO ═════════════════════════════════════════════════════════
     cfg: capas, grosor (s por capa), banda (%), calor, fallos, tiempo */
  MJ.registrar('taladro', {
    titulo: 'Taladro',
    ayuda: 'Mantén **ESPACIO** o **CLIC** para subir de vueltas y suelta para bajar. Solo avanza dentro de la franja; pasado de vueltas, se quema.',
    montar: function (ctx) {
      var cfg = ctx.cfg
      var capas = U.tope(Math.round(cfg.capas || 3), 1, 8)
      var grosor = Math.max(0.5, Number(cfg.grosor) || 3)
      var medio = U.tope(Number(cfg.banda) || 20, 4, 60) / 200
      var calor = Math.max(0.1, Number(cfg.calor) || 1)

      var rpm = 0
      var temperatura = 0
      var avance = 0
      var capa = 0
      var centro = 0.5
      var conRaton = false
      var suelta = false
      var zumbido = null

      var cuerpo = ctx.el('div', 'tl-cuerpo')
      ctx.zona.appendChild(cuerpo)

      var colVueltas = ctx.el('div', 'tl-columna')
      colVueltas.appendChild(ctx.el('span', 'mj-etiqueta', 'VUELTAS'))
      var tubo = ctx.el('div', 'tl-tubo')
      var franja = ctx.el('div', 'tl-franja')
      var aguja = ctx.el('div', 'tl-aguja')
      tubo.appendChild(franja)
      tubo.appendChild(aguja)
      colVueltas.appendChild(tubo)
      cuerpo.appendChild(colVueltas)

      var pared = ctx.el('div', 'tl-pared')
      var listaCapas = []
      for (var i = 0; i < capas; i++) {
        var c = ctx.el('div', 'tl-capa')
        var hecho = ctx.el('div', 'tl-capa__hecho')
        c.appendChild(hecho)
        pared.appendChild(c)
        listaCapas.push(hecho)
      }
      var broca = ctx.el('div', 'tl-broca')
      pared.appendChild(broca)
      cuerpo.appendChild(pared)

      var colCalor = ctx.el('div', 'tl-columna')
      colCalor.appendChild(ctx.el('span', 'mj-etiqueta', 'CALOR'))
      var tuboCalor = ctx.el('div', 'tl-tubo tl-tubo--calor')
      var nivelCalor = ctx.el('div', 'tl-calor')
      tuboCalor.appendChild(nivelCalor)
      colCalor.appendChild(tuboCalor)
      cuerpo.appendChild(colCalor)

      function nuevaCapa() {
        centro = U.azar(0.34 + medio, 0.86 - medio)
        franja.style.bottom = ((centro - medio) * 100).toFixed(2) + '%'
        franja.style.height = (medio * 200).toFixed(2) + '%'
        ctx.progreso(capa, capas)
      }
      nuevaCapa()

      ctx.escuchar(ctx.zona, 'mousedown', function (e) { if (e.button === 0) conRaton = true })
      ctx.escuchar(window, 'mouseup', function () { conRaton = false })

      /* El zumbido del taladro: un oscilador que sube con las vueltas. */
      function sonar() {
        if (zumbido) return
        try {
          var ac = new (window.AudioContext || window.webkitAudioContext)()
          var osc = ac.createOscillator()
          var gan = ac.createGain()
          osc.type = 'sawtooth'
          gan.gain.value = 0
          osc.connect(gan)
          gan.connect(ac.destination)
          osc.start()
          zumbido = { ac: ac, osc: osc, gan: gan }
        } catch (e) { zumbido = null }
      }
      sonar()
      ctx.alCerrar(function () {
        if (!zumbido) return
        try { zumbido.osc.stop(); zumbido.ac.close() } catch (e) {}
        zumbido = null
      })

      ctx.fotograma(function (dt) {
        var quiere = conRaton || ctx.pulsada('Space')
        if (!quiere) suelta = false
        var pulsa = quiere && !suelta

        rpm = U.tope(rpm + (pulsa ? 0.62 : -0.8) * dt, 0, 1)

        var dentro = Math.abs(rpm - centro) <= medio
        var pasado = rpm > centro + medio

        if (dentro) {
          avance += dt / grosor
          temperatura += 0.035 * calor * dt
        } else if (pasado) {
          temperatura += (0.38 + (rpm - centro - medio) * 1.6) * calor * dt
        } else {
          temperatura -= (rpm < 0.06 ? 0.34 : 0.2) * dt
        }
        temperatura = Math.max(0, temperatura)

        if (temperatura >= 1) {
          temperatura = 0.35
          rpm = 0
          suelta = true
          if (ctx.fallo()) return
        }

        if (avance >= 1) {
          listaCapas[capa].style.width = '100%'
          avance = 0
          capa++
          ctx.acierto()
          if (capa >= capas) { ctx.progreso(capa, capas); ctx.ganar(); return }
          nuevaCapa()
        }

        aguja.style.bottom = (rpm * 100).toFixed(2) + '%'
        aguja.classList.toggle('tl-aguja--bien', dentro)
        aguja.classList.toggle('tl-aguja--mal', pasado)
        nivelCalor.style.height = (U.tope(temperatura, 0, 1) * 100).toFixed(1) + '%'
        nivelCalor.classList.toggle('tl-calor--alto', temperatura > 0.7)
        listaCapas[capa].style.width = (avance * 100).toFixed(1) + '%'
        broca.style.left = (((capa + avance) / capas) * 100).toFixed(2) + '%'
        broca.classList.toggle('tl-broca--gira', rpm > 0.06)

        if (zumbido) {
          zumbido.osc.frequency.value = 60 + rpm * 240
          zumbido.gan.gain.value = rpm > 0.04 ? (0.05 + rpm * 0.09) * MJ.volumen() : 0
        }
      })
    },
  })
})()
