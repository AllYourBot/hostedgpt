import { Controller } from '@hotwired/stimulus'

// The sidebar is a fixed, narrow column, so long labels (e.g. assistant names) get
// truncated with an ellipsis. Rather than widening the sidebar for everyone, this
// controller pops a full, untruncated copy of the element on top of the page on
// hover -- appearing to "expand" out over the main content -- then removes it again.
// It leaves the underlying element and surrounding layout completely alone.
export default class extends Controller {
  static classes = ["popout"]

  show() {
    if (!this.truncated) return // nothing is actually cut off, nothing to do

    const rect = this.element.getBoundingClientRect()
    const clone = this.element.cloneNode(true)

    clone.removeAttribute('id')
    clone.removeAttribute('data-controller')
    clone.removeAttribute('data-action')
    clone.setAttribute('tabindex', '-1')
    clone.setAttribute('aria-hidden', 'true')
    clone.classList.remove('truncate', 'flex-1')
    clone.querySelectorAll('.truncate').forEach(el => el.classList.remove('truncate'))
    clone.classList.add('overflow-expand-popout', ...this.popoutClasses)
    Object.assign(clone.style, {
      position: 'fixed',
      top: `${rect.top}px`,
      left: `${rect.left}px`,
      height: `${rect.height}px`,
      width: 'max-content',
      maxWidth: 'none',
      zIndex: '50',
      pointerEvents: 'none',
    })

    document.body.appendChild(clone)
    this.clone = clone

    this.boundHide = () => this.hide()
    window.addEventListener('scroll', this.boundHide, { capture: true, once: true })
  }

  // A label can truncate just its text (e.g. to keep a trailing icon visible), so check
  // the inner .truncate elements as well as the element itself.
  get truncated() {
    return [this.element, ...this.element.querySelectorAll('.truncate')]
      .some(el => el.scrollWidth > el.clientWidth)
  }

  hide() {
    this.clone?.remove()
    this.clone = null
    if (this.boundHide) window.removeEventListener('scroll', this.boundHide, { capture: true })
  }

  disconnect() {
    this.hide()
  }
}
