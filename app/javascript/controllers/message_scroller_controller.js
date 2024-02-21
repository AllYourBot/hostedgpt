window.lastMessageControllerInstance = null
window.wasScrolledToBottom = false

import { Controller } from "@hotwired/stimulus"
import debounce from "utils/debounce"

export default class extends Controller {
  scrollableTarget = null

  static values = {
    scrollDown: { type: Boolean, default: false },
    instant: { type: Boolean, default: false },
    onlyScrollDownIfWasBottom: { type: Boolean, default: false }
  }

  connect() {
    if (window.lastMessageControllerInstance) {
      window.lastMessageControllerInstance.disconnect()
      window.lastMessageControllerInstance = this
    }
    this.scrollableTarget = document.getElementById('right-content')
    window.addEventListener('resize', this.debouncedScrollDownIfWasBottom) // resizing browser & composer size changes

    this.considerScroll()
  }

  disconnect() {
    window.removeEventListener('resize', this.debouncedScrollDownIfWasBottom)
  }

  considerScroll() {
    if (this.scrollDownValue)
      this.debouncedScrollDown()
    else if (this.onlyScrollDownIfWasBottomValue)
      this.scrollDownIfWasBottom()
  }

  debouncedScrollDownIfWasBottom = debounce(() => this.scrollDownIfWasBottom(), 50, true)
  scrollDownIfWasBottom() {
    if (window.wasScrolledToBottom) this.debouncedScrollDown(false)
  }

  debouncedScrollDown = debounce((instant) => this.scrollDown(instant), 50, true)
  scrollDown(instant) {
    let instantScroll = instant ?? this.instantValue
    setTimeout(() => {
      window.wasScrolledToBottom = true // even if we don't get the full way, it was the intention

      this.scrollableTarget.scrollTo({
        top: this.scrollableTarget.scrollHeight,
        behavior: instantScroll ? "auto" : "smooth"
      })
    }, instantScroll ? 300 : 0) // without the delay sometimes the page hasn't finished rendering and it doesn't go to the bottom
  }
}
