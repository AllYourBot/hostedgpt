import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    playedbackId: { type: Number, default: undefined },
    waitingForNextPlayback: { type: Boolean, default: false }
  }
  static outlets = [ "playback" ]

  // In auto-speaker mode (i.e. where the mic button was activated) then this controller always decides when
  // to call into playback_controller to initiate playing back the next thing.
  //
  // The normal loop is:
  //
  // When a playback controller finishes, it calls playbackFinishedPrompting. We check if a next playbackOutlet
  // is ready. If so, it starts playing it. Otherwise, it sets waitingForNextPlaybackValue to true.
  //
  // The next time a playbackOutlet connects, if we are waitingForNextPlaybackValue then we start it. If not,
  // we can safely do nothing because as soon as the playback controller finishes it'll let this speaker
  // controller know (i.e. playbackFinishedPrompting).
  //
  // There is a small chance of a race between these two conditions, I'm not sure how to prevent that...

  playbackFinishedPrompting(id) {
    this.playedbackIdValue = id
    const nextId = this.nextPlaybackId

    if (nextId && nextId > this.playedbackIdValue) {
      console.log(`playbackFinishedPrompting(${id}) and nextId is ready (${nextId})`)
      this.playAndStopOthers(nextId)
    } else {
      console.log(`playbackFinishedPrompting(${id}) and nextId is NOT ready`)
      this.waitingForNextPlaybackValue = true
    }
  }

  playbackOutletConnected(playback) {
    playback.speaker = this // so playback instances can call into auto-speaker

    if (this.waitingForNextPlaybackValue && Listener.enabled) {
      console.log(`playbackOutletConnected(${playback.idValue}) and ready to play()`)
      runAfter(0, () => this.playAndStopOthers(playback.idValue))
    } else if (Listener.enabled) {
      console.log(`playbackOutletConnected(${playback.idValue}) but not ready to play yet`)
      // Previous playback is still finishing prompting, do nothing
    } else if (Listener.disabled) {
      console.log(`playbackOutletConnected(${playback.idValue}) but Listener is disabled`)
      this.playedbackIdValue = playback.idValue
    }
  }

  // There are two edge cases to consider:
  //
  // 1. When an old conversation loads (i.e. there are already assistant messages), we treat these as if they
  // all just finished being spoken. If the user decides to activate the microphone then we set
  // waitingForNextPlaybackValue to true and wait for a new playbackOutlet connect. We're in the normal loop.
  //
  // There situation calls playbackOutletConnected() repeatedly so we have a special branch in there for this
  // and we composer calls:

  micActivated() {
    this.waitingForNextPlaybackValue = true
  }

  // 2. When a new converation was just created with voice, the page will navigate from /new to /conversation
  // and re-initialize this speaker controller. We'll already have an assistant message on the page but this
  // one has not been spoken so we need to start speaking it. We can tell this case by checking the mic state:

  initialize() {
    console.log(`speaker connected with index initially ${this.playedbackIdValue} and Listener ${Listener.enabled}`)
    if (Listener.enabled) this.waitingForNextPlaybackValue = true
  }

  // Utilities

  playAndStopOthers(idToPlay) {
    console.log(`playing(${idToPlay})`)
    runAfter(0, () => this.playbackOutlets.each(playback => {
      const active = playback.idValue == idToPlay
      if (active)
        playback.beginSpeakingMessage()
      else
        playback.discontinueSpeakingMessage()
    }))
  }

  get nextPlaybackId() {
    if (!this.hasPlaybackOutlet) return undefined

    const curIndex = this.playbackOutlets.index(playback => playback.idValue == this.playedbackIdValue)
    return this.playbackOutlets[curIndex + 1]?.idValue
  }

  preserveStimulusValues(e) {
    // FIXME: Eventually rails will have an official solution. Check this issue: https://github.com/hotwired/turbo/issues/1210
    if (e.target == this.element && e.detail.attributeName == "data-speaker-playedback-id-value") e.preventDefault()
    if (e.target == this.element && e.detail.attributeName == "data-speaker-waiting-for-next-playback-value") e.preventDefault()
  }
}
