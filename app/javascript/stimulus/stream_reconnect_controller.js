import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  #observer
  #dropped = false

  connect() {
    this.#observer = new MutationObserver(() => this.#connectionChanged())
    this.#observer.observe(this.element, { attributes: true, attributeFilter: ["connected"] })
  }

  disconnect() {
    this.#observer.disconnect()
  }

  // Server HTML lacks "connected", so a morph would strip it and fake a drop
  keepConnectedAttribute(e) {
    if (e.target == this.element && e.detail.attributeName == "connected") e.preventDefault()
  }

  #connectionChanged() {
    if (!this.#isConnected) {
      this.#dropped = true
      return
    }
    if (!this.#dropped) return

    this.#dropped = false
    this.#catchUpOnMissedBroadcasts()
  }

  #catchUpOnMissedBroadcasts() {
    Turbo.session.refresh(location.href)
  }

  get #isConnected() {
    return this.element.hasAttribute("connected")
  }
}
