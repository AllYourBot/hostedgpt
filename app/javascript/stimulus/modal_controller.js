import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog" ]

  connect() {
    window.addEventListener('blur', this.boundEndDelayedModal)
    document.addEventListener('mousedown', this.boundEndDelayedModal)
  }

  disconnect() {
    window.removeEventListener('blur', this.boundEndDelayedModal)
    document.removeEventListener('mousedown', this.boundEndDelayedModal)
  }

  open() {
    let element

    if (this.hasDialogTarget)
      element = this.dialogTarget
    else
      element = this.element

    element.showModal()
  }

  close() {
    let element

    if (this.hasDialogTarget)
      element = this.dialogTarget
    else
      element = this.element

    element.close()
  }

  keydownQuestionOpen(event) {
    this.endDelayedModal()
    this.startDelayedModal(event)

    if (event.key != '?' || !event.shiftKey || ["INPUT", "TEXTAREA"].includes(event.target.tagName)) return
    this.open()
  }

  keyupQuestionClose(event) {
    this.endDelayedModal()
  }

  startDelayedModal(event) {
    if (event.key == 'Meta' || event.key == 'Control') {
      this.holdingHandler = runAfter(1, () => this.open())
      this.questionDialog = this
    }
  }

  boundEndDelayedModal = () => { this.endDelayedModal() }
  endDelayedModal() {
    if (this.holdingHandler) {
      this.holdingHandler.end()
      this.close()
    }
  }
}
