import Control from "./control.js"

export default class extends Control {
  logLevel_info

  SpeakInto(num)      { $.volume = num
                        $.msOfSilence = 0
                        if (!$.poller) $.poller = runEvery(0.2, () => { $.msOfSilence += 200 })
                      }
  Enable()            { $.status = 'on';  $.microphoneService.start() }
  Disable()           { $.status = 'off'; $.microphoneService.stop() }

  attr_volume         = 0
  attr_status         = 'off'
  attr_msOfSilence    = 0

  get on()            { return $.status == 'on' }
  get off()           { return $.status == 'off' }

  new() {
    $.microphoneService = new MicrophoneService
    $.microphoneService.onVolumeChanged = (num) => { if (num > 2) SpeakInto(num) }
    // SpeakInto.Microphone.at.volume(num) // .to  .at  .with
  }

  finalize() {
    if ($.poller) $.poller.stop()
  }
}
