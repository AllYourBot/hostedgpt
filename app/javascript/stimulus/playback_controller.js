import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: Number, sentencesIndex: Number }
  static targets = [ "assistantText" ]
  static outlets = [ "transition" ]

  #speaking = false
  #promptedEverything = false

  // Ths only time playbackController initiates playback is when the user clicks start on the "Play" button.
  // In voice mode (i.e. the mic button was activated) then speaker controller calls into this controller.

  connect() {
    this.playClicked = false // not quite an actual state, it's a very short-duration flag, so not elevating this to a value
  }

  // Each streamed chunk re-renders the button, which comes back showing play
  transitionOutletConnected(button) {
    if (this.#speaking) button.toggleClassOn()
  }

  toggleSpeakingMessage() {
    if (this.#speaking)
      this.clickedStop()
    else
      this.clickedStart()
  }

  clickedStart() {
    this.playClicked = true
    this.sentencesIndexValue = 0
    this.beginSpeakingMessage()
  }

  beginSpeakingMessage() {
    console.log(`${this.idValue}: beginSpeakingMessage()`)
    this.#showStopUntilSpoken()
    this.observer?.disconnect()
    this.observer = this.connectMessageObserver(() => this.messageTextUpdated('observer'))
    this.messageTextUpdated('initial')
  }

  clickedStop() {
    const readingInVoiceMode = !this.playClicked
    Speaker.onBusyDone = () => { }
    this.discontinueSpeakingMessage()

    Stop.Speaker() // onBusyDone must be cleared before this is stopped
    if (readingInVoiceMode) this.speaker?.playbackFinishedPrompting(this.idValue) // so the next reply still auto-plays
  }

  discontinueSpeakingMessage() {
    console.log(`${this.idValue}: discontinueSpeakingMessage() and observer is`, this.observer)
    this.#speaking = false
    this.playClicked = false
    if (this.hasTransitionOutlet) this.transitionOutlet.toggleClassOff()
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
    if (isThinkingDone) this.#promptedEverything = true
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

  #showStopUntilSpoken() {
    this.#speaking = true
    this.#promptedEverything = false
    if (this.hasTransitionOutlet) this.transitionOutlet.toggleClassOn()

    const existingBusyDone = this.playClicked ? (Speaker.onBusyDone ?? (() => {})) : () => {}
    Speaker.onBusyDone = () => { this.#speakerFinished(); existingBusyDone() }
  }

  // In voice mode the speaker goes quiet whenever it catches up with a reply that is still streaming
  #speakerFinished() {
    const moreToRead = !this.playClicked && Listener.enabled && !this.#promptedEverything
    if (moreToRead) return

    if (this.playClicked)
      this.clickedStop()
    else
      this.discontinueSpeakingMessage()
  }
}
