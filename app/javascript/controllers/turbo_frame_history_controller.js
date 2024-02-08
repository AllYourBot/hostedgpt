import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    document.addEventListener('turbo:before-fetch-request', this.beforeFetchRequest)
    window.addEventListener("popstate", this.popState)
  }

  disconnect() {
    document.removeEventListener('turbo:before-fetch-request', this.beforeFetchRequest)
    window.removeEventListener("popstate", this.popState)
  }

  beforeFetchRequest(event) {
    // Solution from: https://github.com/hotwired/turbo/issues/792
    // When we do a fetch request that targets a turbo-frame, we manually update the URL by
    // adding to pushState. When we do, we set a special param (refresh_on_back = true). We
    // then monitor popState event, which fires every time the back button is pressed. In those
    // cases we do a new Turbo visit to manually refresh the page.
    //
    // This "fixes" history state for turbo frames, but it doesn't use the Turbo page cache.
    // This simply means that going back will cuase a new server request, but that's okay for our
    // purposes.
    let getFetchTargetingFrame =  (event.detail.fetchOptions.headers['Turbo-Frame'] != undefined) &&
                                  (event.detail.fetchOptions.method == "get")

    if (getFetchTargetingFrame) {
      Turbo.cache.exemptPageFromPreview()
      history.replaceState({page: document.title, refresh_on_back: true}, '', window.location.pathname);
      history.pushState({page: 'new title', refresh_on_back: true}, '', event.detail.url.pathname) // not sure how to get page title
    }
  }

  popState(event) {
    if (event.state && event.state.refresh_on_back) {
      Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
