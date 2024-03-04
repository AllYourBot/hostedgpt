import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text"]

  copy() {
    navigator.clipboard.writeText(this.text)
  }

  get text() {
    return this.textTarget.innerText
  }
}
