import Control from "./control.js"

// To clarify the verbs:
// Invoke a Listener and it starts listening
// Dismiss a Listener and you can re-invoke it with wake words, so it's listening just not paying attention
// Mute a Listener and it completely ignores everything it hears, but the mic stays on

export default class extends Control {
  logLevel_info

  log_Tell
  async Tell(words)   { log(`muted = ${$.muted}`); if ($.muted) return
                        if (_intendedDismiss(words)) {
                          Dismiss.Listener()
                          return
                        }
                        if (_intendedInvoke(words)) Invoke.Listener()
                        if (!$.processing) return // gave Invoke() a chance

                        if (_referencingTheScreen(words))
                          $.attachment = await $.screenService.takeScreenshot()
                        else
                          $.attachment = null

                        $.consideration = words
                      }
  log_Invoke
  Invoke()            { if (!$.processing) {
                          $.processing = true
                          $.muted = false
                          Flip.Transcriber.on()
                          $.screenService.start()
                        }
                      }
  log_Dismiss
  Dismiss()           { if ($.processing) {
                          $.processing = false
                          Flip.Transcriber.on() // so it can wait for "wake" words
                        }
                      }

  Mute()              { $.processing = false
                        $.muted = true
                      }

  attr_consideration  = ''
  attr_attachment     = null
	attr_processing     = false
  attr_muted          = true

  new() {
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
}