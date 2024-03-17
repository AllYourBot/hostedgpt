import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    if (event.key != '?' || !event.shiftKey || ["INPUT", "TEXTAREA"].includes(event.target.tagName)) return

    this.element.showModal()
  }
}
