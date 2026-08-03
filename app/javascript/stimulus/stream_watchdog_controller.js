import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = [ "thinking", "retry" ]
  static values = { seconds: { type: Number, default: 120 } }

  connect() {
    this.watchForTheStreamToStall()
  }

  disconnect() {
    this.timeout?.end()
  }

  secondsValueChanged() {
    this.watchForTheStreamToStall()
  }

  watchForTheStreamToStall() {
    this.timeout?.end()
    this.timeout = runAfter(this.secondsValue, () => this.offerToRetry())
  }

  offerToRetry() {
    this.thinkingTargets.forEach((target) => target.classList.add("hidden"))
    this.retryTargets.forEach((target) => target.classList.remove("hidden"))
  }
}
