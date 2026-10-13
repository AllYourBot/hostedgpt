import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["model", "test", "url","token"]

  update_link_language_model(event) {
    const link = event.currentTarget;
    const href = link.href.split('?')[0];
    link.href = href + "?model=" + this.modelTarget.value
  }

  // POST so the token travels in the request body, never in a URL that
  // browser history, proxies, or access logs would keep.
  async test_api_service(event) {
    event.preventDefault()
    if (this.testDisabled) return

    const response = await fetch(event.currentTarget.href, {
      method: "POST",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ url: this.urlTarget.value, token: this.tokenTarget.value })
    })

    Turbo.renderStreamMessage(await response.text())
  }

  disable_test_link() {
    this.testDisabled = true
  }
}
