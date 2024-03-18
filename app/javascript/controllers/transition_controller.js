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
  }

  transitionableTargetConnected() {
    if (this.afterTimeoutValue) {
      this.transitionableTarget.setAttribute('data-timer', 'true')
      this.timeoutHandler = setTimeout(() => this.toggleClass(), this.afterTimeoutValue)
    }

    this.transitionableTarget.addEventListener("turbo:before-morph-element", this.boundTransitionableTargetReconnect, { once: true })
  }

  transitionableTargetDisconnected() {
    if (!this.afterTimeoutValue) return

    if (this.timeoutHandler) {
      clearTimeout(this.timeoutHandler)
      this.timeoutHandler = null
    }
  }

  boundTransitionableTargetReconnect = () => { this.transitionableTargetReconnect() }
  transitionableTargetReconnect() {
    if (this.transitionableTargetDisconnected) this.transitionableTargetDisconnected()
    if (this.transitionableTargetConnected) this.transitionableTargetConnected()
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
    window.dispatchEvent(new CustomEvent('main-column-changed'))
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
