import ReadableModel from "../readable_model.js"

export default class extends ReadableModel {
  log_info
  attrReader_volume
  attrAccessor_onVolumeChanged

  log_start
  async start() {
    if ($.active || typeof window === 'undefined') return

    try {
      const AudioContext = window.AudioContext || window.webkitAudioContext
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true, echoCancellation: true, noiseSuppression: true })

      $.audioContext = new AudioContext()
      $.audioListener = $.audioContext.createMediaStreamSource(stream)
      $.audioProcessor = $.audioContext.createScriptProcessor(2048, 1, 1)
      $.audioListener.connect($.audioProcessor)
      $.audioProcessor.connect($.audioContext.destination)

      $.audioProcessor.onaudioprocess = (event) => processVolume(event)
      $.active = true
      $.volume = 0
    } catch (error) {
      console.error('Error initializing audio', error)
    }
  }

  log_stop
  stop() {
    if ($.audioContext) $.audioContext.close()
    if ($.audioListener) $.audioListener.disconnect()
    if ($.audioProcessor) $.audioProcessor.disconnect()

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
