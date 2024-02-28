import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  copy() {
    navigator.clipboard.writeText(this.message)

    this.element.querySelector(
      "div[data-action='click->clipboard#copy']"
    ).dataset.tip = "Copied!"
  }

  get message() {
    return this.messageTarget.innerText
  }
}
