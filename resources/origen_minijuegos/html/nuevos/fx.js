/* LOS MINIJUEGOS NUEVOS · efectos
 *
 * Lo que hace lucir a los juegos grandes: un escenario sobre lienzo con
 * particulas (chispas, fuego, humo), trazos de neon, temblor de camara y un
 * fondo de rejilla. Sin shadowBlur —en el CEF del juego es carisimo—: el
 * brillo se hace pintando el mismo trazo tres veces en modo 'lighter'.
 */
(function () {
  'use strict'

  var MJ = window.OrigenMJ
  var U = MJ.util

  var COLOR = {
    rosa: '#d81b55', cian: '#35e0ff', verde: '#3ce6a4', ambar: '#ffb02e',
    rojo: '#ff4545', blanco: '#f5f0e6', gris: '#5d6b7a', fondo: '#06080c',
  }

  function escenario(ctx) {
    var L = U.lienzo(ctx.zona)
    var g = L.g
    var E = {
      g: g, W: L.ancho, H: L.alto, nodo: L.nodo, t: 0,
      particulas: [], temblor: 0, destello: 0, colorDestello: '#ffffff',
    }

    /* ── Particulas ──────────────────────────────────────────────── */
    E.chispas = function (x, y, n, o) {
      o = o || {}
      if (E.particulas.length > 700) return
      for (var i = 0; i < n; i++) {
        var a = o.angulo !== undefined ? o.angulo + (Math.random() - 0.5) * (o.abanico || 1) : Math.random() * Math.PI * 2
        var v = (o.fuerza || 160) * (0.35 + Math.random() * 0.9)
        E.particulas.push({
          x: x, y: y, vx: Math.cos(a) * v, vy: Math.sin(a) * v,
          vida: 0, dura: (o.dura || 0.6) * (0.5 + Math.random() * 0.8),
          color: o.color || COLOR.ambar, gordo: o.gordo || 2,
          gravedad: o.gravedad === undefined ? 380 : o.gravedad,
          tipo: o.tipo || 'chispa',
        })
      }
    }

    E.fuego = function (x, y, n, ancho) {
      if (E.particulas.length > 700) return
      for (var i = 0; i < n; i++) {
        E.particulas.push({
          x: x + (Math.random() - 0.5) * (ancho || 10), y: y,
          vx: (Math.random() - 0.5) * 36, vy: -70 - Math.random() * 110,
          vida: 0, dura: 0.45 + Math.random() * 0.6, gordo: 5 + Math.random() * 8,
          gravedad: -60, tipo: 'fuego',
        })
      }
    }

    E.sacudir = function (fuerza) { E.temblor = Math.max(E.temblor, fuerza) }
    E.destellar = function (color, fuerza) { E.colorDestello = color; E.destello = Math.max(E.destello, fuerza || 0.5) }

    /* ── Un fotograma: abrir (fondo + temblor) y cerrar (particulas + destello) ── */
    E.abrir = function (dt, rejilla) {
      E.t += dt
      g.setTransform(L.nodo.width / L.ancho, 0, 0, L.nodo.height / L.alto, 0, 0)
      g.globalCompositeOperation = 'source-over'
      g.globalAlpha = 1
      g.fillStyle = COLOR.fondo
      g.fillRect(0, 0, E.W, E.H)
      g.save()
      if (E.temblor > 0.2) {
        g.translate((Math.random() - 0.5) * E.temblor, (Math.random() - 0.5) * E.temblor)
        E.temblor *= Math.pow(0.0015, dt)
      } else E.temblor = 0
      if (rejilla !== false) {
        g.strokeStyle = 'rgba(53, 224, 255, 0.055)'
        g.lineWidth = 1
        g.beginPath()
        var paso = E.H / 14
        var corre = (E.t * 8) % paso
        for (var x = corre; x < E.W; x += paso) { g.moveTo(x, 0); g.lineTo(x, E.H) }
        for (var y = corre; y < E.H; y += paso) { g.moveTo(0, y); g.lineTo(E.W, y) }
        g.stroke()
      }
    }

    E.cerrar = function (dt) {
      g.globalCompositeOperation = 'lighter'
      for (var i = E.particulas.length - 1; i >= 0; i--) {
        var p = E.particulas[i]
        p.vida += dt
        if (p.vida >= p.dura) { E.particulas.splice(i, 1); continue }
        p.vy += p.gravedad * dt
        p.x += p.vx * dt
        p.y += p.vy * dt
        var k = 1 - p.vida / p.dura
        if (p.tipo === 'fuego') {
          g.globalAlpha = k * 0.55
          g.fillStyle = k > 0.6 ? '#ffe9a8' : (k > 0.3 ? '#ff9a2e' : '#d8341c')
          g.beginPath()
          g.arc(p.x, p.y, p.gordo * (0.4 + k * 0.8), 0, Math.PI * 2)
          g.fill()
        } else {
          g.globalAlpha = k
          g.strokeStyle = p.color
          g.lineWidth = p.gordo * k + 0.4
          g.beginPath()
          g.moveTo(p.x, p.y)
          g.lineTo(p.x - p.vx * 0.035, p.y - p.vy * 0.035)
          g.stroke()
        }
      }
      g.globalAlpha = 1
      g.globalCompositeOperation = 'source-over'
      g.restore()
      if (E.destello > 0.01) {
        g.globalAlpha = Math.min(0.6, E.destello)
        g.fillStyle = E.colorDestello
        g.fillRect(0, 0, E.W, E.H)
        g.globalAlpha = 1
        E.destello *= Math.pow(0.002, dt)
      }
    }

    /* ── Trazos de neon: `traza(g)` solo hace el camino (moveTo/lineTo/arc) ── */
    E.neon = function (traza, color, ancho, fuerza) {
      var f = fuerza === undefined ? 1 : fuerza
      g.save()
      g.globalCompositeOperation = 'lighter'
      g.lineCap = 'round'
      g.lineJoin = 'round'
      g.strokeStyle = color
      g.globalAlpha = 0.12 * f; g.lineWidth = ancho * 5; g.beginPath(); traza(g); g.stroke()
      g.globalAlpha = 0.3 * f; g.lineWidth = ancho * 2.4; g.beginPath(); traza(g); g.stroke()
      g.globalAlpha = Math.min(1, f); g.lineWidth = ancho; g.beginPath(); traza(g); g.stroke()
      g.restore()
    }

    E.halo = function (x, y, radio, color, fuerza) {
      var grad = g.createRadialGradient(x, y, 0, x, y, radio)
      grad.addColorStop(0, color)
      grad.addColorStop(1, 'rgba(0,0,0,0)')
      g.save()
      g.globalCompositeOperation = 'lighter'
      g.globalAlpha = fuerza === undefined ? 0.6 : fuerza
      g.fillStyle = grad
      g.beginPath()
      g.arc(x, y, radio, 0, Math.PI * 2)
      g.fill()
      g.restore()
    }

    E.texto = function (txt, x, y, tam, color, alinear, fuente) {
      g.font = (fuente === 'mono' ? '800 ' : 'italic 700 ') + tam + 'px ' + (fuente === 'mono' ? '"Oxanium", "Barlow Condensed", sans-serif' : '"Barlow Condensed", "Arial Narrow", sans-serif')
      g.textAlign = alinear || 'center'
      g.textBaseline = 'middle'
      g.fillStyle = color || COLOR.blanco
      g.fillText(txt, x, y)
    }

    E.raton = function (e) {
      var r = L.nodo.getBoundingClientRect()
      return { x: (e.clientX - r.left) * E.W / r.width, y: (e.clientY - r.top) * E.H / r.height }
    }

    return E
  }

  MJ.fx = { escenario: escenario, COLOR: COLOR }
})()
