import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  initialize() {
    console.log('init')
    //window.microphoneService = new MicrophoneService()
  }

  connect() {
    //window.microphoneService.start()
  }

  disconnect() {
  }

  considerScroll() {
  }
}
