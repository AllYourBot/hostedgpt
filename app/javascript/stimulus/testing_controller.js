import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  update_link(event) {
    const link = event.currentTarget;
    link.href = link.href + "?query=" + this.inputTarget.value
  }
}
