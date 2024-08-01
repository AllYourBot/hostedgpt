import Service from "../service.js"

export default class extends Service {
  logLevel_info
  attr_msOfSilence

  restartCounter() {
    $.msOfSilence = 0
    if (!$.poller?.handler) $.poller = runEvery(0.2, () => { $.msOfSilence += 200 })
  }

  stop() {
    $.poller?.end()
  }
}
