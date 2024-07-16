import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { index: Number, sentencesIndex: Number }
  static targets = [ "assistantText" ]
  static outlets = [ "transition" ]

  connect() {
    this.manualSpeaking = false
  }

  toggleSpeakingMessage() {
    this.manualSpeaking = !this.manualSpeaking

    if (this.manualSpeaking) {
      if (this.hasTransitionOutlet) this.transitionOutlet.toggleClassOn()
      Speaker.onBusyDone = () => this.toggleSpeakingMessage()
      this.sentencesIndexValue = 0
      this.startSpeakingMessage()
    } else {
      Speaker.onBusyDone = () => {}
      if (this.hasTransitionOutlet) this.transitionOutlet.toggleClassOff()
      Reset.Speaker()
      this.stopSpeakingMessage()
    }
  }

  startSpeakingMessage() {
    this.speaker.playbackIndexValue = this.indexValue

    this.observer = new MutationObserver((mutations) => {
      if (mutations.some(mutation => mutation.target == this.element)) {
        console.log('mutation', mutations)
        this.messageTextUpdated('mutation')
      }
    })
    this.observer.observe(this.element, {
      characterData: true,
      childList: true,
      subtree: true
    })

    this.messageTextUpdated('initial')
  }

  stopSpeakingMessage() {
    this.observer?.disconnect()
  }

  messageTextUpdated(src = '') {
    //console.log(`${this.indexValue}: messageTextUpdated(${src}) ${Listener.enabled ? 'enabled' : 'disabled'} :: from ${this.sentencesIndexValue} to ... (${this.assistantTextTarget.textContent})`)
    if (Listener.disabled && !this.manualSpeaking) return
    const sentences = SpeechService.splitIntoThoughts(this.assistantTextTarget.textContent)
    if (sentences.length == 0) return

    //console.log(`processing message ${this.indexValue}...`, sentences)
    const thinkingDone = this.assistantTextTarget.getAttribute('data-thinking') === 'false'
    const toSentenceIndex = thinkingDone ? sentences.length-1 : sentences.length-2

    //console.log(`speaking from ${this.sentencesIndexValue} to ${toSentenceIndex} (done? ${thinkingDone})`)
    this.speakSentencesTo(sentences, toSentenceIndex)

    if (thinkingDone && !this.manualSpeaking) this.speaker?.advancePlayback()
  }

  speakSentencesTo(sentences, toIndex) {
    if (this.sentencesIndexValue > toIndex) return
    for (this.sentencesIndexValue; this.sentencesIndexValue <= toIndex; this.sentencesIndexValue ++) {
      if (!sentences[this.sentencesIndexValue]) break
      if (sentences[this.sentencesIndexValue].includes('::ServerError') || sentences[this.sentencesIndexValue].includes('Faraday::')) break  // client is displaying a server error
      Prompt.Speaker.toSay(sentences[this.sentencesIndexValue])
    }
  }

  preserveStimulusValues(e) {
    if (e.target == this.element && e.detail.attributeName == "data-playback-sentences-index-value") e.preventDefault()
  }
}
