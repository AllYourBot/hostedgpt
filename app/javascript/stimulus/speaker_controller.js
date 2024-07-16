import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { playbackIndex: { type: Number, default: undefined } }
  static outlets = [ "playback" ]

  connect() {
    console.log(`speaker connected with index initially ${this.playbackIndexValue}`)
    if (Listener.enabled) this.setPlaybackIndexLast('suppressCallback') // navigated from messages/new to conversation/#/messages
  }

  start() {
    console.log('speaker start()')
    this.setPlaybackIndexLast()
  }

  stop() {
    console.log('speaker stop()')
    this.playbackIndexValue = undefined
  }

  playbackIndexValueChanged() {
    console.log(`## playbackIndex = ${this.playbackIndexValue}`)
    if (this.suppressCallback) { this.suppressCallback = false; return }
    //console.log(`playback index value changed to ${this.playbackIndexValue}`)
    if (!this.playbackIndexValue) return // we want to ignore it's default value state
    if (this.hasPlaybackOutlet) runAfter(0, () => { // runAfter 0 simply pushes this to the end of the callback chain to solve a race
      this.startThePlayback(this.playbackIndexValue, 'playbackIndexValueChanged')
    }, 0)
  }

  startThePlayback(index, from = null) {
    //console.log(`startThePlayback(${index}) from ${from}`)
    runAfter(0, () => this.playbackOutlets.each(playback => {
      const active = playback.indexValue == index
      //console.log(`${playback.indexValue}: active = ${active}`)
      if (active)
        playback.startSpeakingMessage()
      else
        playback.stopSpeakingMessage()
    }))
  }

  playbackOutletConnected(playback) {
    //console.log(`playbackOutletConnected ${playback.indexValue} with Listener enabled? ${Listener.enabled}`)
    playback.speaker = this // so playback instances can call into auto-speaker
    if (Listener.disabled) // these connections are happening on initial page load
      runAfter(0, () => this.setPlaybackIndexLast())
    else
      runAfter(0, () => this.startThePlayback(this.playbackIndexValue, 'connected'))
  }

  advancePlayback() {
    this.setPlaybackIndexLast()
  }

  setPlaybackIndexLast(suppressCallback = false) {
    this.suppressCallback = suppressCallback
    const lastValue = this.hasPlaybackOutlet ? this.playbackOutlets.last().indexValue : 0

    if (!this.playbackIndexValue || lastValue > this.playbackIndexValue) this.playbackIndexValue = lastValue
    //console.log(`set index value to ${this.playbackIndexValue}`)
  }

  preserveStimulusValues(e) {
    if (e.target == this.element && e.detail.attributeName == "data-speaker-playback-index-value") e.preventDefault()
  }
}
