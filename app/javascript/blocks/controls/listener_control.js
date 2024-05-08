import Control from "./control.js"

export default class extends Control {
  logLevel_info

  log_Consider
  Tell(words)         { if (_intendedDismiss(words)) {
                          Dismiss.Listener()
                          return
                        }
                        if (_intendedInvoke(words)) Invoke.Listener()
                        if (!$.processing) return // gave Invoke() a chance

                        $.consideration = words
                        log(`## Considering: ${words}`)
                      }
  log_Invoke
  Invoke()            { if (!$.processing) {
                          $.processing = true
                          Flip.Transcriber.on()
                        }
                      }
  log_Dismiss
  Dismiss()           { if ($.processing) {
                          $.processing = false
                          Flip.Transcriber.on() // so it can wait for "wake" words
                        }
                      }

  End()               { $.processing = false
                        Flip.Transcriber.off()
                      }

  attr_consideration  = ''
	attr_processing     = false

  _intendedDismiss(words) {
    return words.downcase().includeAny(["hold on", "hold up", "one sec", "one second", "stop", "on a call"]) &&
           words.downcase().includeAny(["samantha"])
  }

  _intendedInvoke(words) {
    return words.downcase().includeAny(["samantha", "i'm back", "i am back", "i'm here"]) &&
           words.downcase().includeAny(["samantha"]) //TODO; let's recognize these phrases without "samantha" and simply reply with "are you talking to me?"
  }

  _referencingTheScreen(words) {
    return words.downcase().includeAny(["can you see", "you can see", "do you see", "look at", "this"])
  }
}