import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {index: Number, sentencesIndex: Number, speakerActive: Boolean }

  connect() {
    console.log(`playback connected for message ${this.indexValue} and it's initially active = ${this.speakerActiveValue}`)
  }

  speakerActiveValueChanged() {
    if (!this.speaker) return

    if (this.speakerActiveValue) {
      console.log(`active value for ${this.indexValue} is now ${this.speakerActiveValue}`)
      this.speaker.playbackIndexValue = this.indexValue
    }
  }

  // static targets = [ "assistantText" ]

  // get newlyCreatedConversation() {
  //   return params.from == "create" &&
  //     new RegExp(`^/assistants/\\d+/messages/new`).test(request.referer_path)
  // }

  // connect() {
  //   window.debug = this
  //   this.sentencesIndex = 0
  //   this.messagesIndex = this.assistantTextTargets.length

  //   document.addEventListener('turbo:visit', this.boundInit) // turbo visit is firing again when messagers stream in, need to make sure this ONLY fires once on initial page load
  //   document.addEventListener('turbo:morph', this.boundSpeakMessages)
  //   document.addEventListener('turbo:before-stream-render', this.boundSpeakMessages)

  //   this.init()
  // }

  // boundInit = () => { this.init() }
  // init() {
  //   console.log('init()')

  //   if (this.newlyCreatedConversation) {
  //     console.log('subtracting 1')
  //     this.messagesIndex = this.assistantTextTargets.length - 1
  //   }

  //   this.speakMessages()
  // }

  // disconnect() {
  //   document.removeEventListener('turbo:visit', this.boundInit)
  //   document.removeEventListener('turbo:morph', this.boundSpeakMessages)
  //   document.removeEventListener('turbo:before-stream-render', this.boundSpeakMessages)
  // }

  // boundSpeakMessages = () => { this.speakMessages() }
  // speakMessages() {
  //   console.log(`speakMessages() :: ${this.messagesIndex} of ${this.assistantTextTargets.length}`)
  //   let message, sentences, messageDone, toSentenceIndex
  //   if (Listener.disabled) return

  //   for (this.messagesIndex; this.messagesIndex < this.assistantTextTargets.length; this.messagesIndex ++) {
  //     message = this.assistantTextTargets[this.messagesIndex]

  //     sentences = SpeechService.splitIntoThoughts(message.innerText)
  //     if (sentences.length == 0) continue
  //     console.log(`processing message ${this.messagesIndex}...`, sentences)
  //     messageDone = message.getAttribute('data-thinking') === 'false'
  //     toSentenceIndex = messageDone ? sentences.length : sentences.length-1
  //     if (toSentenceIndex < 0) toSentenceIndex = 0

  //     console.log(`speaking from ${this.sentencesIndex} to ${toSentenceIndex} (done? ${messageDone})`)
  //     this.speakSentencesFromTo(sentences, this.sentencesIndex, toSentenceIndex)
  //     this.sentenceIndex = messageDone ? 0 : toSentenceIndex+1
  //   }
  //   if (!messageDone) this.messagesIndex -= 1 // we need to check this message again
  // }

  // speakSentencesFromTo(sentences, fromIndex, toIndex) {
  //   for (let i = fromIndex; fromIndex <= toIndex; i ++) {
  //     if (!sentences[i]) break
  //     if (sentences[i].includes('::ServerError') || sentences[i].includes('Faraday::')) break  // client is displaying a server error
  //     Prompt.Speaker.toSay(sentences[i])
  //   }
  // }
}
