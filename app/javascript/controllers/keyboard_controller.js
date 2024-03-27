import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "keyboardable" ]

  click() {
    let element

    if (this.hasKeyboardableTarget)
      element = this.lastOfTheTargets
    else
      element = this.element

    element.click()
  }

  get lastOfTheTargets() {
    return this.keyboardableTargets.slice(-1)[0]
  }
}