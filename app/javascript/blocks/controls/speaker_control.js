import Control from "./control.js"

export default class extends Control {
  logLevel_info

  log_Prompt
  Prompt(words)       { $.audioService.sayNext(words) }
  Reset()             { $.audioService.stop() }

	get speaking()	    { $.audioService.speaking }
	get busy()	        { $.audioService.busy }

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