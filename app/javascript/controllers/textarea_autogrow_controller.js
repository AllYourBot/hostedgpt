import { Controller } from '@hotwired/stimulus'

export default class extends Controller {

  initialize () {
    this.onResize = undefined
    this.resizeDebounceDelayValue = 100
    this.autogrow = this.autogrow.bind(this)
  }

  connect () {
    this.element.style.overflow = 'hidden'
    this.onResize = this.resizeDebounceDelayValue > 0 ? debounce(this.autogrow, this.resizeDebounceDelayValue) : this.autogrow

    this.autogrow()

    this.element.addEventListener('input', this.autogrow)
    window.addEventListener('resize', this.onResize)
  }

  disconnect () {
    window.removeEventListener('resize', this.onResize)
  }

  autogrow () {
    this.element.style.height = 'auto'
    this.element.style.height = `${this.element.scrollHeight + 2}px`
  }
}

function debounce (callback, delay) {
  return (...args) => {
    const context = this
    clearTimeout(timeout)

    timeout = setTimeout(() => callback.apply(context, args), delay)
  }
}