import Interface from "../interface.js"

export default class extends Interface {
  logLevel_info

  log_Prompt
  Prompt(words)             { $.audioService.sayNext(words) }
  Reset()                   { $.audioService.stop() }
  async Play(sound, onEnd)  { await $.audioService.play(sound, onEnd) }
  Loop(sec, sound)          { $.audioService.playEvery(sec, sound) }

  get speaking()            { $.audioService.speaking }
  get busy()                { $.audioService.busy }

  new() {
    $.audioService = new AudioService
    Microphone.attach($.audioService.player)
    $.audioService.onBusyChanged = (busy) => {
      console.log(`onbusyChanged(${busy})`)
      if (busy)
        Cover.Transcriber()
      else
        Uncover.Transcriber()
    }
  }
}
