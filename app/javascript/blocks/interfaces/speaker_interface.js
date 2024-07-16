import Interface from "../interface.js"

export default class extends Interface {
  logLevel_info
  attrAccessor_onBusyDone

  log_Prompt
  Prompt(sentence)          { $.audioService.speakNext(sentence) }
  Reset()                   { $.audioService.stop() }
  async Play(sound, onEnd)  { await $.audioService.play(sound, onEnd) }
  Loop(sec, sound)          { $.audioService.playEvery(sec, sound) }

  get speaking()            { $.audioService.speaking }
  get busy()                { $.audioService.busy }

  new() {
    $.audioService = new AudioService
    $.audioService.onBusyChanged = (busy) => {
      if (busy) {
        Cover.Transcriber()

      } else if (!busy && !Listener.disabled) {
        Play.Speaker.sound('pop', () => {
          Loop.Speaker.every(8, 'typing1')
        })
        Invoke.Listener()
        if ($.onBusyDone) $.onBusyDone()

      } else if (!busy) {
        if ($.onBusyDone) $.onBusyDone()
      }
    }
  }
}
