import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "text", "assistantText" ]
  static values = { initialMessageCount: Number }

  connect() {
    this.connected = true
    this.assistantTextTargetsCount = this.assistantTextTargets.length
    this.thoughtsSentCount = 0

    console.log(`## connected with ${this.textTargets.length} text and ${this.assistantTextTargetsCount} assistantText`)

    document.addEventListener('turbo:before-stream-render', this.parseReplaceWords) // the streaming response triggers this
    if (this.hasAssistantTextTarget) this.assistantTextTargets.last().addEventListener('turbo:morph-element', this.firstParseWords) // in the 1st response an empty reply message can be there
    document.addEventListener('turbo:visit', this.firstParseWords) // in the 1st response, the reply can already be there upon load
    this.firstParseWords() // sometimes the controller is slow to connect
  }

  disconnect() {
    document.addEventListener('turbo:before-stream-render', this.parseReplaceWords)
    if (this.hasAssistantTextTarget) this.assistantTextTargets.forEach((target) => target.removeEventListener('turbo:morph-element', this.boundParseWords))
    document.removeEventListener('turbo:visit', this.firstParseWords)
  }

  assistantTextTargetConnected(target) {
    if (!this.connected) return
    if (this.assistantTextTargets.length <= this.assistantTextTargetsCount) return

    target.addEventListener('turbo:morph-element', this.boundParseWords) // sometimes a streams is missed so then morph updates things
    this.assistantTextTargetsCount += 1
    this.thoughtsSentCount = 0
    Reset.Speaker()

    this.parseWords(target, 'targetConnected')
  }

  parseReplaceWords = (event) => { console.log('replace', event.target.getAttribute('action')); if (event.target.getAttribute('action') == 'replace') this.parseWords(event.detail.newStream.querySelector('template').content?.firstChild?.nextSibling?.querySelector('[data-speaker-target="text assistantText"]'), 'replace') }
  firstParseWords = () => { if (this.assistantTextTargets.length == 1) this.parseWords(this.assistantTextTargets.first(), 'visit replace or first morph') }
  boundParseWords = (event) => { this.parseWords(event.target, 'morph') }
  parseWords(target, source) {
    if (!target) return
    console.log(`parseWords (${source})`, target)
    if (source == 'morph' &&
       (target != this.assistantTextTargets.last() || target != this.textTargets.last())) {
      console.log(`morphed but not last`, target, this.assistantTextTargets.last(), this.textTargets.last())
      return
    }
    if (Microphone.off) return

    console.log(`## parsingWords (${source})`, target)

    const thinking = target.getAttribute('data-thinking') === 'true'
    const thoughts = SpeechService.splitIntoThoughts(target.innerText)

    for(this.thoughtsSentCount; this.thoughtsSentCount < thoughts.length-1; this.thoughtsSentCount ++)
      Prompt.Speaker.toSay(thoughts[this.thoughtsSentCount])

    if (!thinking && this.thoughtsSentCount == thoughts.length-1) {
      Prompt.Speaker.toSay(thoughts[this.thoughtsSentCount])
      this.thoughtsSentCount += 1
    }
  }
}
