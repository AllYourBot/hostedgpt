import Interface from "blocks/interface"

// the length of time we pause before reflecting on what was said should
// take into account *what* was said. If the last word was clearly the end
// of a sentence and it ended as a question? e.g. "..., right?" We should
// start considering those words sooner than if the last word is the sound
// of someone's voice trailing off. e.g. "... well..."

// For now, we have a hard-coded silence duration. Maybe we utter a sound
// like "hmm" before this silence duration has elapsed to help it feel more
// responsive? Also, maybe we start processing the response even before
// this duration has elapsed but we delay responding?

export default class extends Interface {
  logLevel_info

  Flip(turnOn)        { if (turnOn && !$.active) {
                          $.active = true
                          $.transcriberService.start()

                          Flip.Microphone.on()
                          Invoke.Listener()

                        } else if (!turnOn && $.active) {
                          $.active = false
                          $.transcriberService.end()

                          Flip.Microphone.off()
                          Disable.Listener()
                        }
                      }

  log_SpeakTo
  SpeakTo(text)       { $.words += text+' '
                        if (!$.poller?.handler) $.poller = runEvery(0.2, () => {
                          log('enough silence...')
                          if (Microphone.msOfSilence <= 1800) return // what if there is background noise?

                          void Tell.Listener.to.consider($.words)
                          $.words = ''
                          $.poller.end()
                        })
                      }

  Cover()             { $.covered = true }
  Uncover()           { $.transcriberService.restart()
                        $.covered = false
                        Play.Speaker.sound('pop', () => {
                          Loop.Speaker.every(8, 'typing1')
                        })
                      }

  attr_words          = ''
  attr_active         = false

  get on()            { return $.active }
  get off()           { return !$.active }

  get supported()     { return Transcriber.$.transcriberService.$.recognizer != null }

  new() {
    $.covered = false
    $.transcriberService = new TranscriberService
    $.transcriberService.onTextReceived = (text) => {
      if ($.covered) return
      SpeakTo.Transcriber.with.words(text)
    }
  }
}