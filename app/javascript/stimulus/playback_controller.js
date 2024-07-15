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
    console.log('startSpeakingMessage()')
    this.speaker.playbackIndexValue = this.indexValue

    this.observer = new MutationObserver(() => this.speakMessage('mutation'))
    this.observer.observe(this.assistantTextTarget, {
      characterData: true,
      childList: true,
      subtree: true,
      attributes: true
    })

    window.debug = this.assistantTextTarget
    this.speakMessage('initial')
  }

  stopSpeakingMessage() {
    console.log('stopSpeakingMessage()')
    this.observer?.disconnect()
  }

  // speak() {
  //   console.log(`speak()`)
  //   Prompt.Speaker.toSay("I am testing this feature")
  // }

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

    if (thinkingDone) done()
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
    this.speakerActiveValue = false
    this.speaker?.advancePlayback()
  }
}
