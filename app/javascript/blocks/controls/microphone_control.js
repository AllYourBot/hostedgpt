import Control from "./control.js"

export default class extends Control {
  logLevel_info

  Flip(on)            { if (on && !$.active) {
                          $.active = true
                          $.microphoneService.start()
                          Flip.Transcriber.on()
                        } else if (!on && $.active) {
                          $.active = false
                          $.microphoneService.stop()
                          Flip.Transcriber.off()
                        }
                      }

  log_SpeakInto
  SpeakInto(num)      { $.volume = num
                        // $.volumeBuffer.push(num)
                        // if ($.volumeBuffer.length > 6) $.volumeBuffer.shift()
                        $.msOfSilence = 0

                        if (!$.poller) $.poller = runEvery(0.2, () => { $.msOfSilence += 200 })
                      }

  attr_volume         = 0
  attr_msOfSilence    = 0
  attr_active         = false

  get on()            { return $.active }
  get off()           { return !$.active }

  new() {
    $.microphoneService = new MicrophoneService
    $.microphoneService.onVolumeChanged = (num) => {
      if (num > 2)
      SpeakInto.Microphone.at.volume(num)
    }
  }

  finalize() {
    $.poller?.stop()
  }
}
