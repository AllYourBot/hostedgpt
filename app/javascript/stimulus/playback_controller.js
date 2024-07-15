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
        this.speakMessage('mutation')
      }
    })
    this.observer.observe(this.element, {
      characterData: true,
      childList: true,
      subtree: true
    })

    window.debug = this.assistantTextTarget
    this.speakMessage('initial')
  }

  stopSpeakingMessage() {
    console.log(`stopSpeakingMessage(${this.indexValue})`)
    this.observer?.disconnect()
  }

  speakMessage(src = '') {
    console.log(`speakMessage(${Listener.disabled}) ${src} :: ${this.indexValue} = ${this.assistantTextTarget.innerText}`)
    if (Listener.disabled) return
    const sentences = SpeechService.splitIntoThoughts(this.assistantTextTarget.innerText)
    if (sentences.length == 0) return

    console.log(`processing message ${this.indexValue}...`, sentences)
    const thinkingDone = this.assistantTextTarget.getAttribute('data-thinking') === 'false'
    const toSentenceIndex = thinkingDone ? sentences.length : sentences.length - 1

    console.log(`speaking from ${this.sentencesIndexValue} to ${toSentenceIndex} (done? ${thinkingDone})`)
    this.speakSentencesFromTo(sentences, this.sentencesIndexValue, toSentenceIndex)
    this.sentencesIndexValue = toSentenceIndex + 1

    if (thinkingDone) this.done()
  }

  speakSentencesFromTo(sentences, fromIndex, toIndex) {
    toIndex = Math.max(toIndex, 0)
    if (fromIndex >= toIndex) return
    for (let i = fromIndex; fromIndex <= toIndex; i ++) {
      if (!sentences[i]) break
      if (sentences[i].includes('::ServerError') || sentences[i].includes('Faraday::')) break  // client is displaying a server error
      Prompt.Speaker.toSay(sentences[i])
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
