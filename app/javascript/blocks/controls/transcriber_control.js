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

  log_SpeakTo
  SpeakTo(text)   { $.words += text+' '
                    if (!$.poller) $.poller = runEvery(0.2, () => {
                      if (Microphone.msOfSilence <= 1800) return // what if there is background noise?

                      console.log(`## Consider ${$.words}`)

                      // what should paused state do?


                      // if (Bot.waiting)
                      //   Tell.Bot.to($.words)
                      // else
                      //   Interrupt.Bot.with($.words)

                      $.words = ''
                      $.poller?.stop()
                    })
                  }
  Start()	        { $.status = 'started'; $.transcriberService.start(); Microphone.Enable() }
	Pause()	        { $.status = 'paused';  $.transcriberService.pause() } // TODO: implement this
	End()		        { $.status = 'ended'
                    $.poller?.stop()
                    $.transcriberService.end()
                    Microphone.Disable()
                  }

  attr_words      = ''
	attr_status     = 'ended'

	get paused() 	  { $.status == 'paused' }
	get listening()	{ $.status == 'started' }
	get ended()		  { $.status == 'ended' }

	new() {
		$.transcriberService = new TranscriberService
		$.transcriberService.onTextReceived = (text) => SpeakTo(text)
    // SpeakTo.Transcriber.with.words(text)
	}
}