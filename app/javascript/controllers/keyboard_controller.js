import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "keyboardable" ]

  click() {
    let element

    if (this.hasKeyboardableTarget)
      element = this.keyboardableTargets.slice(-1)[0]
    else
      element = this.element

    element.click()
  }
}