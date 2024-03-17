import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "submit" ]

  get cleanInputValue() {
    return this.inputTarget.value.trim()
  }

  connect() {
    this.inputTarget.focus()
    this.cursorToEnd()
    this.disableSubmitButton()
  }

  cursorToEnd() {
    this.inputTarget.selectionStart =
      this.inputTarget.selectionEnd =
        this.inputTarget.value.length
  }

  // Disable the submit button if the input is empty.
  disableSubmitButton() {
    if (this.cleanInputValue.length < 1) {
      this.submitTarget.disabled = true
    } else {
      this.submitTarget.disabled = false
    }
  }

  submitForm() {
    if (this.cleanInputValue.length > 0) {
      this.element.requestSubmit()
      this.inputTarget.disabled = true
      this.submitTarget.disabled = true
      window.dispatchEvent(new CustomEvent('main-column-changed'))
    }
  }

  focusKeydown(event) {
    if (event.key == "/" && ["INPUT", "TEXTAREA"].includes(event.target.tagName)) return

    this.inputTarget.focus()
    event.preventDefault()
  }

  unfocusKeydown(event) {
    document.activeElement.blur()
    event.preventDefault()
  }
}
