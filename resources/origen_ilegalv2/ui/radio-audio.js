(() => {
  const sTalkOn = new Audio('sounds/walkieon.mp3')
  const sTalkOff = new Audio('sounds/walkieoff.mp3')

  sTalkOn.volume = 0.5
  sTalkOff.volume = 0.3

  const play = (audio) => {
    try {
      audio.currentTime = 0
      const maybePromise = audio.play()
      if (maybePromise && typeof maybePromise.catch === 'function') {
        maybePromise.catch(() => {})
      }
    } catch (_) {}
  }

  window.addEventListener('message', (event) => {
    const data = event.data || {}
    if (data.action !== 'radioTalkSound') return

    if (data.state === 'on') {
      play(sTalkOn)
      return
    }

    if (data.state === 'off') {
      play(sTalkOff)
    }
  })
})()
