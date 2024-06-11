import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "keyboardable" ]

  click(event) {
    let element

    if (this.hasKeyboardableTarget)
      element = this.lastOfTheTargets
    else
      element = this.element

    element.click()
    event.preventDefault()
  }

  submit(event) {
    this.element.closest('form').requestSubmit()
    event.preventDefault()
  }

  get lastOfTheTargets() {
    return this.keyboardableTargets.slice(-1)[0]
  }
}
