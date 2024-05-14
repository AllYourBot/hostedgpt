import Interface from "blocks/interface"

export default class extends Interface {
  logLevel_info

  log_Prompt
  Prompt(words)       { $.audioService.sayNext(words) }
  Reset()             { $.audioService.stop() }

  get speaking()      { $.audioService.speaking }
  get busy()          { $.audioService.busy }

  new() {
    $.audioService = new AudioService
    $.audioService.onBusyChanged = (busy) => {
      console.log(`onbusyChanged(${busy})`)
      if (busy)
        Cover.Transcriber()
      else
        Uncover.Transcriber()
    }
  }
}