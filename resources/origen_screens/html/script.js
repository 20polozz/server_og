/* origen_screens · el mando de las teles, y los paneles de admin.
   Todo lo que se pulsa aquí lo vuelve a comprobar el servidor: esta página
   solo enseña y pide. */
(function () {
  'use strict'

  var $ = function (id) { return document.getElementById(id) }
  var recurso = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'origen_screens'

  function post (nombre, datos) {
    return fetch('https://' + recurso + '/' + nombre, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(datos || {})
    }).then(function (r) { return r.json() }).catch(function () { return null })
  }

  var app = $('app-container')
  var paneles = ['mando', 'ajustes', 'crear', 'admin']
  // Las tres de admin van dentro de la gestión a pantalla completa (#gestion),
  // cada una con su título y su botón del riel.
  var GESTION = {
    admin: { titulo: 'Pantallas y teles', brocha: 'Qué se ve en cada una', riel: 'admin' },
    crear: { titulo: 'Nueva pantalla', brocha: 'Colócala en el mundo', riel: 'crear' },
    ajustes: { titulo: 'Ajustes de la pantalla', brocha: 'Quién la controla', riel: 'admin' }
  }

  function mostrar (panel) {
    app.hidden = !panel
    paneles.forEach(function (p) { $(p).hidden = p !== panel })
    // El mando entra deslizándose: se enseña fuera de sitio y al fotograma
    // siguiente se pone dentro, para que haya transición.
    var mando = $('mando')
    mando.classList.remove('esta-dentro')
    if (panel === 'mando') {
      requestAnimationFrame(function () {
        requestAnimationFrame(function () { mando.classList.add('esta-dentro') })
      })
    }
    var g = GESTION[panel]
    $('gestion').hidden = !g
    if (g) {
      $('g-titulo').textContent = g.titulo
      $('g-titulo').dataset.brocha = g.brocha
      document.querySelectorAll('[data-ir]').forEach(function (b) {
        b.classList.toggle('is-on', b.dataset.ir === g.riel)
      })
    }
  }

  // Las cifras de la barra salen de la última lista que mandó el servidor.
  function pintarBarra (lista) {
    if (!lista) return
    var n = function (f) { return String(lista.filter(f).length) }
    $('g-n').textContent = String(lista.length)
    $('g-cuenta').textContent = String(lista.length)
    $('g-antena').textContent = n(function (p) { return p.encendida && !p.hidden })
    $('g-ocultas').textContent = n(function (p) { return p.hidden })
    $('g-pared').textContent = n(function (p) { return p.modo !== 'prop' })
  }

  document.querySelectorAll('[data-ir]').forEach(function (b) {
    b.addEventListener('click', function () {
      if (b.dataset.ir === 'crear') abrirCrear()
      else post('adminLista')
    })
  })

  function cerrar () {
    mostrar(null)
    post('cerrar')
  }

  document.querySelectorAll('[data-cerrar]').forEach(function (b) { b.addEventListener('click', cerrar) })
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && !app.hidden) cerrar()
  })

  // ════════════════════════════════════════════════════════════════
  //  El mando
  // ════════════════════════════════════════════════════════════════
  var estado = { encendida: false }
  var ocupado = false
  var temporizadorMsg = null

  function mensaje (texto, tipo) {
    var m = $('m-msg')
    m.textContent = texto || ''
    m.dataset.tipo = tipo || ''
    clearTimeout(temporizadorMsg)
    if (texto) temporizadorMsg = setTimeout(function () { m.textContent = '' }, 5000)
  }

  //  Tele de casa o pantalla: va en el renglón de la cabecera.
  var esCasa = false

  function pintarEstado (st) {
    estado = st || { encendida: false }
    var antena = $('m-antena')
    var enc = !!estado.encendida

    antena.dataset.estado = !enc ? 'apagada' : (estado.pausado ? 'pausa' : 'antena')
    $('m-rotulo').textContent = !enc ? 'Apagada' : (estado.pausado ? 'En pausa' : 'En antena')

    var fuente = ''
    if (enc) {
      if (estado.tipo === 'youtube') fuente = 'YouTube'
      else fuente = estado.clase === 'directo' ? 'Twitch · directo' : 'Twitch · vídeo'
    }
    $('m-fuente').textContent = fuente
    $('m-url').textContent = enc ? estado.url : ''
    // El renglón de la cabecera: el estado, lo que suena y qué tele es.
    $('m-renglon').textContent = [$('m-rotulo').textContent, fuente, esCasa ? 'Tele de casa' : 'Pantalla']
      .filter(function (t) { return t }).join(' · ')

    $('m-pausa').disabled = !enc
    $('m-apagar').disabled = !enc
    $('m-volumen').disabled = !enc
    $('m-pausa').textContent = enc && estado.pausado ? 'Seguir' : 'Pausar'
    // En un directo no hay principio al que volver.
    $('m-reiniciar').hidden = enc && estado.clase === 'directo'
    $('m-reiniciar').disabled = !enc

    if (enc && document.activeElement !== $('m-volumen')) {
      $('m-volumen').value = estado.volumen
      $('m-volumen-val').textContent = estado.volumen + '%'
    }
  }

  function orden (accion, dato) {
    if (ocupado) return Promise.resolve(null)
    ocupado = true
    return post('mando', { accion: accion, dato: dato }).then(function (r) {
      ocupado = false
      if (r && r.msg) mensaje(r.msg, r.ok ? 'ok' : 'error')
      else if (!r || !r.ok) mensaje(r && r.msg ? r.msg : '', 'error')
      return r
    })
  }

  function poner () {
    var enlace = $('m-enlace').value.trim()
    if (!enlace) { mensaje('Pega un enlace de YouTube o Twitch', 'error'); $('m-enlace').focus(); return }
    $('m-poner').disabled = true
    orden('poner', enlace).then(function (r) {
      $('m-poner').disabled = false
      if (r && r.ok) $('m-enlace').value = ''
    })
  }

  $('m-poner').addEventListener('click', poner)
  $('m-enlace').addEventListener('keydown', function (e) { if (e.key === 'Enter') poner() })
  $('m-pausa').addEventListener('click', function () { orden(estado.pausado ? 'seguir' : 'pausa') })
  $('m-reiniciar').addEventListener('click', function () { orden('reiniciar') })
  $('m-apagar').addEventListener('click', function () { orden('apagar') })
  $('m-volumen').addEventListener('input', function () { $('m-volumen-val').textContent = this.value + '%' })
  // Se manda al soltar, no mientras se arrastra: el servidor lleva ritmo.
  $('m-volumen').addEventListener('change', function () { orden('volumen', Number(this.value)) })
  $('m-ajustes').addEventListener('click', function () { post('ajustes') })

  // ════════════════════════════════════════════════════════════════
  //  Ajustes de una pantalla (admin)
  // ════════════════════════════════════════════════════════════════
  var ajustesId = null
  var ajustesOculta = false

  function pintarOcultar () {
    var b = $('a-ocultar')
    b.textContent = ajustesOculta ? 'Mostrar pantalla' : 'Ocultar pantalla'
    b.classList.toggle('active-visibility', !ajustesOculta)
  }

  function abrirAjustes (d) {
    ajustesId = d.id
    ajustesOculta = !!d.hidden
    $('a-nombre').value = d.name || ''
    $('a-trabajos').value = d.job || ''
    $('a-negocio').value = d.negocio || ''
    $('a-marcador').checked = !!d.hideMarker
    $('a-marcador').closest('.sc-casilla').hidden = d.modo === 'prop'
    pintarOcultar()
    mostrar('ajustes')
  }

  $('a-ocultar').addEventListener('click', function () {
    if (!ajustesId) return
    ajustesOculta = !ajustesOculta
    pintarOcultar()
    post('ocultar', { id: ajustesId })
  })

  $('a-guardar').addEventListener('click', function () {
    if (!ajustesId) return
    post('guardarAjustes', {
      id: ajustesId,
      name: $('a-nombre').value,
      job: $('a-trabajos').value,
      negocio: $('a-negocio').value,
      hideMarker: $('a-marcador').checked
    })
    mostrar(null)
  })

  // ════════════════════════════════════════════════════════════════
  //  Colocar una pantalla (admin)
  // ════════════════════════════════════════════════════════════════
  var modo = 'prop'
  var NOTAS = {
    prop: 'Apuntas a una tele que ya existe y el vídeo sale en su pantalla.',
    pared: 'Marcas dos esquinas en una pared y el punto donde se usa el mando.'
  }

  function elegirModo (m) {
    modo = m
    document.querySelectorAll('[data-modo]').forEach(function (b) {
      b.classList.toggle('active', b.dataset.modo === m)
    })
    $('c-nota-modo').textContent = NOTAS[m]
    document.querySelector('.sc-solo-pared').hidden = m !== 'pared'
  }

  document.querySelectorAll('[data-modo]').forEach(function (b) {
    b.addEventListener('click', function () { elegirModo(b.dataset.modo) })
  })
  $('c-volumen').addEventListener('input', function () { $('c-volumen-val').textContent = this.value + '%' })

  $('c-empezar').addEventListener('click', function () {
    post('empezarColocacion', {
      modo: modo,
      name: $('c-nombre').value,
      job: $('c-trabajos').value,
      negocio: $('c-negocio').value,
      volume: Number($('c-volumen').value),
      hideMarker: $('c-marcador').checked,
      usePolyzone: $('c-zona').checked
    })
    mostrar(null)
  })

  function abrirCrear () {
    $('c-nombre').value = ''
    $('c-trabajos').value = ''
    $('c-negocio').value = ''
    $('c-volumen').value = 50
    $('c-volumen-val').textContent = '50%'
    $('c-marcador').checked = false
    $('c-zona').checked = true
    elegirModo('prop')
    mostrar('crear')
  }

  // ════════════════════════════════════════════════════════════════
  //  Lista (admin)
  // ════════════════════════════════════════════════════════════════
  function celda (fila, texto, clase) {
    var td = document.createElement('td')
    if (clase) td.className = clase
    if (texto != null) td.textContent = texto
    fila.appendChild(td)
    return td
  }

  function boton (padre, texto, alPulsar, clase) {
    var b = document.createElement('button')
    b.className = 'btn-table-action' + (clase ? ' ' + clase : '')
    b.textContent = texto
    b.addEventListener('click', alPulsar)
    padre.appendChild(b)
    return b
  }

  function abrirLista (lista) {
    var cuerpo = $('lista')
    cuerpo.innerHTML = ''
    pintarBarra(lista || [])
    if (!lista || !lista.length) {
      var vacia = document.createElement('tr')
      var td = celda(vacia, 'No hay pantallas colocadas')
      td.colSpan = 4
      cuerpo.appendChild(vacia)
      mostrar('admin')
      return
    }

    lista.forEach(function (p) {
      var fila = document.createElement('tr')

      var nombre = celda(fila)
      var strong = document.createElement('strong')
      strong.textContent = p.name || 'Sin nombre'
      nombre.appendChild(strong)
      nombre.appendChild(document.createElement('br'))
      var small = document.createElement('small')
      small.textContent = (p.modo === 'prop' ? 'Tele del mapa · ' : 'Pared · ') + p.id
      nombre.appendChild(small)

      var control = []
      if (p.job) control.push(p.job)
      if (p.negocio) control.push('negocio ' + p.negocio)
      celda(fila, control.length ? control.join(' · ') : 'Solo admins')

      var est = celda(fila)
      var chapa = document.createElement('span')
      chapa.className = 'status-badge'
      var punto = document.createElement('span')
      punto.className = 'status-dot' + (p.encendida ? ' active' : '')
      chapa.appendChild(punto)
      chapa.appendChild(document.createTextNode(p.hidden ? 'Oculta' : (p.encendida ? 'En antena' : 'Apagada')))
      est.appendChild(chapa)

      var acciones = celda(fila)
      var grupo = document.createElement('div')
      grupo.className = 'action-btn-group'
      acciones.appendChild(grupo)
      boton(grupo, 'Ir', function () { post('adminIr', { id: p.id }); mostrar(null) })
      boton(grupo, 'Mando', function () { post('adminMando', { id: p.id }); mostrar(null) })
      boton(grupo, 'Ajustes', function () { post('adminAjustes', { id: p.id }) })
      // Borrar pide un segundo clic: no hay vuelta atrás.
      var borrar = boton(grupo, 'Eliminar', function () {
        if (!borrar.dataset.seguro) {
          borrar.dataset.seguro = '1'
          borrar.textContent = '¿Seguro?'
          setTimeout(function () { delete borrar.dataset.seguro; borrar.textContent = 'Eliminar' }, 3000)
          return
        }
        post('borrar', { id: p.id })
        fila.remove()
      }, 'btn-table-delete')

      cuerpo.appendChild(fila)
    })
    mostrar('admin')
  }

  // ════════════════════════════════════════════════════════════════
  //  Mensajes de Lua
  // ════════════════════════════════════════════════════════════════
  window.addEventListener('message', function (e) {
    var d = e.data
    if (!d || typeof d.accion !== 'string') return

    if (d.accion === 'mando') {
      $('m-nombre').textContent = d.nombre || 'Tele'
      $('m-clase').textContent = 'Mando'
      esCasa = !!d.casa
      $('m-ajustes').hidden = !d.admin || d.casa
      $('m-enlace').value = ''
      mensaje('')
      pintarEstado(d.estado)
      mostrar('mando')
      setTimeout(function () { $('m-enlace').focus() }, 50)
    } else if (d.accion === 'estado') {
      pintarEstado(d.estado)
    } else if (d.accion === 'ajustes') {
      abrirAjustes(d.datos || {})
    } else if (d.accion === 'crear') {
      abrirCrear()
    } else if (d.accion === 'admin') {
      abrirLista(d.lista)
    } else if (d.accion === 'cerrar') {
      mostrar(null)
    }
  })
})()
