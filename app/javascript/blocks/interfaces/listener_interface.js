import Interface from "../interface.js"

// To clarify the verbs:
// Invoke a Listener and it starts listening
// Dismiss a Listener and you can re-invoke it with wake words, so it's listening just not paying attention
// Disable a Listener and it completely stops working and will be fully re-initialized if you Invoke again

export default class extends Interface {
  logLevel_info

  log_Tell
  async Tell(words)   { if (this.engaged && _intendedDismiss(words)) {
                          await Dismiss.Listener()
                          return
                        }
                        if (_intendedInvoke(words)) {
                          await Invoke.Listener()
                          words = _removeSpeechBeforeName(words)
                        }
                        if (!$.processing) return // Invoke() did not succeed

                        if (_referencingTheScreen(words))
                          $.attachment = await $.screenService.takeScreenshot()
                        else
                          $.attachment = null

                        $.consideration = words
                        _startThinking()
                      }
  log_Invoke
  async Invoke()      { if (!$.processing) {
                          $.processing = true
                          await $.screenService.start()
                          await Flip.Transcriber.on()
                        }
                      }
  log_Dismiss
  async Dismiss()     { if ($.processing) {
                          $.processing = false
                          await Flip.Transcriber.on() // so it can wait for "wake" words
                          await Play.Speaker.sound('pip')
                        }
                      }

  async Disable()     { if ($.processing != null) {
                          $.processing = null
                          await $.screenService.end()
                          await Flip.Transcriber.off()
                          await Play.Speaker.sound('pip')
                        }
                      }

  attr_consideration  = ''
  attr_attachment     = null

  get engaged()       { return $.processing === true  }
  get dismissed()     { return $.processing === false }
  get disabled()      { return $.processing === null }

  get supported()     { return Transcriber.supported }

  new() {
    $.processing = null
    $.screenService = new ScreenService
  }

  _intendedDismiss(words) {
    return words.downcase().includeAny(["hold on", "hold up", "one sec", "one second", "stop", "on a call"]) &&
           words.downcase().includeAny(["samantha"])
  }

  _intendedInvoke(words) {
    return words.downcase().includeAny(["samantha", "i'm back", "i am back", "i'm here"]) &&
           words.downcase().includeAny(["samantha"]) //TODO; let's recognize these phrases without "samantha" and simply reply with "are you talking to me?"
  }

  _referencingTheScreen(words) {
    return words.downcase().includeAny(["can you see", "you can see", "do you see", "look at", "this", "my screen", "the screen"])
  }

  _startThinking() {
    Play.Speaker.sound('jeep', () => {
      Loop.Speaker.every(4, 'thinking')
    })
  }

  _removeSpeechBeforeName(words) {
    if (words.downcase().includes("samantha"))
      return words.slice(words.downcase().indexOf("samantha"))
    else
      return words
  }
}
