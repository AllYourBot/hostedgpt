import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "openButton", "closeButton", "saveButton"];
  static values = { apiKey: String, firstName: String, lastName: String };

  connect() {
    this.modalTarget.style.display = "none";
  }

  openModal() {
    this.modalTarget.style.display = "block";
  }

  closeModal() {
    this.modalTarget.style.display = "none";
  }

  saveSettings() {
    // Get input values using the values provided by Stimulus.js
    const apiKey = this.apiKeyValue;
    const firstName = this.firstNameValue;
    const lastName = this.lastNameValue;

    // Perform any necessary actions with the values here (e.g., save to a database)
    // You can send an AJAX request to save the data to the server

    // Close the modal
    this.closeModal();
  }

  outsideClick(event) {
    if (event.target === this.modalTarget) {
      this.closeModal();
    }
  }
}
