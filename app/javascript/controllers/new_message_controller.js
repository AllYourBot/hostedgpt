"use strict";

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "submit" ]

  get cleanInputValue() {
    return this.inputTarget.value.trim()
  }

  connect() {
    // Focus the input when the controller is connected
    this.focusInput()

    // Manage the enabled state of the submit button
    this.disableSubmitButton()
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
      this.element.reset()
      window.dispatchEvent(new Event('resize')) // Throw this event will cause textarea_autogrow to reprocess
    }
  }

  // Focus the input, and place the cursor at the end of the text.
  focusInput() {
    this.inputTarget.focus()
    this.inputTarget.selectionStart =
      this.inputTarget.selectionEnd =
      this.inputTarget.value.length
  }

  focusKeydown(event) {
    // Don't steal the keypress if the input field is already focused
    if (event.key == "/" && event.target.tagName != "BODY")
      return

    this.focusInput()
    event.preventDefault()
  }

  unfocusKeydown(event) {
    document.activeElement.blur()
    event.preventDefault()
  }
}
