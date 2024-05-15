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
  static outlets = [ "message-scroller" ]

  connect() {
    this.retryCount = 0
    this.maxRetries = 12
    this.retryAfterMs = 500
    this.imageKey = Math.round(Math.random()*100000000000)

    window.imageLoadingForSystemTestsToCheck ||= {}

    if (this.imageTarget.src == "")
      window.imageLoadingForSystemTestsToCheck[this.imageKey] = 'loading'
    else
      window.imageLoadingForSystemTestsToCheck[this.imageKey] = 'done'

    this.imageTarget.src = this.urlValue
  }

  retryAfterDelay() {
    this.retryCount++
    if (this.retryCount <= this.maxRetries) {
      this.imageTarget.classList.add("hidden")
      this.loaderTarget.classList.remove("hidden")
      this.considerScrolling(false) // why are we scrolling here? Tests fail if we remove this

      setTimeout(() => {
        let srcBase = this.urlValue.split("?")[0]
        this.imageTarget.src = `${srcBase}?disposition=-${this.retryCount}`
      }, this.retryAfterMs)
    }
  }

  show() {
    this.imageTarget.removeAttribute("width")
    this.imageTarget.removeAttribute("height")
    this.imageTarget.classList.remove("hidden")
    this.loaderTarget.classList.add("hidden")
    window.imageLoadingForSystemTestsToCheck[this.imageKey] = 'recalculating'
    this.ensureImageLoaded()
  }

  ensureImageLoaded() {
    if (this.imageTarget.parentElement.clientHeight > 25)
      this.considerScrolling(true)
    else
      runAfter(0.5, () => this.ensureImageLoaded())
  }

  messageScrollerOutletConnected() {
    if (this.redoConsiderScrolling != undefined) this.considerScrolling(this.redoConsiderScrolling)
  }

  considerScrolling(includeDetails) {
    const event = includeDetails ? new CustomEvent('dummy', { detail: this.imageKey }) : new CustomEvent('dummy')

    if (this.hasMessageScrollerOutlet && this.messageScrollerOutlets.length > 0)
      this.messageScrollerOutlets.forEach((outlet) => outlet.throttledScrollDownIfScrolledToBottom(event))
    else
      this.redoConsiderScrolling = includeDetails
  }
}
