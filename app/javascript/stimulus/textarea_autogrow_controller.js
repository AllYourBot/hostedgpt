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
    window.addEventListener('turbo:morph', this.throttledAutogrow)
    window.addEventListener('resize', this.throttledAutogrow)
    window.addEventListener('main-column-changed', this.throttledAutogrow)
  }

  disconnect() {
    this.element.removeEventListener('input', this.throttledAutogrow)
    window.removeEventListener('turbo:morph', this.throttledAutogrow)
    window.removeEventListener('resize', this.throttledAutogrow)
    window.removeEventListener('main-column-changed', this.throttledAutogrow)
  }

  throttledAutogrow = throttle((event) => { if (!event.detail.fromAutogrow) this.autogrow(event) }, 50)
  autogrow() {
    const prevHeight = getComputedStyle(this.element).height
    this.element.style.height = 'auto'
    const newHeight = `${this.element.scrollHeight+2}px` // scrollHeight is two less than computedHeight, this prevents jumps
    this.element.style.height = newHeight

    if (prevHeight != newHeight) window.dispatchEvent(new CustomEvent('main-column-changed', { detail: { fromAutogrow: true } })) // TODO: prevents infinite event loop, why is this happening sometimes?
  }

  submitForm() {
    this.element.closest('form').requestSubmit()
  }
}