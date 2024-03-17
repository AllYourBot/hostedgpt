import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    if (event.key != '?' || !event.shiftKey) return
    this.element.showModal()
  }
}
