import Service from "../service.js"

export default class extends Service {
  logLevel_info

  new(arr = []) {
    $.queue = arr
  }

  push(obj) {
    $.queue.push(obj)
  }

  async queueRequest(index, text) {
    let audioUrl, lastError

    for (let i = 1; i <= 3 && !$.serverVoiceUnavailable; i++) {
      if (! $.queue[index]) break

      try {
        log(`  generating job ${index} attempt ${i} (${text.slice(0, 20)}...)`, 'debug')
        request = new SpeechService()
        $.queue[index].request = request
        audioUrl = await request.audioFromOpenAI(text)
      } catch (error) {
        lastError = error
        if (error.serverVoiceUnavailable) { $.serverVoiceUnavailable = true; break }
        log(`  error fetching job ${index} attempt ${i}${i == 3 ? ` - giving up (${text})` : ''}`)
        await sleep(0.5)
      }

      if (audioUrl != undefined) break
    }
    if (! $.queue[index]) return

    if ($.serverVoiceUnavailable) {
      $.queue[index].browserVoice = true
      $.queue[index].generated = true
    } else if (audioUrl == undefined) {
      $.queue[index].errored = true
      $.queue[index].error = lastError?.message
    } else {
      $.queue[index].audioUrl = audioUrl
      $.queue[index].generated = true
    }
  }

  at(i) {
    return $.queue[i]
  }

  reset() {
    $.queue.forEach(item => {
      item.request?.cancel()
    })
    $.queue = []
  }

  get requestsInFlight() {
    return $.queue.filter(job => job.requested && !job.generated && !job.errored).length
  }

  get nextUnrequested() {
    return $.queue.find(job => !job.requested)
  }

  get all() {
    return $.queue
  }

  get length() {
    return $.queue.length
  }
}
