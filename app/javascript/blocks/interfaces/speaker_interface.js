import Interface from "../interface.js"

export default class extends Interface {
  logLevel_info
  attrAccessor_onBusyDone

  log_Prompt
  Prompt(sentence)          { if (!blocks.env.isTest) $.audioService.speakNext(sentence) }
  Stop()                    { $.audioService.stop() }
  async Play(sound, onEnd)  { await $.audioService.play(sound, onEnd) }
  Loop(sec, sound)          { $.audioService.playEvery(sec, sound) }
  Hush()                    { $.audioService.stopLooping() }

  get speaking()            { $.audioService.speaking }
  get busy()                { $.audioService.busy }

  new() {
    $.audioService = new AudioService
    $.audioService.onBusyChanged = (busy) => {
      if (busy) {
        Cover.Transcriber()
      } else if (!busy && !Listener.disabled) {
        Play.Speaker.sound('pop', () => _loopTypingSounds())
        Invoke.Listener()
        if ($.onBusyDone) $.onBusyDone()

      } else if (!busy) {
        if ($.onBusyDone) $.onBusyDone()
      }
    }
  }

  // The listener can be dismissed while the pop is still playing, so check again once it finishes
  _loopTypingSounds() {
    if (!Listener.engaged) return
    $.audioService.playRandomlyEvery(6, 10, ['typing1', 'typing2', 'typing3'])
  }
}
