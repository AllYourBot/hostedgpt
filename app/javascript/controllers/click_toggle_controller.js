import { Controller } from '@hotwired/stimulus'

// This controller listens for a click on the "trigger" element. When it receives one, it toggles the "flippable" class on the "destination" element:
//
// The same element where you are defining the controller must get data-click-toggle-flippable-class="..class(es) named here..."
// Any two elements at the same level as the controller or below get data-click-toggle-target="destination" and data-click-toggle-target="target"

export default class extends Controller {
  static classes = [ "flippable" ]
  static targets = [ "trigger", "destination" ]

  connect () {
    this.triggerTargets.forEach(triggerElement => {

      triggerElement.addEventListener('click', () => this.clicked())
    })
  }

  disconnect () {
    this.triggerTargets.forEach(triggerElement => {
      triggerElement.removeEventListener('click', () => this.clicked())
    })
  }

  clicked () {
    this.destinationTargets.forEach(element => {
      element.classList.toggle(this.flippableClass)
    })
  }
}
