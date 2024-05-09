import Service from "./service.js"

export default class extends Service {
  logLevel_info

  new() {
    $.player = new Audio()
  }

  play(audio, onEnd) {
    if (!$.player) return

    try {
      $.player.onended = null
      $.player.pause()
    } catch(e) {
      console.log('audio play failed', e)
    }

    $.player.src = audio
    $.player.volume = 1
    $.player.onended = onEnd

    $.player.play()
  }

  async speak(text, onEnd) {
    const audio = await SpeechService.SpeechWithOpenAI(text)
    play(audio, onEnd)
  }
}
