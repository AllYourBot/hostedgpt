import { Controller } from '@hotwired/stimulus'
import debounce from "../utils/debounce.js"

export default class extends Controller {

  initialize() {
    this.onResize = undefined
    this.autogrow = this.autogrow.bind(this)
  }

  connect() {
    this.element.style.overflow = 'hidden'
    this.autogrow()

    this.element.addEventListener('input', this.debouncedAutogrow)
    window.addEventListener('resize', this.debouncedAutogrow)
  }

  disconnect() {
    this.element.removeEventListener('input', this.debouncedAutogrow)
    window.removeEventListener('resize', this.debouncedAutogrow)
  }

  debouncedAutogrow = debounce(() => this.autogrow(), 50)
  autogrow() {
    this.element.style.height = 'auto'
    this.element.style.height = `${this.element.scrollHeight + 2}px` // the +2 is a hack to make the size not jump on load. The scrollHeight differs from than actual height for the empty state
  }
}