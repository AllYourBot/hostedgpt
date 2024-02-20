window.lastMessageControllerInstance = null

import { Controller } from "@hotwired/stimulus"
import debounce from "utils/debounce"

export default class extends Controller {
  static values = {
    scrollDown: { type: Boolean, default: false },
    onlyScrollDownIfNearBottom: { type: Boolean, default: false }
  }

  connect() {
    if (window.lastMessageControllerInstance) {
      window.lastMessageControllerInstance.disconnect()
      window.lastMessageControllerInstance = this
    }
    window.addEventListener('resize', this.debouncedConsiderScroll)
    this.considerScroll()
  }

  disconnect() {
    window.removeEventListener('resize', this.debouncedConsiderScroll)
  }

  debouncedConsiderScroll = debounce(() => this.considerScroll(), 50)
  considerScroll() {
    const scrollableTarget = document.getElementById('right-content')
    const scrollOffset = scrollableTarget.scrollHeight - scrollableTarget.scrollTop
    const nearBottom = Math.abs(scrollOffset - scrollableTarget.clientHeight) <= 20

    if (this.scrollDownValue || (this.onlyScrollDownIfNearBottomValue && nearBottom)) {
      setTimeout(() => {
        scrollableTarget.scrollTo({
          top: scrollableTarget.scrollHeight,
          behavior: "smooth"
        })
      }, this.scrollDownValue ? 500 : 0) // without the delay sometimes the page hasn't finished rendering and it doesn't go to the bottom
    }
  }
}
