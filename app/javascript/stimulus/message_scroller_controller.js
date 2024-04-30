window.lastMessageControllerInstance = null
window.wasScrolledToBottom = false

import { Controller } from "@hotwired/stimulus"
import throttle from "./utils/throttle"

export default class extends Controller {
  scrollableTarget = null

  static values = {
    scrollDown: { type: Boolean, default: false },
    instantly: { type: Boolean, default: false },
    onlyScrollDownIfScrolledToBottom: { type: Boolean, default: false }
  }

  get bottom() { return this.scrollableTarget.scrollHeight }
  get scrollPosition() { return this.scrollableTarget.scrollTop + this.scrollableTarget.clientHeight }

  connect() {
    if (window.lastMessageControllerInstance) window.lastMessageControllerInstance.disconnect()
    window.lastMessageControllerInstance = this

    this.scrollableTarget = document.getElementById('messages')  // Could not reference this as a target
                                                                      // because it's higher in DOM than messages.
    window.addEventListener('resize', this.throttledScrollDownIfScrolledToBottom)
    window.addEventListener('main-column-changed', this.throttledScrollDownIfScrolledToBottom)

    this.considerScroll()
  }

  disconnect() {
    window.removeEventListener('resize', this.throttledScrollDownIfScrolledToBottom)
    window.removeEventListener('main-column-changed', this.throttledScrollDownIfScrolledToBottom)
    window.removeEventListener('load', this.throttledScrollDownIfScrolledToBottom)
  }

  considerScroll() {
    if (this.scrollDownValue)
      this.throttledScrollDown()
    else if (this.onlyScrollDownIfScrolledToBottomValue)
      this.scrollDownIfScrolledToBottom()
  }

  discardScrollDown = (event) => { if (window.imageLoadingForSystemTestsToCheck[event?.detail]) { console.log(`discarding ${event.detail}`); window.imageLoadingForSystemTestsToCheck[event.detail] = 'done' } }
  throttledScrollDownIfScrolledToBottom = throttle((event) => this.scrollDownIfScrolledToBottom(event), 50, this.discardScrollDown)
  scrollDownIfScrolledToBottom(event) {
    if (window.wasScrolledToBottom)
      this.throttledScrollDown(event)
    else if (window.imageLoadingForSystemTestsToCheck[event?.detail])
      window.imageLoadingForSystemTestsToCheck[event.detail] = 'done'
  }

  throttledScrollDown = throttle((event) => this.scrollDown(event), 50)
  scrollDown(event) {
    this.scrollDownRetry(event?.detail, 0)
  }

  scrollDownRetry(key, attempt) {
    if (attempt < 5 && this.bottom == this.scrollPosition) {
      setTimeout(() => { this.scrollDownRetry(key, attempt + 1) }, 100)
      return
    } // will delay up to 500ms if unable to scroll down

    window.wasScrolledToBottom = true // even if we don't get the full way, it was the intention

    this.scrollableTarget.scrollTo({
      top: this.bottom,
      behavior: this.instantlyValue ? "auto" : "smooth"
    })

    if (key) setTimeout(() => { window.imageLoadingForSystemTestsToCheck[key] = 'done' }, 500)

    if (this.instantlyValue) {
      // This occurs immediately after page load; we jump to the bottom as fast as we can. However,
      // sometimes this fires and jumps before the page is fully loaded so scrollHeight it calculates
      // may not be correct yet. As a precaution, we add one more event to fire on window load to scroll
      // down a bit further. This was hard to test so I'm not yet certain it solves the problem.
      window.addEventListener('load', this.throttledScrollDownIfScrolledToBottom, { once: true })
    }

    setTimeout(() => { window.scrolledDownForSystemTestsToCheck = true }, 500)
  }
}
