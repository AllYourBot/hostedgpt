import { Controller } from "@hotwired/stimulus"
static targets = ["input"]

// Connects to data-controller="language-model"
export default class extends Controller {
  update_link(event) {
    const link = document.getElementById("test_language_model")
    link.href = link.href + "?query=" + event.target.value
  }
}
