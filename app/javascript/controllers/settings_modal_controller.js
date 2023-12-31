import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "openButton", "closeButton", "saveButton", "apiKeyEl", "firstNameEl", "lastNameEl"];
  static values = { updateUrl: String };

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
    // Get input values
    const apiKey = this.apiKeyElTarget.value;
    const firstName = this.firstNameElTarget.value;
    const lastName = this.lastNameElTarget.value;

    // Prepare the data to send in the request body
    const userData = {
      user: {
        openai_key: apiKey,
        first_name: firstName,
        last_name: lastName
      }
    };

    // Send the update request using the fetch API
    fetch(this.updateUrlValue, {
      method: "PUT", // Use PUT method for update
      headers: {
        "Content-Type": "application/json", // Set the content type to JSON
      },
      body: JSON.stringify(userData), // Convert the data to JSON string
    })
      .then((response) => {
        if (response.ok) {
          // Update was successful, you can handle the success case here
          console.log("Update successful");
        } else {
          // Update failed, handle the error case here
          console.error("Update failed");
        }
      })
      .catch((error) => {
        // Handle any network or other errors here
        console.error("Network error:", error);
      });

    // Close the modal
    this.closeModal();
  }

  outsideClick(event) {
    if (event.target === this.modalTarget) {
      this.closeModal();
    }
  }
}
