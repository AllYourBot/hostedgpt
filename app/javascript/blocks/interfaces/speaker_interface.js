import Interface from "../interface.js"

export default class extends Interface {
  logLevel_info

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
      else
        Uncover.Transcriber()
    }
  }
}
