import { Controller } from "@hotwired/stimulus"

// While the assistant is streaming a reply the server re-renders this element every ~100ms, which reconnects
// this controller and restarts its timer. If the stream dies -- the job crashed, the worker went away, the
// websocket dropped -- no re-render ever arrives, the timer expires, and we replace the thinking indicator
// with a Retry button so the conversation isn't left waiting on a reply that will never come.
//
// Example:
//
// <div data-controller="stream-watchdog" data-stream-watchdog-seconds-value="120">
//   <span data-stream-watchdog-target="thinking"></span>
//   <div class="hidden" data-stream-watchdog-target="retry">Retry</div>
// </div>

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
