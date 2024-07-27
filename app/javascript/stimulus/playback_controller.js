import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: Number, sentencesIndex: Number }
  static targets = [ "assistantText" ]
  static outlets = [ "transition" ]

  // Ths only time playbackController initiates playback is when the user clicks start on the "Play" button.
  // In voice mode (i.e. the mic button was activated) then speaker controller calls into this controller.

  connect() {
    this.playClicked = false // not quite an actual state, it's a very short-duration flag, so not elevating this to a value
  }

  toggleSpeakingMessage() {
    this.playClicked = !this.playClicked

    if (this.playClicked)
      this.clickedStart()
    else
      this.clickedStop()
  }

  clickedStart() {
    this.sentencesIndexValue = 0

    if (this.hasTransitionOutlet) this.transitionOutlet.toggleClassOn()
    const existingBusyDone = Speaker.onBusyDone ?? (() => {})
    Speaker.onBusyDone = () => { this.toggleSpeakingMessage(); existingBusyDone() }
    this.beginSpeakingMessage()
  }

  beginSpeakingMessage() {
    console.log(`${this.idValue}: beginSpeakingMessage()`)
    this.observer?.disconnect()
    this.observer = this.connectMessageObserver(() => this.messageTextUpdated('observer'))
    this.messageTextUpdated('initial')
  }

  clickedStop() {
    if (this.hasTransitionOutlet) this.transitionOutlet.toggleClassOff()
    Speaker.onBusyDone = () => { }
    this.discontinueSpeakingMessage()

    Stop.Speaker() // onBusyDone must be cleared before this is stopped
  }

  discontinueSpeakingMessage() {
    console.log(`${this.idValue}: discontinueSpeakingMessage() and observer is`, this.observer)
    this.observer?.disconnect()
    this.observer = undefined
  }

  messageTextUpdated(src = '') {
    console.log(`${this.idValue}:   messageTextUpdated(${src}) ${Listener.enabled ? 'enabled' : 'disabled'} :: from ${this.sentencesIndexValue} to ... (${this.assistantTextTarget.textContent})`)
    if (Listener.disabled && !this.playClicked) return
    const sentences = SpeechService.splitIntoThoughts(this.assistantTextTarget.textContent)
    if (sentences.length == 0) return

    const isThinkingDone = this.assistantTextTarget.getAttribute('data-thinking') === 'false'
    const toSentenceIndex = isThinkingDone ? sentences.length-1 : sentences.length-2
    this.speakSentencesTo(sentences, toSentenceIndex, isThinkingDone)
  }

  speakSentencesTo(sentences, toIndex, isThinkingDone) {
    if (this.sentencesIndexValue > toIndex) return
    console.log(`${this.idValue}:     speakSentencesTo(${this.sentencesIndexValue} to ... ${toIndex})`)
    while (this.sentencesIndexValue <= toIndex) {
      const i = this.sentencesIndexValue
      this.sentencesIndexValue ++

      if (!sentences[i]) break
      if (sentences[i].includes('::ServerError') || sentences[i].includes('Faraday::')) return

      Prompt.Speaker.toSay(sentences[i])
    }
    console.log(`${this.idValue}:      sentenceIndex set to ${this.sentencesIndexValue} (${toIndex} was passed in)`)
    if (isThinkingDone && !this.playClicked) this.speaker?.playbackFinishedPrompting(this.idValue)
    if (blocks.env.isTest && Speaker.onBusyDone) runAfter(1, () => Speaker.onBusyDone())
  }

  disconnect() {
    this.observer?.disconnect()
    this.observer = undefined
  }

  // Utilities

  connectMessageObserver(callback) {
    const observer = new MutationObserver((mutations) => {
      if (mutations.some(mutation =>
        mutation.target == this.element || this.element.contains(mutation.target))) {
        console.log(`${this.idValue}: mutation`)
        callback()
      }
    })

    observer.observe(this.element, {
      characterData: true,
      childList: true,
      subtree: true
    })

    return observer
  }

  preserveStimulusValues(e) {
    // FIXME: Eventually rails will have an official solution. Check this issue: https://github.com/hotwired/turbo/issues/1210
    if (e.target == this.element && e.detail.attributeName == 'data-playback-sentences-index-value') e.preventDefault()
  }
}
