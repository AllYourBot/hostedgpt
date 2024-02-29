import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    path: String
  }

  navigate() {
    const new_conversation_path = this.pathValue
    window.location.href = new_conversation_path
  }
}
