import { Controller } from "@hotwired/stimulus"

// This replicates the behavior of turbo_confirm
//
// The controller exists because there are some button_to tags that we need to disable turbo for. Example:
//
// <%= button_to "Gmail", "/auth/gmail", method: :post, data: { turbo: false, controller: "confirm", confirm_text_value: "Hello?" }

export default class extends Controller {
  static values = { text: String }

  connect() {
    this.element.addEventListener("click", this.boundConfirm)
  }

  disconnect() {
    this.element.removeEventListener("click", this.boundConfirm)
  }

  boundConfirm = (e) => { this.confirm(e) }
  confirm(e) {
    if (!confirm(this.textValue)) e.preventDefault()
  }
}
