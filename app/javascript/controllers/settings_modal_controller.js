import Rails from "@rails/ujs"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "openButton", "closeButton", "saveButton", "apiKeyEl", "firstNameEl", "lastNameEl"]
  static values = { updateUrl: String }

  connect() {
    this.modalTarget.style.display = "none"
  }

  openModal() {
    this.modalTarget.style.display = "block"
  }

  closeModal() {
    this.modalTarget.style.display = "none"
  }

  onPostSuccess() {
    console.log("save")
  }

  saveSettings() {
    Rails.fire(this.element.querySelector("form"), "submit")

    // Close the modal
    this.closeModal()
  }

  outsideClick(event) {
    if (event.target === this.modalTarget) {
      this.closeModal()
    }
  }
}
