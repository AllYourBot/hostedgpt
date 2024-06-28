import Service from "../service.js"

export default class extends Service {
  logLevel_info
  attrReader_volume
  attrAccessor_onVolumeChanged

  log_start
  async start() {
    if ($.active || typeof window === 'undefined') return

    try {
      const AudioContext = window.AudioContext || window.webkitAudioContext
      $.stream = await navigator.mediaDevices.getUserMedia({ audio: true, echoCancellation: true, noiseSuppression: true })
      if (!$.audioContext) $.audioContext = new AudioContext()
      $.microphoneSource = $.audioContext.createMediaStreamSource($.stream)
      $.audioProcessor = $.audioContext.createScriptProcessor(2048, 1, 1)
      $.microphoneSource.connect($.audioProcessor)
      $.audioProcessor.connect($.audioContext.destination)

      $.audioVisualizer = $.audioContext.createAnalyser()
      $.microphoneSource.connect($.audioVisualizer)
      $.audioVisualizer.fftSize = 1024
      $.audioVisualizerDataArray = new Uint8Array($.audioVisualizer.frequencyBinCount)

      if ($.playerToAttach) _attachPlayer()

      $.audioProcessor.onaudioprocess = (event) => processVolume(event)
      $.active = true
      $.volume = 0
    } catch (error) {
      console.error('Error initializing audio', error)
    }
  }

  attach(player) {
    $.playerToAttach = player
    _attachPlayer()
  }

  _attachPlayer() {
    if (!$.playerToAttach || !$.audioContext) return

    $.playerSource = $.audioContext.createMediaElementSource($.playerToAttach)
    $.playerSource.connect($.audioVisualizer)
    $.playerSource.connect($.audioContext.destination)
    $.playerToAttach = null
  }

  async end() {
    if ($.audioProcessor) $.audioProcessor.disconnect()
    if ($.microphoneSource) $.microphoneSource.disconnect()
    if ($.playerSource) $.playerSource.disconnect($.audioVisualizer)
    if ($.audioVisualizer) $.audioVisualizer.disconnect()
    //if ($.audioContext) $.audioContext.close()  This inadvertently stops the player, we'll re-use this context
    if ($.stream) $.stream.getTracks().forEach(track => track.stop())

    $.active = false
    $.volume = null
  }

  processVolume(event) {
    if (!$.active) return

    const inputs = Array.from(event.inputBuffer.getChannelData(0))
    const sum = inputs.map(input => input*input).sum()
    const newVolume = (Math.sqrt(sum / inputs.length) * 100).round()

    if ($.onVolumeChanged && newVolume != $.volume) $.onVolumeChanged(newVolume)
    $.volume = newVolume
  }
}
