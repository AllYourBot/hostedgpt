import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { playedbackId: { type: Number, default: undefined } }
  static outlets = [ "playback" ]

  connect() {
    console.log(`speaker connected with index initially ${this.playedbackIdValue}`)
    //if (Listener.enabled) this.setPlayedToLast() // 'suppressCallback') // navigated from messages/new to conversation/#/messages
  }

  start() {
    console.log('speaker start()')
    this.setPlayedToLast('start')
  }

  stop() {
    console.log('speaker stop()') // TODO: when is this called?
  }

  playedbackIdValueChanged() {
    console.log(`## playedbackIdValue = ${this.playedbackIdValue}`)
    //if (this.suppressCallback) { this.suppressCallback = false; return }
    if (!this.playedbackIdValue) return // we want to ignore it's default value state
    if (this.hasPlaybackOutlet) runAfter(0, () => { // runAfter 0 simply pushes this to the end of the callback chain to solve a race
      this.continuePlayback('playbackIndexValueChanged')
    }, 0)
  }

  continuePlayback(src = null) {
    //console.log(`continuePlayback(${index}) from ${src}`)
    runAfter(0, () => this.playbackOutlets.each(playback => {
      const active = playback.idValue == this._nextPlaybackId()
      //console.log(`${playback.idValue}: active = ${active}`)
      if (active)
        playback.startSpeakingMessage()
      else
        playback.stopSpeakingMessage()
    }))
  }

  playbackOutletConnected(playback) {
    //console.log(`playbackOutletConnected ${playback.idValue} with Listener enabled? ${Listener.enabled}`)
    playback.speaker = this // so playback instances can call into auto-speaker
    if (Listener.disabled) // these connections are happening on initial page load
      runAfter(0, () => this.setPlayedToLast('outlet connected'))
    else
      runAfter(0, () => this.continuePlayback('outlet connected'))
  }

  advancePlayback() {
    this.setPlayedToLast('advance')
  }

  setPlayedToLast(src = null) {
    //this.suppressCallback = suppressCallback

    const lastValue = this.hasPlaybackOutlet ? this.playbackOutlets.last().idValue : 0

    if (lastValue && (!this.playedbackIdValue || lastValue > this.playedbackIdValue))
      this.playedbackIdValue = lastValue

    console.log(`set playedbackIdValue to ${this.playedbackIdValue} (${src})`)
  }

  preserveStimulusValues(e) {
    if (e.target == this.element && e.detail.attributeName == "data-speaker-playedback-id-value") e.preventDefault()
  }

  _nextPlaybackId() {
    if (!this.hasPlaybackOutlet) return undefined

    const curIndex = this.playbackOutlets.index(playback => playback.idValue == this.playedbackIdValue)
    return this.playbackOutlets[curIndex+1]?.idValue
  }
}
