import {
  OrthographicCamera,
  Scene,
  WebGLRenderTarget,
  LinearFilter,
  NearestFilter,
  RGBAFormat,
  UnsignedByteType,
  CfxTexture,
  ShaderMaterial,
  PlaneBufferGeometry,
  Mesh,
  WebGLRenderer
} from './module/Three.js'

class GameRender {
  constructor() {
    this.isActive = false
    this.canvas = null
    this.customCamRatio = false
    this.screenLeft = 0
    this.captureOpts = null
    this.imageData = null
    this.rtWidth = 0
    this.rtHeight = 0
    this._loopHandle = null
    this._loopKind = null

    this.cameraRTT = new OrthographicCamera(
      window.innerWidth / -2,
      window.innerWidth / 2,
      window.innerHeight / 2,
      window.innerHeight / -2,
      -10000,
      10000
    )
    this.cameraRTT.position.z = 0
    this.cameraRTT.setViewOffset(window.innerWidth, window.innerHeight, 0, 0, window.innerWidth, window.innerHeight)

    this.sceneRTT = new Scene()

    const gameTexture = new CfxTexture()
    gameTexture.needsUpdate = true

    this.material = new ShaderMaterial({
      uniforms: { tDiffuse: { value: gameTexture } },
      vertexShader: `
        varying vec2 vUv;
        void main() {
          vUv = vec2(uv.x, 1.0 - uv.y);
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        varying vec2 vUv;
        uniform sampler2D tDiffuse;
        void main() {
          gl_FragColor = texture2D(tDiffuse, vUv);
        }
      `
    })

    const plane = new PlaneBufferGeometry(window.innerWidth, window.innerHeight)
    const quad = new Mesh(plane, this.material)
    quad.position.z = -100
    this.sceneRTT.add(quad)

    this.renderer = new WebGLRenderer({ powerPreference: 'low-power' })
    this.renderer.setPixelRatio(1)
    this.renderer.setSize(window.innerWidth, window.innerHeight)
    this.renderer.autoClear = false

    this.rtTexture = new WebGLRenderTarget(window.innerWidth, window.innerHeight, {
      minFilter: LinearFilter,
      magFilter: NearestFilter,
      format: RGBAFormat,
      type: UnsignedByteType
    })

    const appendArea = document.createElement('div')
    appendArea.id = 'origen-pantalla-render'
    appendArea.style.display = 'none'
    appendArea.appendChild(this.renderer.domElement)
    document.body.appendChild(appendArea)

    this._captureTick = this._captureTick.bind(this)
    this.resize = this.resize.bind(this)

    window.addEventListener('resize', this.resize)
  }

  _clearSchedule() {
    if (this._loopHandle == null) return
    if (this._loopKind === 'raf') {
      cancelAnimationFrame(this._loopHandle)
    } else {
      clearTimeout(this._loopHandle)
    }
    this._loopHandle = null
    this._loopKind = null
  }

  _scheduleNextCapture() {
    if (!this.isActive || !this.canvas) return

    const fr = this.captureOpts && this.captureOpts.frameRate
    if (fr) {
      const ms = Math.max(8, Math.round(1000 / fr))
      this._loopKind = 'timeout'
      this._loopHandle = setTimeout(this._captureTick, ms)
      return
    }

    this._loopKind = 'raf'
    this._loopHandle = requestAnimationFrame(this._captureTick)
  }

  _getViewRect() {
    const fullW = window.innerWidth
    const fullH = window.innerHeight
    let subW = fullW
    let subH = fullH
    let subX = 0
    if (this.customCamRatio) {
      subW = Math.floor(fullH * this.customCamRatio)
      subX = this.screenLeft
    }
    return { fullW, fullH, subW, subH, subX }
  }

