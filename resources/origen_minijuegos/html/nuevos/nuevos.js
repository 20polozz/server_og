/* LOS MINIJUEGOS NUEVOS · el motor
 *
 * Aqui no hay ningun juego: hay lo que comparten los ocho. El panel, el reloj,
 * los fallos, el progreso, los pitidos, el rotulo del final y la vuelta del
 * resultado a Lua. Cada juego (juegos-*.js) se apunta con OrigenMJ.registrar y
 * solo tiene que pintar dentro de `ctx.zona` y decir acierto / fallo / ganar.
 *
 * Lua manda:  { action: 'nuevoEmpezar', juego, titulo, config, volumen, turno }
 *             { action: 'nuevoCerrar' }
 * y recibe:   POST nuevoResultado { juego, exito, turno }
 */
(function () {
  'use strict'

  var JUEGOS = {}
  var partida = null
  var raiz = null
  var piezas = {}
  var volumen = 0.35

  /* ── Sonido: pitidos hechos a mano, sin ficheros ─────────────────── */
  var audio = null
  function contexto() {
    if (audio) return audio
    try { audio = new (window.AudioContext || window.webkitAudioContext)() } catch (e) { audio = null }
    return audio
  }

  function tono(frecuencia, dura, tipo, cuando, fuerza) {
    var ac = contexto()
    if (!ac || volumen <= 0) return
    try {
      var t0 = ac.currentTime + (cuando || 0)
      var osc = ac.createOscillator()
      var gan = ac.createGain()
      osc.type = tipo || 'sine'
      osc.frequency.setValueAtTime(frecuencia, t0)
      gan.gain.setValueAtTime(0.0001, t0)
      gan.gain.exponentialRampToValueAtTime(Math.max(0.0002, volumen * (fuerza || 1) * 0.5), t0 + 0.008)
      gan.gain.exponentialRampToValueAtTime(0.0001, t0 + dura)
      osc.connect(gan)
      gan.connect(ac.destination)
      osc.start(t0)
      osc.stop(t0 + dura + 0.02)
    } catch (e) {}
  }

  var SONIDOS = {
    tic: function () { tono(1150, 0.035, 'square', 0, 0.35) },
    clic: function () { tono(520, 0.05, 'triangle', 0, 0.7) },
    bien: function () { tono(660, 0.09, 'triangle'); tono(990, 0.14, 'triangle', 0.08) },
    mal: function () { tono(170, 0.22, 'sawtooth', 0, 0.8) },
    ganar: function () { tono(523, 0.1, 'triangle'); tono(659, 0.1, 'triangle', 0.09); tono(784, 0.1, 'triangle', 0.18); tono(1047, 0.22, 'triangle', 0.27) },
    perder: function () { tono(330, 0.16, 'sawtooth', 0, 0.7); tono(247, 0.16, 'sawtooth', 0.14, 0.7); tono(165, 0.3, 'sawtooth', 0.28, 0.7) },
  }

  /* ── El panel ─────────────────────────────────────────────────────── */
  function el(etiqueta, clase, texto) {
    var nodo = document.createElement(etiqueta)
    if (clase) nodo.className = clase
    if (texto !== undefined) nodo.textContent = texto
    return nodo
  }

  function montarPanel() {
    if (raiz) return
    raiz = el('div')
    raiz.id = 'mj-raiz'
    raiz.style.display = 'none'

    piezas.rotulo = el('div', 'mj-rotulo')
    var barra = el('div', 'mj-barra')
    piezas.progreso = el('div', 'mj-pips mj-pips--progreso')
    piezas.reloj = el('div', 'mj-reloj', '0.0')
    piezas.vidas = el('div', 'mj-pips mj-pips--vidas')
    barra.appendChild(piezas.progreso)
    barra.appendChild(piezas.reloj)
    barra.appendChild(piezas.vidas)

    piezas.marco = el('div', 'mj-marco')
    piezas.zona = el('div', 'mj-zona')
    piezas.fin = el('div', 'mj-fin')
    piezas.marco.appendChild(piezas.zona)
    piezas.marco.appendChild(piezas.fin)

    piezas.ayuda = el('div', 'mj-ayuda')

    raiz.appendChild(piezas.rotulo)
    raiz.appendChild(barra)
    raiz.appendChild(piezas.marco)
    raiz.appendChild(piezas.ayuda)
    document.body.appendChild(raiz)
  }

  function pintarPips(caja, llenos, total, titulo) {
    caja.innerHTML = ''
    caja.title = titulo || ''
    if (!total || total < 1) return
    /* Mas de diez puntitos no se leen: se pasa a numero. */
    if (total > 10) {
      caja.appendChild(el('span', 'mj-cuenta', llenos + '/' + total))
      return
    }
    for (var i = 0; i < total; i++) {
      caja.appendChild(el('span', 'mj-pip' + (i < llenos ? ' mj-pip--lleno' : '')))
    }
  }

  /* La ayuda admite **negrita** para las teclas; lo demas va como texto. */
  function pintarAyuda(texto) {
    piezas.ayuda.innerHTML = ''
    String(texto || '').split('**').forEach(function (trozo, i) {
      piezas.ayuda.appendChild(i % 2 ? el('strong', '', trozo) : document.createTextNode(trozo))
    })
  }

  /* ── Una partida ──────────────────────────────────────────────────── */
  function empezar(clave, config, opciones) {
    montarPanel()
    if (partida) cerrar()

    var def = JUEGOS[clave]
    opciones = opciones || {}
    if (!def) {
      devolver(clave, false, opciones.turno)
      return
    }

    config = config || {}
    if (typeof opciones.volumen === 'number') volumen = opciones.volumen

    var p = {
      clave: clave,
      config: config,
      fallos: 0,
      perdonados: typeof config.fallos === 'number' ? Math.max(0, Math.floor(config.fallos)) : null,
      restante: Number(config.tiempo) > 0 ? Number(config.tiempo) : 0,
      conReloj: Number(config.tiempo) > 0,
      terminada: false,
      fotogramas: [],
      teclas: [],
      limpiezas: [],
      pulsadas: {},
      ultimo: 0,
      raf: 0,
      /* El numero de partida de Lua: vuelve con el resultado para que el de
         una partida vieja no cierre la nueva (aunque sea el mismo juego). */
      turno: opciones.turno,
    }
    partida = p

    piezas.rotulo.textContent = opciones.titulo || def.titulo || clave
    piezas.zona.innerHTML = ''
    piezas.zona.className = 'mj-zona mj-zona--' + clave + (def.grande ? ' mj-zona--pantalla' : '')
    /* Los juegos «grandes» van al centro, en una pantalla oscura de aparato. */
    raiz.classList.toggle('mj-raiz--grande', def.grande === true)
    piezas.fin.className = 'mj-fin'
    piezas.fin.textContent = ''
    piezas.marco.classList.remove('mj-marco--mal')
    piezas.reloj.style.visibility = p.conReloj ? 'visible' : 'hidden'
    piezas.reloj.classList.remove('mj-reloj--apura')
    pintarPips(piezas.progreso, 0, 0)
    if (p.perdonados !== null) pintarPips(piezas.vidas, p.perdonados + 1, p.perdonados + 1, 'Intentos')
    else pintarPips(piezas.vidas, 0, 0)
    pintarAyuda(def.ayuda)

    raiz.style.display = 'flex'

    var ctx = {
      zona: piezas.zona,
      cfg: config,
      viva: function () { return partida === p && !p.terminada },
      sonido: function (nombre) { if (SONIDOS[nombre]) SONIDOS[nombre]() },
      tono: tono,
      progreso: function (hechos, total) { pintarPips(piezas.progreso, hechos, total, 'Progreso') },
      vidas: function (quedan, total) { pintarPips(piezas.vidas, quedan, total, 'Intentos') },
      ayuda: pintarAyuda,
      acierto: function () { SONIDOS.bien() },
      /* Devuelve true si con este fallo se ha perdido. */
      fallo: function () {
        if (!ctx.viva()) return true
        p.fallos++
        SONIDOS.mal()
        piezas.marco.classList.remove('mj-marco--mal')
        void piezas.marco.offsetWidth
        piezas.marco.classList.add('mj-marco--mal')
        if (p.perdonados !== null) {
          pintarPips(piezas.vidas, Math.max(0, p.perdonados + 1 - p.fallos), p.perdonados + 1, 'Intentos')
          if (p.fallos > p.perdonados) {
            acabar(p, false)
            return true
          }
        }
        return false
      },
      ganar: function () { acabar(p, true) },
      perder: function () { acabar(p, false) },
      fotograma: function (fn) { p.fotogramas.push(fn) },
      tecla: function (fn) { p.teclas.push(fn) },
      pulsada: function (codigo) { return p.pulsadas[codigo] === true },
      escuchar: function (nodo, tipo, fn, opc) {
        nodo.addEventListener(tipo, fn, opc)
        p.limpiezas.push(function () { nodo.removeEventListener(tipo, fn, opc) })
      },
      alCerrar: function (fn) { p.limpiezas.push(fn) },
      el: el,
    }
    p.ctx = ctx

    try {
      def.montar(ctx)
    } catch (e) {
      console.error('[minijuegos] ' + clave + ' no ha podido montarse', e)
      acabar(p, false, true)
      return
    }

    p.ultimo = performance.now()
    var vuelta = function (ahora) {
      if (partida !== p || p.terminada) return
      var dt = Math.min(0.05, Math.max(0, (ahora - p.ultimo) / 1000))
      p.ultimo = ahora

      if (p.conReloj) {
        p.restante -= dt
        if (p.restante <= 0) {
          piezas.reloj.textContent = '0.0'
          acabar(p, false)
          return
        }
        piezas.reloj.textContent = p.restante.toFixed(1)
        piezas.reloj.classList.toggle('mj-reloj--apura', p.restante <= 10)
      }

      for (var i = 0; i < p.fotogramas.length; i++) {
        try { p.fotogramas[i](dt, ahora / 1000) } catch (e) {
          console.error('[minijuegos] ' + clave, e)
          acabar(p, false, true)
          return
        }
        if (p.terminada) return
      }
      p.raf = requestAnimationFrame(vuelta)
    }
    p.raf = requestAnimationFrame(vuelta)
  }

  function limpiar(p) {
    cancelAnimationFrame(p.raf)
    p.limpiezas.forEach(function (fn) { try { fn() } catch (e) {} })
    p.limpiezas = []
    p.fotogramas = []
    p.teclas = []
  }

  function acabar(p, exito, sinRotulo) {
    if (p.terminada) return
    p.terminada = true
    limpiar(p)

    if (sinRotulo) {
      ocultar(p)
      devolver(p.clave, exito, p.turno)
      return
    }

    if (exito) SONIDOS.ganar()
    else SONIDOS.perder()
    piezas.fin.textContent = exito ? 'CONSEGUIDO' : 'FALLADO'
    piezas.fin.className = 'mj-fin mj-fin--visto ' + (exito ? 'mj-fin--bien' : 'mj-fin--mal')

    setTimeout(function () {
      /* Cerrada por Lua durante el rotulo (otra partida encima): ya no es
         la de ahora y Lua ya ha contestado por ella. */
      if (partida !== p) return
      ocultar(p)
      devolver(p.clave, exito, p.turno)
    }, 850)
  }

  function ocultar(p) {
    if (partida !== p) return
    partida = null
    if (raiz) raiz.style.display = 'none'
    piezas.zona.innerHTML = ''
  }

  /* Lua cierra (muerto, esposado, otro juego encima): sin rotulo ni resultado,
     que el resultado ya lo ha dado el. */
  function cerrar() {
    var p = partida
    if (!p) return
    p.terminada = true
    limpiar(p)
    ocultar(p)
  }

  function devolver(clave, exito, turno) {
    try {
      var yo = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null
      if (!yo) return
      fetch('https://' + yo + '/nuevoResultado', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ juego: clave, exito: exito === true, turno: turno }),
      }).catch(function () {})
    } catch (e) {}
  }

  /* ── Teclado ──────────────────────────────────────────────────────── */
  window.addEventListener('keydown', function (e) {
    var p = partida
    if (!p || p.terminada) return
    if (e.code === 'Escape') {
      e.preventDefault()
      acabar(p, false)
      return
    }
    /* Espacio y flechas mueven la pagina; aqui son del juego. */
    if (e.code === 'Space' || e.code.indexOf('Arrow') === 0 || e.code === 'Tab') e.preventDefault()
    var repetida = p.pulsadas[e.code] === true
    p.pulsadas[e.code] = true
    for (var i = 0; i < p.teclas.length; i++) p.teclas[i](e.code, true, e, repetida)
  })

  window.addEventListener('keyup', function (e) {
    var p = partida
    if (!p || p.terminada) return
    p.pulsadas[e.code] = false
    for (var i = 0; i < p.teclas.length; i++) p.teclas[i](e.code, false, e, false)
  })

  /* Si la ventana pierde el foco, ninguna tecla se queda «pulsada». */
  window.addEventListener('blur', function () {
    if (partida) partida.pulsadas = {}
  })

  window.addEventListener('message', function (e) {
    var d = e.data
    if (!d || typeof d !== 'object') return
    if (d.action === 'nuevoEmpezar') empezar(d.juego, d.config, { titulo: d.titulo, volumen: d.volumen, turno: d.turno })
    else if (d.action === 'nuevoCerrar') cerrar()
  })

  var OrigenMJ = window.OrigenMJ = {
    registrar: function (clave, def) { JUEGOS[clave] = def },
    empezar: empezar,
    cerrar: cerrar,
    juegos: function () { return Object.keys(JUEGOS) },
    volumen: function () { return volumen },
    /* Utiles que usan varios juegos. */
    util: {
      azar: function (a, b) { return a + Math.random() * (b - a) },
      entero: function (a, b) { return Math.floor(a + Math.random() * (b - a + 1)) },
      tope: function (v, a, b) { return Math.max(a, Math.min(b, v)) },
      barajar: function (lista) {
        var copia = lista.slice()
        for (var i = copia.length - 1; i > 0; i--) {
          var j = Math.floor(Math.random() * (i + 1))
          var t = copia[i]; copia[i] = copia[j]; copia[j] = t
        }
        return copia
      },
      svg: function (etiqueta, atributos, padre) {
        var nodo = document.createElementNS('http://www.w3.org/2000/svg', etiqueta)
        for (var k in atributos) nodo.setAttribute(k, atributos[k])
        if (padre) padre.appendChild(nodo)
        return nodo
      },
      /* Un lienzo que ocupa su caja, nitido en pantallas densas. */
      lienzo: function (caja) {
        var c = document.createElement('canvas')
        c.className = 'mj-lienzo'
        caja.appendChild(c)
        var r = caja.getBoundingClientRect()
        var escala = Math.min(2, window.devicePixelRatio || 1)
        var ancho = Math.max(50, Math.round(r.width))
        var alto = Math.max(50, Math.round(r.height))
        c.width = Math.round(ancho * escala)
        c.height = Math.round(alto * escala)
        var g = c.getContext('2d')
        g.setTransform(escala, 0, 0, escala, 0, 0)
        return { nodo: c, g: g, ancho: ancho, alto: alto }
      },
      /* Los colores salen del tema, no van escritos. */
      color: function (nombre, porDefecto) {
        var v = getComputedStyle(document.documentElement).getPropertyValue(nombre)
        return (v && v.trim()) || porDefecto
      },
    },
  }
})()
