import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Actions
  submit() {
    this.element.requestSubmit()
  }
}
