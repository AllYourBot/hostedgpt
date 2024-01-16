"use strict";

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    this.inputTarget.focus()
    this.inputTarget.addEventListener("keyup", this.disableSubmitButton.bind(this))
    this.disableSubmitButton()
  }

  disconnect() {
    this.inputTarget.removeEventListener("keyup", this.disableSubmitButton.bind(this))
  }

  disableSubmitButton() {
    console.log(this.inputTarget.value.length)
    if (this.inputTarget.value.length < 1) {
      this.submitTarget.disabled = true
    } else {
      this.submitTarget.disabled = false
    }
  }
}
