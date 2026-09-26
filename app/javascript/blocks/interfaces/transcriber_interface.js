import Interface from "../interface.js"

// The length of time we pause before reflecting on what was said takes into
// account *what* was said. If the last word sounds like someone's voice is
// trailing off mid-thought, e.g. "... and um", we wait longer than when the
// words sound like a finished thought, e.g. "..., right?"

// Maybe we could also start processing the response even before this
// duration has elapsed but delay responding?

export default class extends Interface {
  logLevel_info
  attrReader_covered

  async Flip(turnOn)    { if (turnOn && $.active) {
                            Uncover.Transcriber()

                          } else if (turnOn && !$.active) {
                            $.active = true
                            Uncover.Transcriber()
                            await Invoke.Listener()

                          } else if (!turnOn && $.active) {
                            $.active = false
                            $.dismissPoller?.end()
                            $.silenceService.stop()
                            await $.transcriberService.end()
                            await Disable.Listener()
                          }
                        }

  async Approve()       { if (blocks.env.isTest) return true
                          let approved = await $.transcriberService.start()
                          await $.transcriberService.end()
                          return approved
                        }

  log_SpeakTo
  SpeakTo(text)         { if ($.covered) { log(`ignored "${text}" because the transcriber is covered while the assistant speaks`); return }
                          $.words += text+' '
                          $.silenceService.restartCounter()
                          $.dismissPoller?.end()
                          _shortWaitThenTell()
                        }

  Cover()               { $.covered = true
                          $.silenceService.stop()
                        }

  Uncover()             { $.covered = false
                          $.transcriberService.restart()
                          _longWaitThenDismis()
                        }

  attr_words            = ''
  attr_active           = false

  get on()              { return $.active }
  get off()             { return !$.active }

  get supported()       { return Transcriber.$.transcriberService.$.recognizer != null }

  new() {
    $.covered = false
    $.silenceService = new SilenceService
    $.transcriberService = new TranscriberService
    $.transcriberService.onSound = () => $.silenceService.restartCounter()
  }

  _shortWaitThenTell()  { if (!$.tellPoller?.handler) $.tellPoller = runEvery(0.2, () => {
                            if ($.silenceService.msOfSilence <= _msOfSilenceNeeded($.words)) return
                            log('enough silence to start processing...')

                            if (! $.covered) Cover.Transcriber()
                            Tell.Listener.to.consider($.words)

                            $.words = ''
                            $.tellPoller.end()
                          })
                        }

  _msOfSilenceNeeded(words) { return _soundsUnfinished(words) ? 2000 : 800 }

  _soundsUnfinished(words) { const lastWord = words.downcase().trim().split(/\s+/).last().replace(/[^a-z']/g, '')
                             return ["and", "but", "or", "so", "because", "then", "if", "like", "um", "uh", "er", "hmm",
                               "well", "the", "a", "an", "to", "of", "for", "with", "about", "that", "which", "my", "your",
                               "is", "are", "was", "i", "i'm", "we", "also", "maybe", "actually", "basically"].include(lastWord)
                           }

  _longWaitThenDismis() { $.silenceService.restartCounter()

                          if (!$.dismissPoller?.handler) $.dismissPoller = runEvery(0.2, () => {
                            if ($.silenceService.msOfSilence <= 30000) return
                            log('enough silence to dismiss...')

                            Dismiss.Listener()
                            $.dismissPoller.end()
                          })
                        }
}
