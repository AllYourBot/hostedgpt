import { Controller } from "@hotwired/stimulus"
import MicrophoneService from "blocks/services/microphone_service"

export default class extends Controller {
  connect() {
    window.microphoneService = new MicrophoneService()
    window.microphoneService.start()
  }

  disconnect() {
  }

  considerScroll() {
  }
}
