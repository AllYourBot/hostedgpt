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
    let audioUrl

    for (let i = 1; i <= 3; i++) {
      if (! $.queue[index]) break

      try {
        log(`  generating job ${index} attempt ${i} (${text.slice(0, 20)}...)`, 'debug')
        request = new SpeechService()
        $.queue[index].request = request
        audioUrl = await request.audioFromOpenAI(text)
      } catch (error) {
        log(`  error fetching job ${index} attempt ${i}${i == 3 ? ` - giving up (${text})` : ''}`)
        await sleep(0.5)
      }

      if (audioUrl != undefined) break
    }
    if (! $.queue[index]) return

    if (audioUrl == undefined)
      $.queue[index].errored = true
    else {
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

  get all() {
    return $.queue
  }

  get length() {
    return $.queue.length
  }
}
