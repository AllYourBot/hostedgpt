import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { playbackIndex: { type: Number, default: undefined } }
  static outlets = [ "playback" ]

  connect() {
    console.log(`speaker connected with index initially ${this.playbackIndexValue}`)
    if (Listener.enabled) this.setPlaybackIndexLast() // navigated from messages/new to conversation/#/messages
  }

  start() {
    console.log('speaker start()')
    this.setPlaybackIndexAhead()
  }

  stop() {
    console.log('speaker stopx()')
    this.playbackIndexValue = undefined
  }

  playbackIndexValueChanged() {
    console.log(`playback index value changed to ${this.playbackIndexValue}`)
    if (!this.playbackIndexValue) return // we want to ignore it's default value state
    if (this.hasPlaybackOutlet) runAfter(0, () => { // runAfter 0 simply pushes this to the end of the callback chain to solve a race
      this.startThePlayback(this.playbackIndexValue, 'playbackIndexValueChanged')
    }, 0)
  }

  startThePlayback(index, from = null) {
    console.log(`startThePlayback(${index}) from ${from}`)
    runAfter(0, () => this.playbackOutlets.each(playback => {
      const active = playback.indexValue == index
      console.log(`${playback.indexValue}: active = ${active}`)
      if (active)
        playback.startSpeakingMessage()
      else
        playback.stopSpeakingMessage()
    }))
  }

  playbackOutletConnected(playback) {
    console.log(`playbackOutletConnected ${playback.indexValue} with autoplay = ${this.autoplayNextOutlet}`)
    playback.speaker = this // so playback instances can call into auto-speaker
    if (Listener.disabled) { // these connections are happening on initial page load
      if (playback.indexValue > this.playbackIndexValue) this.setPlaybackIndexAhead()
    } else {
      runAfter(0, () => this.startThePlayback(this.playbackIndexValue))
    }
  }

  advancePlayback() {
    if (this.playbackOutlets.last().indexValue == this.playbackIndexValue) {
      console.log('advancePlayback but no next outlet exists')
      this.setPlaybackIndexAhead()
    } else {
      this.playbackIndexValue = this.playbackOutlets.last().indexValue
      console.log(`advancePlayback to ${this.playbackIndexValue}`)
    }
  }

  setPlaybackIndexLast() {
    if (this.hasPlaybackOutlet)
      this.playbackIndexValue = this.playbackOutlets.last().indexValue
    else
      this.playbackIndexValue = 1
  }

  setPlaybackIndexAhead() {
    if (this.hasPlaybackOutlet)
      this.playbackIndexValue = this.playbackOutlets.last().indexValue + 2
    else
      this.playbackIndexValue = 1
  }

  preserveStimulusValues(e) {
    if (e.target == this.element && e.detail.attributeName == "data-speaker-playback-index-value") e.preventDefault()
  }
}
