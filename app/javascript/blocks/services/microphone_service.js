import Service from "./service.js"

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
      $.audioContext = new AudioContext()
      $.audioSource = $.audioContext.createMediaStreamSource($.stream)
      $.audioProcessor = $.audioContext.createScriptProcessor(2048, 1, 1)
      $.audioSource.connect($.audioProcessor)
      $.audioProcessor.connect($.audioContext.destination)

      $.audioProcessor.onaudioprocess = (event) => processVolume(event)
      $.active = true
      $.volume = 0
    } catch (error) {
      console.error('Error initializing audio', error)
    }
  }

  log_end
  end() {
    if ($.audioProcessor) $.audioProcessor.disconnect()
    if ($.audioSource) $.audioSource.disconnect()
    if ($.audioContext) $.audioContext.close()
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
