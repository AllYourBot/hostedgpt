import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: Number, sentencesIndex: Number }
  static targets = [ "assistantText" ]
  static outlets = [ "transition" ]

  // Ths only time playbackController initiates playback is when the user clicks start on the "Play" button.
  // In voice mode (i.e. the mic button was activated) then speaker controller calls into this controller.

  connect() {
    this.playClicked = false // not quite a true state, it's a very short-duration flag, so not elevating this to a value
  }

  toggleSpeakingMessage() {
    this.playClicked = !this.playClicked

    if (this.playClicked)
      this.clickedStart()
    else
      this.clickedStop()
  }

  clickedStart() {
    if (this.hasTransitionOutlet) this.transitionOutlet.toggleClassOn()
    Speaker.onBusyDone = () => this.toggleSpeakingMessage()
    this.beginSpeakingMessage()

    this.sentencesIndexValue = 0
  }

  beginSpeakingMessage() {
    console.log('### beginSpeakingMessage()')
    this.observer = this.connectMessageObserver(() => this.messageTextUpdated('observer'))
    this.messageTextUpdated('initial')
  }

  clickedStop() {
    if (this.hasTransitionOutlet) this.transitionOutlet.toggleClassOff()
    Speaker.onBusyDone = () => { }
    this.discontinueSpeakingMessage()

    Stop.Speaker()
  }

  discontinueSpeakingMessage() {
    this.observer?.disconnect()
  }

  messageTextUpdated(src = '') {
    console.log(`${this.idValue}: messageTextUpdated(${src}) ${Listener.enabled ? 'enabled' : 'disabled'} :: from ${this.sentencesIndexValue} to ... (${this.assistantTextTarget.textContent})`)
    if (Listener.disabled && !this.playClicked) return
    const sentences = SpeechService.splitIntoThoughts(this.assistantTextTarget.textContent)
    if (sentences.length == 0) return

    const thinkingDone = this.assistantTextTarget.getAttribute('data-thinking') === 'false'
    const toSentenceIndex = thinkingDone ? sentences.length-1 : sentences.length-2
    this.speakSentencesTo(sentences, toSentenceIndex)

    if (thinkingDone && !this.playClicked) this.speaker?.playbackFinishedPrompting()
  }

  async speakSentencesTo(sentences, toIndex) {
    if (this.sentencesIndexValue > toIndex) return
    for (this.sentencesIndexValue; this.sentencesIndexValue <= toIndex; this.sentencesIndexValue ++) {
      if (!sentences[this.sentencesIndexValue]) break
      if (sentences[this.sentencesIndexValue].includes('::ServerError') || sentences[this.sentencesIndexValue].includes('Faraday::')) {
        // client is displaying a server error
        break
      }
      if (!blocks.env.isTest)
        Prompt.Speaker.toSay(sentences[this.sentencesIndexValue])
      else {
        console.log(`isTest: playback_controller: Prompt.Speaker.toSay(${sentences[this.sentencesIndexValue]})`)
        await sleep(1)
        if (Speaker.onBusyDone) Speaker.onBusyDone()
      }
    }
  }

  // Utilities

  connectMessageObserver(callback) {
    return new MutationObserver((mutations) => {
      if (mutations.some(mutation => mutation.target == this.element)) {
        console.log('mutation', mutations)
        callback()
      }
    }).observe(this.element, {
      characterData: true,
      childList: true,
      subtree: true
    })
  }

  preserveStimulusValues(e) {
    // FIXME: Eventually rails will have an official solution. Check this issue: https://github.com/hotwired/turbo/issues/1210
    if (e.target == this.element && e.detail.attributeName == 'data-playback-sentences-index-value') e.preventDefault()
  }
}
