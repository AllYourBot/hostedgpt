import Control from "./control.js"

// the length of time we pause before reflecting on what was said should
// take into account *what* was said. If the last word was clearly the end
// of a sentence and it ended as a question? e.g. "..., right?" We should
// start considering those words sooner than if the last word is the sound
// of someone's voice trailing off. e.g. "... well..."

// For now, we have a hard-coded silence duration. Maybe we utter a sound
// like "hmm" before this silence duration has elapsed to help it feel more
// responsive? Also, maybe we start processing the response even before
// this duration has elapsed but we delay responding?

export default class extends Control {
  logLevel_info

    Flip(on)          { if (on && !$.active) {
                          $.active = true
                          $.transcriberService.start()
                          Microphone.Flip(true)
                          Listener.Invoke()
                        } else if (!on && $.active) {
                          $.active = false
                          $.transcriberService.stop()
                          Microphone.Flip(false)
                          Listener.Dismiss()
                        }
                      }

  log_SpeakTo
  SpeakTo(text)       { $.words += text+' '
                        if (!$.poller?.handler) $.poller = runEvery(0.2, () => {
                          log('enough silence...')
                          if (Microphone.msOfSilence <= 1800) return // what if there is background noise?

                          Listener.Tell($.words)
                          $.words = ''
                          $.poller.stop()
                        })
                        else
                          log('poller is already pending')
                      }


  attr_words          = ''
	attr_active         = false

	get on() 	          { $.active == 'paused' }
	get off()	          { $.active == 'started' }

	new() {
		$.transcriberService = new TranscriberService
		$.transcriberService.onTextReceived = (text) => SpeakTo(text)
	}
}