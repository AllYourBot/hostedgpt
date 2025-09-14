import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "urlInput", "copiedMessage" ]
  static values = { conversationId: Number }

  copyToClipboard() {
    if (this.hasUrlInputTarget) {
      this.urlInputTarget.select()
      document.execCommand('copy')

      // Show copied message
      if (this.hasCopiedMessageTarget) {
        this.copiedMessageTarget.classList.remove('hidden')

        // Hide after 3 seconds
        setTimeout(() => {
          if (this.hasCopiedMessageTarget) {
            this.copiedMessageTarget.classList.add('hidden')
          }
        }, 3000)
      }
    }
  }
}