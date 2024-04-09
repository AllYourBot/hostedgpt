import { Controller } from "@hotwired/stimulus"

// If an image URL might return a 404 when the page loads, this controller will show an alternate and retry it a few times.
// It's important that you set the img src to an empty string and let the stimulus controller swap out the url, otherwise
// the browser might request it and fail before the stimulus controller has had a chance to initialize.
//
// Example:
//
// <div data-controller="image-loader" data-image-loader-url-class="http://image.com/picture.jpg">
//   <img src=""
//     data-image-loader-target="image"
//     data-action="
//       error->image-loader#retryAfterDelay
//       load->image-loader#show
//     "
//   />
//   <div id="spinner" class="hidden" data-image-loader-target="loader"></div>
// </div>

export default class extends Controller {
  static targets = [ "image", "loader" ]
  static values = { url: String }

  connect() {
    this.retryCount = 0
    this.maxRetries = 6
    this.retryAfterMs = 500

    this.imageTarget.src = this.urlValue
  }

  show() {
    this.imageTarget.classList.remove("hidden")
    this.loaderTarget.classList.add("hidden")
    window.dispatchEvent(new CustomEvent('main-column-changed'))
  }

  retryAfterDelay() {
    this.retryCount++
    if (this.retryCount <= this.maxRetries) {
      this.imageTarget.classList.add("hidden")
      this.loaderTarget.classList.remove("hidden")

      setTimeout(() => {
        let srcBase = this.imageTarget.src.split("?")[0]
        let separator = this.imageTarget.src.includes("?") ? "&" : "?"
        this.imageTarget.src = `${srcBase}${separator}disposition=-${this.retryCount}`
      }, this.retryAfterMs)
    }
  }
}