  _getOutputSize(subW, subH) {
    const o = this.captureOpts
    if (!o || (o.maxWidth == null && o.maxHeight == null)) {
      return { outW: subW, outH: subH }
    }
    const mw = o.maxWidth != null ? o.maxWidth : subW
    const mh = o.maxHeight != null ? o.maxHeight : subH
    const scale = Math.min(mw / subW, mh / subH, 1)
    return {
      outW: Math.max(1, Math.floor(subW * scale)),
      outH: Math.max(1, Math.floor(subH * scale))
    }
  }

  _rebuildPipeline() {
    if (this.rtTexture) {
      this.rtTexture.dispose()
    }

    const { fullW, fullH, subW, subH, subX } = this._getViewRect()
    const { outW, outH } = this._getOutputSize(subW, subH)
    this.rtWidth = outW
    this.rtHeight = outH

    this.cameraRTT = new OrthographicCamera(
      fullW / -2,
      fullW / 2,
      fullH / 2,
      fullH / -2,
      -10000,
      10000
    )
    this.cameraRTT.position.z = 100
    this.cameraRTT.setViewOffset(fullW, fullH, subX, 0, subW, subH)
    this.cameraRTT.zoom = 0.1

    this.sceneRTT = new Scene()
    const plane = new PlaneBufferGeometry(fullW, fullH)
    const quad = new Mesh(plane, this.material)
    quad.position.z = -100
    this.sceneRTT.add(quad)

    this.rtTexture = new WebGLRenderTarget(outW, outH, {
      minFilter: LinearFilter,
      magFilter: NearestFilter,
      format: RGBAFormat,
      type: UnsignedByteType
    })

    this.renderer.setSize(outW, outH)

    if (!this.imageData || this.imageData.width !== outW || this.imageData.height !== outH) {
      this.imageData = null
    }
  }

  resize() {
    if (!this.isActive) return
    this._rebuildPipeline()
  }

  _captureTick() {
    this._loopHandle = null
    this._loopKind = null

    if (!this.isActive || !this.canvas) return

    const w = this.rtWidth
    const h = this.rtHeight
    if (w < 1 || h < 1) {
      return
    }

    if (!this.imageData || this.imageData.width !== w || this.imageData.height !== h) {
      this.imageData = new ImageData(w, h)
    }

    this.renderer.clear()
    this.renderer.render(this.sceneRTT, this.cameraRTT, this.rtTexture, true)
    this.renderer.readRenderTargetPixels(this.rtTexture, 0, 0, w, h, this.imageData.data)

    if (this.canvas.width !== w || this.canvas.height !== h) {
      this.canvas.width = w
      this.canvas.height = h
    }

    const ctx = this.canvas.getContext('2d')
    if (ctx) {
      ctx.putImageData(this.imageData, 0, 0)
    }

    this._scheduleNextCapture()
  }

  renderToTarget(element, ratio, left, opts) {
    this._clearSchedule()

    if (opts && typeof opts === 'object') {
      const fr = Number(opts.frameRate)
      const mw = Number(opts.maxWidth)
      const mh = Number(opts.maxHeight)
      const hasCap = (Number.isFinite(mw) && mw > 0) || (Number.isFinite(mh) && mh > 0)
      let capFr = Number.isFinite(fr) ? Math.max(5, Math.min(60, fr)) : null
      if (capFr == null && hasCap) {
        capFr = 20
      }
      this.captureOpts = {
        frameRate: capFr,
        maxWidth: Number.isFinite(mw) && mw > 0 ? Math.floor(mw) : null,
        maxHeight: Number.isFinite(mh) && mh > 0 ? Math.floor(mh) : null
      }
    } else {
      this.captureOpts = null
    }

    if (ratio) {
      this.customCamRatio = ratio
      this.screenLeft = left || 0
    }

    this._rebuildPipeline()
    this.canvas = element
    this.isActive = true
    this._captureTick()
  }

  stop() {
    this._clearSchedule()
    this.isActive = false
    this.captureOpts = null
    if (this.rtTexture) {
      this.rtTexture.dispose()
      this.rtTexture = null
    }
    this.rtWidth = 0
    this.rtHeight = 0
    this.imageData = null
  }
}

window.OrigenPantallaRender = new GameRender()
