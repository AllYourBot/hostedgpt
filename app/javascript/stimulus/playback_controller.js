import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { index: Number, sentencesIndex: Number }
  static targets = [ "assistantText" ]

  connect() {
    console.log(`playback connected for message ${this.indexValue}`, this.element)
  }

  // speakerActiveValueChanged() {
  //   if (!this.speaker) return

  //   if (this.speakerActiveValue)
  //     this.startSpeakingMessage()
  //   else
  //     this.stopSpeakingMessage()
  // }

  startSpeakingMessage() {
    console.log(`startSpeakingMessage(${this.indexValue})`)
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

    window.debug = this.assistantTextTarget
    this.messageTextUpdated('initial')
  }

  stopSpeakingMessage() {
    console.log(`stopSpeakingMessage(${this.indexValue})`)
    this.observer?.disconnect()
  }

  messageTextUpdated(src = '') {
    console.log(`${this.indexValue}: messageTextUpdated(${src}) ${Listener.enabled ? 'enabled' : 'disabled'} :: from ${this.sentencesIndexValue} to ... (${this.assistantTextTarget.textContent})(${this.assistantTextTarget.innerText})(${this.assistantTextTarget.innerHTML})`)
    if (Listener.disabled) return
    const sentences = SpeechService.splitIntoThoughts(this.assistantTextTarget.textContent)
    if (sentences.length == 0) return

    console.log(`processing message ${this.indexValue}...`, sentences)
    const thinkingDone = this.assistantTextTarget.getAttribute('data-thinking') === 'false'
    const toSentenceIndex = thinkingDone ? sentences.length-1 : sentences.length-2

    console.log(`speaking from ${this.sentencesIndexValue} to ${toSentenceIndex} (done? ${thinkingDone})`)
    this.speakSentencesTo(sentences, toSentenceIndex)

    if (thinkingDone) this.done()
  }

  speakSentencesTo(sentences, toIndex) {
    if (this.sentencesIndexValue > toIndex) return
    for (this.sentencesIndexValue; this.sentencesIndexValue <= toIndex; this.sentencesIndexValue ++) {
      if (!sentences[this.sentencesIndexValue]) break
      if (sentences[this.sentencesIndexValue].includes('::ServerError') || sentences[this.sentencesIndexValue].includes('Faraday::')) break  // client is displaying a server error
      Prompt.Speaker.toSay(sentences[this.sentencesIndexValue])
    }
  }

  done() {
    console.log(`done() for ${this.indexValue}`)
    this.speaker?.advancePlayback()
  }

  preserveStimulusValues(e) {
    if (e.target == this.element && e.detail.attributeName == "data-playback-sentences-index-value") e.preventDefault()
  }
}
