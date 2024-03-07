import { Controller } from "@hotwired/stimulus"
import throttle from "stimulus/utils/throttle"

export default class extends Controller {

  initialize() {
    this.onResize = undefined
    this.autogrow = this.autogrow.bind(this)
  }

  connect() {
    this.element.style.overflow = 'hidden'
    this.autogrow()

    this.element.addEventListener('input', this.throttledAutogrow)
    window.addEventListener('resize', this.throttledAutogrow)
    window.addEventListener('right-column-changed', this.throttledAutogrow)
  }

  disconnect() {
    this.element.removeEventListener('input', this.throttledAutogrow)
    window.removeEventListener('resize', this.throttledAutogrow)
    window.removeEventListener('right-column-changed', this.throttledAutogrow)
  }

  throttledAutogrow = throttle(() => this.autogrow(), 50)
  autogrow() {
    const prevHeight = this.element.style.height
    this.element.style.height = 'auto'
    const newHeight = `${this.element.scrollHeight + 2}px`  // The +2 prevents jumping on load. The scrollHeight
                                                            // from the actual height for the empty state.
    this.element.style.height = newHeight

    if (prevHeight != newHeight) window.dispatchEvent(new CustomEvent('right-column-changed'))
  }
}