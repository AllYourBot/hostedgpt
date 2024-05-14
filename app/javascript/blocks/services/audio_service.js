import Service from "./service.js"

export default class extends Service {
  logLevel_info

  new() {
    $.player = new Audio()
    $.queue = []
    $.playing = false
    $.busy = false
  }

  play(audio, onEnd) {
    if (!$.player) return

    $.playing = true
    try {
      $.player.onended = null
      $.player.pause()
    } catch(e) { log(`audio play failed ${e}`) }

    $.player.onended = () => {
      $.playing = false
      if (onEnd) onEnd()
    }
    $.player.volume = 1
    $.player.src    = audio

    $.player.play()
  }

  stop() {
    $.player.pause()
    $.queue = []
    $.playing = false
    $.busy = false
  }

  async speakNow(text, onEnd) {
    const audio = await SpeechService.audioFromOpenAI(text)
    play(audio, onEnd)
  }

  sayNext(words) {
    if (words == undefined) return

    const index = $.queue.length

    $.queue.push({
      index: index,
      words: words,
      audioUrl: null,
      generated: false,
      played: false,
      errored: false,
    })

    void _queueWordsToSay(index)
  }

  async _queueWordsToSay(index) {
    const text = $.queue[index].words
    let audioUrl
    $.busy = true

    for (let i = 1; i <= 3; i++) {
      try {
        audioUrl = await SpeechService.audioFromOpenAI(text)
      } catch(error) {
        log(`  error fetching job ${index} attempt ${i}${i == 3 ? ' - giving up' : ''}`)
        await sleep(500)
      }

      if (audioUrl != undefined) break
    }
    if (audioUrl == undefined) $.queue[index].errored = true

    $.queue[index].audioUrl = audioUrl
    $.queue[index].generated = true

    void _speakingLoop('generation')
  }

  async _speakingLoop(trigger) {
    const jobsToPlay = $.queue.filter((job) => !job.played)
    // if (trigger) {
    //   log(`speakingLoop with ${jobsToPlay.length} jobs remaining - ${trigger} finished & speaking = ${$.playing}`)
    //   jobsToPlay.forEach((job) => log(`  job #${job.index}: ${job.generated ? 'generated' : 'not generated'} : ${job.played ? 'played' : 'not played'} : ${job.errored ? 'errored' : 'no error'} : ${job.words}...`))
    // }

    if (jobsToPlay.length > 0) {
      const job = jobsToPlay[0]

      if (job.generated && !$.playing && job.errored) {
        log(`  play #${job.index} skipped because of generating error`)
        job.played = true
        _speakingLoop('playback')
        return
      } else if (job.generated && !$.playing && !job.errored) {
        job.played = true
        _playThenLoop(job.index, job.words, job.audioUrl)
        return
      } else {
        await sleep(250)
        _speakingLoop()
        return
      }
    } else if (!$.playing) _doneSpeakingAllWords()
  }

  _playThenLoop(index, words, audioUrl) {
    // if (this._plabackSoundTimeoutHandler) clearTimeout(this._plabackSoundTimeoutHandler)

    // this._plabackSoundTimeoutHandler = setTimeout(() => {
    //   $.playing = false
    //   log(`  speaking now ${$.playing}`)
    //   log(`  play timed out for #${index}, looping anyway.`)
    //   _speakingLoop('timer')
    // }, 8000) // figure out how to cancel this timeout as soon as speaking starts. Add a callback from background to indicate this.

    log(`Playing: ${words}`)
    play(audioUrl, () => {
      // f (this._plabackSoundTimeoutHandler) clearTimeout(this._plabackSoundTimeoutHandler)
      // log(`  done #${index} - ${words.slice(0,10)}...`)
      _speakingLoop('playback')
    }, words)
  }

  log_doneSpeakingAllWords
  _doneSpeakingAllWords() {
    $.playing = false
    $.busy = false
    $.queue = []
  }
}
