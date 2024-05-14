import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "text" ]
  static values = { initialMessageCount: Number }

  connect() {
    this.connected = true
    this.textTargetsCount = this.textTargets.length
    this.thoughtsSentCount = 0

    this.textTargets.forEach((target) => target.addEventListener('turbo:before-morph', this.boundParseWords))
  }

  textTargetConnected(target) {
    if (!this.connected) return

    if (this.textTargets.length > this.textTargetsCount) {
      target.addEventListener('turbo:before-morph', this.boundParseWords)
      this.textTargetsCount += 1
      this.thoughtsSentCount = 0
      Reset.Speaker()
    }

    this.parseWords(target)
  }

  disconnect() {
    this.textTargets.forEach((target) => target.removeEventListener('turbo:before-morph', this.boundParseWords))
  }

  boundParseWords = (event) => { this.parseWords(event) }
  parseWords(target) {
    if (Microphone.off) return

    const thinking = target.getAttribute('data-thinking') === 'true'
    const thoughts = SpeechService.splitIntoThoughts(target.innerText)

    for(this.thoughtsSentCount; this.thoughtsSentCount < thoughts.length-1; this.thoughtsSentCount ++)
      Prompt.Speaker.toSay(thoughts[this.thoughtsSentCount])

    if (!thinking && this.thoughtsSentCount == thoughts.length-1)
      Prompt.Speaker.toSay(thoughts[this.thoughtsSentCount])
  }
}
