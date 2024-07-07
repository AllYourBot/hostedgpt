import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "text", "assistantText", "userText" ]
  static values = { initialMessageCount: Number }

  connect() {
    this.connected = true
    this.assistantTextTargetsCount = this.assistantTextTargets.length
    this.thoughtsSentCount = 0

    console.log(`## connected with ${this.textTargets.length} text and ${this.assistantTextTargetsCount} assistantText and ${this.userTextTargets.length} userText`)

    // When page loads becuase a new conversation was created (i.e. 1 user message & 1 newly created assistant message), there are a few cases to consider:
    // * The reply may be stubbed out but the job hasn't run, after visit event, before-stream-render may be the next event that fires
    // * The reply may be stubbed out and the job is running and just about to finish, after visit event, morph-element may be the next and only event that fires
    // * The reply may already be there (e.g. job ran & completely finished) turbo:visit will be first and only event that fires

    document.addEventListener('turbo:before-stream-render', this.parseReplaceWords) // the streaming response triggers this
    if (this.hasAssistantTextTarget) this.assistantTextTargets.last().addEventListener('turbo:morph-element', this.firstParseWordsMorph) // in the 1st response an empty reply message can be there
    document.addEventListener('turbo:visit', this.firstParseWordsVisit) // in the 1st response, the reply can already be there upon load
    this.firstParseWordsMorph() // sometimes the controller is slow to connect and even misses the visit
  }

  disconnect() {
    document.removeEventListener('turbo:before-stream-render', this.parseReplaceWords)
    if (this.hasAssistantTextTarget) this.assistantTextTargets.forEach((target) => {
      target.removeEventListener('turbo:morph-element', this.boundParseWords)
      target.removeEventListener('turbo:morph-element', this.firstParseWordsMorph)
    })
    document.removeEventListener('turbo:visit', this.firstParseWordsVisit)
  }

  assistantTextTargetConnected(target) {
    if (!this.connected) return
    if (this.assistantTextTargets.length <= this.assistantTextTargetsCount) return

    target.addEventListener('turbo:morph-element', this.boundParseWords) // sometimes a streams is missed so then morph updates things
    this.assistantTextTargetsCount += 1
    this.thoughtsSentCount = 0
    console.log(`## connected now with ${this.assistantTextTargetsCount} assistantText and ${this.userTextTargets.length} userText`)
    Reset.Speaker()

    this.parseWords(target, 'targetConnected')
  }

  parseReplaceWords = (event) => { if (event.target.getAttribute('action') == 'replace') this.parseWords(event.detail.newStream.querySelector('template').content?.firstChild?.nextSibling?.querySelector('[data-speaker-target="text assistantText"]'), 'replace') }
  firstParseWordsMorph = () => { if (this.assistantTextTargets.length == 1 && this.userTextTargets.length == 1) this.parseWords(this.assistantTextTargets.first(), 'first morph or on connect')}
  firstParseWordsVisit = (event) => { if (event.detail.action == "advance" && this.assistantTextTargets.length == 1 && this.userTextTargets.length == 1) this.parseWords(this.assistantTextTargets.first(), 'visit advance') }
  boundParseWords = (event) => { this.morphWasFirstEventAfterVisit = false; this.parseWords(event.target, 'morph') }
  parseWords(target, source) {
    if (!target) return
    if (source == 'morph' &&
       (target != this.assistantTextTargets.last() || target != this.textTargets.last())) {
      console.log(`morphed but not last`, target, this.assistantTextTargets.last(), this.textTargets.last())
      return
    }
    if (Listener.disabled) return

    console.log(`## parsingWords (${source})`, target)

    const thinking = target.getAttribute('data-thinking') === 'true'
    const thoughts = SpeechService.splitIntoThoughts(target.innerText)

    for(this.thoughtsSentCount; this.thoughtsSentCount < thoughts.length-1; this.thoughtsSentCount ++) {
      let thought = thoughts[this.thoughtsSentCount]
      if (thought.includes('::ServerError') || thought.includes('Faraday::')) break  // client is displaying a server error
      Prompt.Speaker.toSay(thought)
    }

    if (!thinking && this.thoughtsSentCount == thoughts.length-1) {
      Prompt.Speaker.toSay(thoughts[this.thoughtsSentCount])
      this.thoughtsSentCount += 1
    }
  }
}
