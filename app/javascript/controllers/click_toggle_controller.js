import { Controller } from '@hotwired/stimulus'

// Example:
//
// <div data-controller="click-toggle" data-click-toggle-flippable-class="!hidden">
//   <div id="element-that-shows-and-hides" class="block" data-click-toggle-target="destination"></div>
//   <a href="#" data-action="click-toggle#toggleClass">click to toggle</a>
// </div>
//
// Every element that is of target = destination will have the flippable class toggled.

export default class extends Controller {
  static classes = [ "flippable" ]
  static targets = [ "destination" ]

  toggleClass() {
    this.destinationTargets.forEach(element => {
      element.classList.toggle(this.flippableClass)
    })

    // Showing and hiding elements can cause the page to flow differently, very similarly to what happens when the
    // browser size changes. Throw this event in case we have other listeners on the resize event.
    window.dispatchEvent(new Event('resize'))
  }
}
