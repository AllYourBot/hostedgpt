import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "text" ]
  static values = { initialMessageCount: Number }

  connect() {
    this.connected = true
    this.textTargetsCount = this.textTargets.length
  }

  textTargetConnected(target) {
    if (!this.connected || Listener.muted) return

    const thinking = target.getAttribute('data-thinking') === 'true'
    const thoughts = SpeechService.splitIntoThoughts(target.innerText)

    console.log(`text target connected and ${this.textTargets.length} >? ${this.textTargetsCount} (${thinking}) with "${target.innerText}"`)

    if (this.textTargets.length > this.textTargetsCount) {
      this.textTargetsCount += 1
      this.thoughtsSentCount = 0
      Reset.Speaker()
    }

    for(this.thoughtsSentCount; this.thoughtsSentCount < thoughts.length-1; this.thoughtsSentCount ++)
      Prompt.Speaker.toSay(thoughts[this.thoughtsSentCount])

    if (!thinking && this.thoughtsSentCount == thoughts.length-1)
      Prompt.Speaker.toSay(thoughts[this.thoughtsSentCount])
  }
}
