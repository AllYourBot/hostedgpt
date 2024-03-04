import { Controller } from '@hotwired/stimulus'

// Example:
//
// <div data-controller="transition" data-transition-toggle-class="!hidden">
//   <div id="element-that-shows-and-hides" class="block" data-transition-target="transitionable"></div>
//   <a href="#" data-action="transition#toggleClass">click to toggle</a>
// </div>
//
// Every element that is of target = me will have the class toggled.

export default class extends Controller {
  static classes = [ "toggle" ]
  static targets = [ "transitionable" ]
  static values = {
    afterTimeout: Number
  }

  connect() {
    this.on = false
    if (this.afterTimeoutValue) setTimeout(() => this.toggleClass(), this.afterTimeoutValue)
  }

  toggleClass() {
    this.on = !this.on

    this.transitionableTargets.forEach(element => {
      this.toggleClasses.forEach(className => {
        element.classList.toggle(className)
      })
    })

    // Showing and hiding elements can cause the page to flow differently, very similarly to what happens when the
    // browser size changes. Throw this event in case we have other listeners on the resize event.
    window.dispatchEvent(new CustomEvent('right-column-changed'))
  }

  toggleClassOn() {
    if (this.on) return
    this.toggleClass()
  }

  toggleClassOff() {
    if (!this.on) return
    this.toggleClass()
  }
}
