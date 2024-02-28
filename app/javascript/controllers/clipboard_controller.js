import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text"]

  copy() {
    navigator.clipboard.writeText(this.text)

    this.element.querySelector(
      "div[data-action='click->clipboard#copy']"
    ).dataset.tip = "Copied!"
  }

  get text() {
    return this.textTarget.innerText
  }
}
