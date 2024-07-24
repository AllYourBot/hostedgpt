import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    playedbackId: { type: Number, default: undefined },
    readyForNextPlayback: { type: Boolean, default: false }
  }
  static outlets = [ "playback" ]

  // In auto-speaker mode (i.e. where the mic button was activated) then this controller always decides when
  // to call into playback_controller to initiate playing back the next thing.
  //
  // The normal loop is:
  //
  // Whenever a playback controller finishes, it calls playbackFinishedPrompting. This checks if there
  // is a next playbackOutlet already connected. If there is, it calls it's beginSpeakingMessage(). If there
  // is not then it sets readyForNextPlaybackValue to true.
  //
  // The next time a playbackOutlet connects, if we are readyForNextPlaybackValue then we start it. If not,
  // we can safely do nothing because as soon as the playback controller finishes it'll let this speaker
  // controller know (i.e. playbackFinishedPrompting).

  // playbackFinishedPrompting() {
  //   if (this.nextPlaybackId)
  //     this.playedbackIdValue = this.nextPlaybackId
  //   else
  //     this.readyForNextPlaybackValue = true
  // }
  //
  // playbackOutletConnected(playback) {
  //   playback.speaker = this // so playback instances can call into this speaker controller
  //
  //   if (this.readyForNextPlayback)
  //     this.playedbackIdValue = playback.id
  //   else if (Listener.disabled)
  //     runAfter(0, () => this.setPlayedToLast('outlet connected'))
  //   else if (Listener.enabled) {
  //     console.log('playbackOutletConnected but previous playback is still finishing, do nothing.)
  //   }
  // }
  //
  // // Utilities
  //
  // get nextPlaybackId() {}
  //
  // get readyForNextPlayback() {}
  //
  // get setPlayedToLast() {}


  // There are two edge cases to consider:
  //
  // 1. When an old conversation loads (i.e. there are already assistant messages), we treat these as if they
  // all just finished being spoken and set readyForNextPlaybackValue to true. If the user decides to activate
  // the microphone then eventually we'll get a new playbackOutlet connect and we'll be in the normal loop.
  //
  // There situation calls playbackOutletConnected() repeatedly so we have a special branch in there for this
  //
  // 2. When a new converation was just created with voice, the page will load fresh and we'll already have
  // an assistant message on the page but this one has not been spoken so we need to start speaking this first
  // one. We can tell this case by checked the mic state upon initial connection.

  // connect() {
  //   if (Listener.enabled) this.readyForNextPlaybackValue = true
  // }






  connect() {
    console.log(`speaker connected with index initially ${this.playedbackIdValue}`)
    //if (Listener.enabled) this.setPlayedToLast() // 'suppressCallback') // navigated from messages/new to conversation/#/messages
  }

  start() { // I don't think I need this — remove from composer
    console.log('speaker start()')
    this.setPlayedToLast('start')
  }

  stop() { // I don't think I need this — remove from composer
    console.log('speaker stop()')
  }

  setPlayedToLast(src = null) {
    const lastValue = this.hasPlaybackOutlet ? this.playbackOutlets.last().idValue : 0
    if (lastValue && (!this.playedbackIdValue || lastValue > this.playedbackIdValue))
      this.playedbackIdValue = lastValue

    console.log(`set playedbackIdValue to ${this.playedbackIdValue} (${src})`)
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
    console.log(`continuePlayback() from ${src}`)
    runAfter(0, () => this.playbackOutlets.each(playback => {
      const active = playback.idValue == this._nextPlaybackId // TODO: Shouldn't this be this.playedbackIdValue
      console.log(`active? ${playback.idValue} == ${this._nextPlaybackId}`, this.playbackOutlets)
      if (active)
        playback.beginSpeakingMessage()
      else
        playback.discontinueSpeakingMessage()
    }))
  }

  playbackOutletConnected(playback) {
    playback.speaker = this // so playback instances can call into auto-speaker
    //console.log(`playbackOutletConnected ${playback.idValue} with Listener enabled? ${Listener.enabled}`)
    if (this._playbackEnabled)
      runAfter(0, () => this.continuePlayback('outlet connected'))
    else
      runAfter(0, () => this.setPlayedToLast('outlet connected'))
  }

  playbackFinishedPrompting() {
    this.setPlayedToLast('advance')
  }

  preserveStimulusValues(e) {
    // Add link from comment from reddit
    if (e.target == this.element && e.detail.attributeName == "data-speaker-playedback-id-value") e.preventDefault()
  }



  get _nextPlaybackId() {
    if (!this.hasPlaybackOutlet) return undefined

    const curIndex = this.playbackOutlets.index(playback => playback.idValue == this.playedbackIdValue)
    return this.playbackOutlets[curIndex+1]?.idValue
  }

  get _playbackEnabled() {
    return Listener.enabled
  }
}
