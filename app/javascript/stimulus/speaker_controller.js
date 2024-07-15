import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { playbackIndex: { type: Number, default: undefined } }
  static outlets = [ "playback" ]

  connect() {
    console.log(`speaker connected with index initially ${this.playbackIndexValue}`)
    this.autoplayNextOutlet = false
  }

  start() {
    this.autoplayNextOutlet = true
    this.setPlaybackIndexAhead()
  }

  stop() {
    this.playbackIndexValue = undefined
  }

  playbackIndexValueChanged() {
    if (!this.playbackIndexValue) return // we want to ignore it's default value state
    console.log(`playback index value changed to ${this.playbackIndexValue}`)
    if (this.hasPlaybackOutlet) runAfter(0, () => { // runAfter 0 simply pushes this to the end of the callback chain to solve a race
      this.startThePlayback(this.playbackIndexValue)
    }, 0)
  }

  startThePlayback(index) {
    runAfter(0, () => this.playbackOutlets.each(playback => {
      const active = playback.indexValue == index
      if (active)
        playback.startSpeakingMessage()
      else
        playback.stopSpeakingMessage()
    }))
  }

  playbackOutletConnected(playback) {
    console.log('playbackOutletConnected', playback.indexValue)
    playback.speaker = this // so playback instances can call into auto-speaker
    if (this.autoplayNextOutlet) {
      this.autoplayNextOutlet = false
    } else {
      console.log(`connected but ${Listener.disabled}`)
      if (Listener.disabled && playback.indexValue > this.playbackIndexValue) this.setPlaybackIndexAhead()
    }
  }

  advancePlayback() {
    if (this.playbackOutlets.last().indexValue == this.playbackIndexValue) {
      console.log('advancePlayback but no next outlet exists')
      this.autoplayNextOutlet = true
      this.setPlaybackIndexAhead()
    } else {
      this.playbackIndexValue = this.playbackOutlets.last().indexValue
      console.log(`advancePlayback to ${this.playbackIndexValue}`)
    }
  }

  setPlaybackIndexAhead() {
    if (!this.hasPlaybackOutlet) return
    this.playbackIndexValue = this.playbackOutlets.last().indexValue + 2
  }
}
