import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog" ]

  open() {
    let element

    if (this.hasDialogTarget)
      element = this.dialogTarget
    else
      element = this.element

    element.showModal()
  }

  keydownQuestionOpen(event) {
    if (event.key != '?' || !event.shiftKey || ["INPUT", "TEXTAREA"].includes(event.target.tagName)) return
    this.open()
  }
}
