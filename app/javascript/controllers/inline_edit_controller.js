import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input" ]

  connect() {
    this.originalText = this.inputTarget.value
    this.focusInput()
  }

  submitForm() {
    if (this.inputTarget.disabled) return

    this.element.requestSubmit()
    this.inputTarget.disabled = true
  }

  // Focus the input, and place the cursor at the end of the text.
  focusInput() {
    this.inputTarget.focus()
    this.inputTarget.selectionStart =
      this.inputTarget.selectionEnd =
        this.inputTarget.value.length
  }

  abort() {
    console.log('abort')
    this.inputTarget.value = this.originalText
    this.submitForm()
  }
}