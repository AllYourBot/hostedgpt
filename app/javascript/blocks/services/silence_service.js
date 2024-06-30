import Service from "../service.js"

export default class extends Service {
  logLevel_debug
  attr_msOfSilence

  new() {
    restartCounter()
  }

  restartCounter() {
    $.msOfSilence = 0
    if (!$.poller?.handler) $.poller = runEvery(0.2, () => {$.msOfSilence += 200})
  }

  _timerEnd() {
    $.poller?.end()
    restartCounter()
  }
}
