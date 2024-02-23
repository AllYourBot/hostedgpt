import { Controller } from '@hotwired/stimulus'

// Example:
//
// <div data-controller="transition" data-transition-toggle-class="!hidden">
//   <div id="element-that-shows-and-hides" class="block" data-transition-target="me"></div>
//   <a href="#" data-action="transition#toggleClass">click to toggle</a>
// </div>
//
// Every element that is of target = me will have the class toggled.

export default class extends Controller {
  static classes = [ "toggle" ]
  static targets = [ "me" ]
  static values = {
    afterTimeout: Number
  }

  connect() {
    if (this.afterTimeoutValue) setTimeout(() => this.toggleClass(), this.afterTimeoutValue)
  }

  toggleClass() {
    this.meTargets.forEach(element => {
      element.classList.toggle(...this.toggleClasses)
    })

    // Showing and hiding elements can cause the page to flow differently, very similarly to what happens when the
    // browser size changes. Throw this event in case we have other listeners on the resize event.
    window.dispatchEvent(new Event('resize'))
  }
}
