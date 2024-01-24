import { Controller } from '@hotwired/stimulus'
import debounce from "../utils/debounce.js"

// This controller listens for a click on the "trigger" element. When it receives one, it toggles the "flippable" class on the "destination" element:
//
// The same element where you are defining the controller must get data-click-toggle-flippable-class="..class(es) named here..."
// Any two elements at the same level as the controller or below get data-click-toggle-target="destination" and data-click-toggle-target="target"

export default class extends Controller {
  static classes = [ "flippable" ]
  static targets = [ "trigger", "destination" ]

  connect() {
    this.triggerTargets.forEach(triggerElement => {
      triggerElement.addEventListener('click', this)
    })
  }

  disconnect() {
    this.triggerTargets.forEach(triggerElement => {
      triggerElement.removeEventListener('click', this)
    })
  }

  handleEvent = debounce(this.toggleClasses, 100)

  toggleClasses() {
    this.destinationTargets.forEach(element => {
      element.classList.toggle(this.flippableClass)
    })

    // Showing and hiding elements can cause the page to flow differently, very similarly to what happens when the browser size changes. Throw
    // this event in case we have other listeners on the resize event.
    window.dispatchEvent(new Event('resize'))
  }
}
