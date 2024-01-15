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
    this.element.removeEventListener('input')
    window.removeEventListener('resize')
  }

  autogrow () {
    this.element.style.height = 'auto'
    this.element.style.height = `${this.element.scrollHeight + 2}px` // the +2 is a hack to make the size not jump on load. The scrollHeight differs from than actual height for the empty state
  }
}

function debounce (callback, delay) {
  return (...args) => {
    const context = this
    clearTimeout(timeout)

    timeout = setTimeout(() => callback.apply(context, args), delay)
  }
}